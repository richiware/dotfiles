-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- Font
config.font_size = 8.5
config.font = wezterm.font("DejaVu Sans Mono")
config.cell_width = 0.8
config.freetype_load_flags = "NO_HINTING"

-- Theme
config.color_scheme = "Canonical Solarized Dark"
local canonical_solarized = require("canonical_solarized")
canonical_solarized.apply_to_config(config)

config.enable_tab_bar = false
config.enable_kitty_keyboard = true

-- Finally, return the configuration to wezterm:
return config
