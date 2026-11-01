-- DarkGold for WezTerm, part of cosmic-darkgold-theme (MIT).
-- Colours follow the COSMIC Terminal scheme (cosmic-term/).
--
-- Install: ./wezterm/install.sh puts this in ~/.config/wezterm/, then in
-- ~/.config/wezterm/wezterm.lua:
--   config.colors = require("darkgold")
-- To follow COSMIC's Dark / Light toggle with the White Gold half installed too:
--   local dark = (wezterm.gui and wezterm.gui.get_appearance() or "Dark"):find("Dark")
--   config.colors = require(dark and "darkgold" or "whitegold")

return {
  foreground = "#EFEBDC",
  background = "#1B1B1B",

  cursor_bg = "#EFEBDC",
  cursor_fg = "#1B1B1B",
  cursor_border = "#EFEBDC",
  compose_cursor = "#C0AF7F",

  selection_bg = "#4E4E49",
  selection_fg = "none",

  scrollbar_thumb = "#817F68",
  split = "#817F68",

  -- black, red, green, yellow, blue, magenta, cyan, white
  ansi = { "#1B1B1B", "#F44336", "#C0AF7F", "#A99B7A", "#E58980", "#77838A", "#6D6D6D", "#E1CE98" },
  brights = { "#817F68", "#F44336", "#C0AF7F", "#A99B7A", "#E58980", "#77838A", "#6D6D6D", "#EFEBDC" },

  copy_mode_active_highlight_bg = { Color = "#C0AF7F" },
  copy_mode_active_highlight_fg = { Color = "#1B1B1B" },
  copy_mode_inactive_highlight_bg = { Color = "#A99B7A" },
  copy_mode_inactive_highlight_fg = { Color = "#1B1B1B" },

  quick_select_label_bg = { Color = "#C0AF7F" },
  quick_select_label_fg = { Color = "#1B1B1B" },
  quick_select_match_bg = { Color = "#A99B7A" },
  quick_select_match_fg = { Color = "#1B1B1B" },

  tab_bar = {
    background = "#1B1B1B",
    active_tab = { bg_color = "#C0AF7F", fg_color = "#1B1B1B", intensity = "Bold" },
    inactive_tab = { bg_color = "#2A2A29", fg_color = "#A8A59B" },
    inactive_tab_hover = { bg_color = "#3C3C39", fg_color = "#EFEBDC" },
    new_tab = { bg_color = "#1B1B1B", fg_color = "#A8A59B" },
    new_tab_hover = { bg_color = "#3C3C39", fg_color = "#C0AF7F" },
  },
}
