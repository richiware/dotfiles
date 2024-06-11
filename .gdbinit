# Pretty print
set print pretty on

# Bug report command
define bugreport
    set pagination off
    set logging file /tmp/bugreport.txt
    set logging enabled on
    thread apply all backtrace full
    shell uname -a
    set logging enabled off
end
