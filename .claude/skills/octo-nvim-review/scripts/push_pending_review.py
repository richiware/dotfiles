#!/usr/bin/env python3
"""Push /octo:review findings into the viewer's PENDING GitHub review.

octo.nvim stores an in-progress review as a PENDING review on GitHub, so every
thread added here shows up after `:Octo review resume` (or `:Octo review`) and
stays private until the review is submitted from neovim.

Usage:
  push_pending_review.py [--findings FILE] [--pr N] [--repo OWNER/NAME]
                         [--min-confidence 0.0] [--dry-run]

FILE defaults to the newest ~/.claude-octopus/results/**/review-findings-*.json.
Each finding may carry an optional "suggestion" object added by Claude:
  {"start_line": 40, "line": 42, "code": "replacement lines"}
which is rendered as a GitHub ```suggestion block over lines start_line..line.
"""
import argparse
import glob
import hashlib
import json
import os
import re
import subprocess
import sys

ICONS = {"normal": "⚠️", "nit": "💅", "pre-existing": "🕰️"}
INFO_ICON = "💡"
MARKER = "<!-- octo-nvim-review:{} -->"


def run(args, stdin=None):
    res = subprocess.run(args, input=stdin, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"{' '.join(args[:3])}... failed: {res.stderr.strip()}")
    return res.stdout


def graphql(query, **variables):
    payload = json.dumps({"query": query, "variables": variables})
    out = json.loads(run(["gh", "api", "graphql", "--input", "-"], stdin=payload))
    if out.get("errors"):
        raise RuntimeError("; ".join(e.get("message", str(e)) for e in out["errors"]))
    return out["data"]


def load_findings(path):
    raw = open(path, encoding="utf-8").read().lstrip()
    # Provider output may carry trailing prose after the JSON document and
    # invalid escapes such as "\_" (repaired the same way octopus' review.sh does).
    decoder = json.JSONDecoder()
    try:
        doc = decoder.raw_decode(raw)[0]
    except json.JSONDecodeError:
        doc = decoder.raw_decode(re.sub(r'\\(?!["\\/bfnrt]|u[0-9A-Fa-f]{4})', r"\\\\", raw))[0]
    return doc.get("findings", [])


def commentable_lines(pr, repo):
    """Map path -> set of RIGHT-side line numbers that GitHub accepts comments on."""
    diff = run(["gh", "pr", "diff", str(pr), "--repo", repo])
    lines, path, cur = {}, None, None
    for row in diff.splitlines():
        if row.startswith("diff --git "):
            path, cur = None, None
        elif row.startswith("+++ "):
            path = None if row[4:] == "/dev/null" else row[6:]
            if path:
                lines.setdefault(path, set())
        elif row.startswith("@@"):
            m = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)", row)
            cur = int(m.group(1)) if m else None
        elif path and cur is not None and not row.startswith("\\"):
            if row.startswith("-"):
                continue
            lines[path].add(cur)
            cur += 1
    return lines


def render_body(f, file_level):
    sev = f.get("severity", "info")
    parts = [f"{ICONS.get(sev, INFO_ICON)} **{f.get('title', '').strip()}**"]
    if file_level and f.get("line"):
        parts.append(f"_(line {f['line']})_")
    parts.append(f.get("detail", "").strip())
    sug = f.get("suggestion")
    if sug and sug.get("code") is not None and not file_level:
        parts.append("```suggestion\n" + sug["code"].rstrip("\n") + "\n```")
    parts.append(MARKER.format(finding_key(f)))
    return "\n\n".join(p for p in parts if p)


def finding_key(f):
    key = json.dumps([f.get("file"), f.get("line"), f.get("category"), f.get("title")])
    return hashlib.sha1(key.encode()).hexdigest()[:12]


Q_PR = """
query($owner:String!,$name:String!,$number:Int!){
  repository(owner:$owner,name:$name){ pullRequest(number:$number){
    id headRefOid
    reviews(first:20,states:PENDING){ nodes{ id body viewerDidAuthor
      comments(first:100){ nodes{ body } } } } } } }"""
M_REVIEW = """
mutation($pr:ID!,$oid:GitObjectID!){
  addPullRequestReview(input:{pullRequestId:$pr,commitOID:$oid}){ pullRequestReview{ id } } }"""
M_THREAD = """
mutation($input:AddPullRequestReviewThreadInput!){
  addPullRequestReviewThread(input:$input){ thread{ id } } }"""
M_BODY = """
mutation($id:ID!,$body:String!){
  updatePullRequestReview(input:{pullRequestReviewId:$id,body:$body}){ pullRequestReview{ id } } }"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--findings")
    ap.add_argument("--pr", type=int)
    ap.add_argument("--repo")
    ap.add_argument("--min-confidence", type=float, default=0.0)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    path = a.findings
    if not path:
        cands = glob.glob(os.path.expanduser("~/.claude-octopus/results/**/review-findings-*.json"),
                          recursive=True)
        if not cands:
            sys.exit("no review-findings-*.json found; run /octo:review first")
        path = max(cands, key=os.path.getmtime)
    findings = [f for f in load_findings(path)
                if f.get("verdict") not in ("false-positive", "excluded-by-debate")
                and float(f.get("confidence", 1)) >= a.min_confidence]
    print(f"findings: {path} ({len(findings)} to push)")
    if not findings:
        return

    repo = a.repo or run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"]).strip()
    pr = a.pr or int(run(["gh", "pr", "view", "--json", "number", "-q", ".number"]).strip())
    owner, name = repo.split("/", 1)
    lines = commentable_lines(pr, repo)

    data = graphql(Q_PR, owner=owner, name=name, number=pr)["repository"]["pullRequest"]
    mine = [r for r in data["reviews"]["nodes"] if r["viewerDidAuthor"]]
    existing = "\n".join(c["body"] for r in mine for c in r["comments"]["nodes"])
    review_id = mine[0]["id"] if mine else None
    review_body = mine[0]["body"] if mine else ""
    print(f"PR {repo}#{pr}: " + ("reusing your pending review" if review_id else "will start a pending review"))

    pushed, skipped, orphans = 0, 0, []
    for f in findings:
        fpath, line = f.get("file"), f.get("line")
        if MARKER.format(finding_key(f)) in existing:
            skipped += 1
            continue
        if fpath not in lines:
            orphans.append(f)
            continue
        sug = f.get("suggestion") or {}
        start = sug.get("start_line")
        end = sug.get("line", line)
        inline = isinstance(end, int) and end in lines[fpath] and (
            start is None or all(n in lines[fpath] for n in range(start, end + 1)))
        inp = {"path": fpath, "body": render_body(f, not inline)}
        if inline:
            inp.update(line=end, side="RIGHT")
            if start is not None and start < end:
                inp.update(startLine=start, startSide="RIGHT")
        else:
            inp["subjectType"] = "FILE"
        where = f"{fpath}:{end}" if inline else f"{fpath} (file-level, line {line})"
        if a.dry_run:
            print(f"  [dry-run] {where}  {f.get('title')}")
            pushed += 1
            continue
        if not review_id:
            review_id = graphql(M_REVIEW, pr=data["id"], oid=data["headRefOid"])[
                "addPullRequestReview"]["pullRequestReview"]["id"]
        inp["pullRequestReviewId"] = review_id
        try:
            graphql(M_THREAD, input=inp)
            print(f"  + {where}  {f.get('title')}")
            pushed += 1
        except RuntimeError as e:
            print(f"  ! {where}: {e}; moving to review summary")
            orphans.append(f)

    if orphans:
        note = "\n".join(f"- `{f.get('file')}:{f.get('line')}` {ICONS.get(f.get('severity'), INFO_ICON)} "
                         f"**{f.get('title')}**: {f.get('detail', '').strip()} "
                         f"{MARKER.format(finding_key(f))}"
                         for f in orphans if MARKER.format(finding_key(f)) not in review_body)
        if note:
            body = (review_body + "\n\n" if review_body else "") + \
                "### /octo:review findings outside the diff\n\n" + note
            if a.dry_run:
                print(f"  [dry-run] {len(orphans)} finding(s) outside the diff -> review summary")
            else:
                if not review_id:
                    review_id = graphql(M_REVIEW, pr=data["id"], oid=data["headRefOid"])[
                        "addPullRequestReview"]["pullRequestReview"]["id"]
                graphql(M_BODY, id=review_id, body=body)
                print(f"  + {len(orphans)} finding(s) outside the diff added to the review summary")

    print(f"done: {pushed} thread(s) added, {skipped} already present"
          + (" (dry run, nothing written)" if a.dry_run else ""))
    if not a.dry_run:
        print("In neovim: `:Octo review resume` (or close and resume an open review to reload).")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as e:
        sys.exit(f"error: {e}")
