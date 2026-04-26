local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 14.0

-- Color scheme
config.color_scheme = 'Catppuccin Mocha'

-- Window
config.window_decorations = 'RESIZE|INTEGRATED_BUTTONS'
config.window_close_confirmation = 'NeverPrompt'
config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }

-- Cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 0

-- Mouse
config.hide_mouse_cursor_when_typing = true
config.pane_focus_follows_mouse = true

-- Left option key as Alt (right already defaults to macOS compose)
config.send_composed_key_when_left_alt_is_pressed = false

local SSH_AUTH_SOCK = os.getenv 'SSH_AUTH_SOCK'
if
  SSH_AUTH_SOCK
  == string.format('%s/keyring/ssh', os.getenv 'XDG_RUNTIME_DIR')
then
  local onep_auth =
    string.format('%s/.1password/agent.sock', wezterm.home_dir)
  -- Glob is being used here as an indirect way to check to see if
  -- the socket exists or not. If it didn't, the length of the result
  -- would be 0
  if #wezterm.glob(onep_auth) == 1 then
    config.default_ssh_auth_sock = onep_auth
  end
end


-- Ensure common tool paths are available in spawned processes
config.set_environment_variables = {
  PATH = '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:' .. (os.getenv('PATH') or ''),
}


-- ---------------------------------------------------------------------------
-- Keys
-- ---------------------------------------------------------------------------
config.leader = { key = 'b', mods = 'SUPER', timeout_milliseconds = 1000 }

-- smart-splits.nvim: Cmd+hjkl to move, Cmd+Shift+hjkl to resize
-- IS_NVIM is set by smart-splits.nvim on load; if in Neovim, pass keys through,
-- otherwise move/resize WezTerm panes directly.
local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == 'true'
end

local direction_keys = { h = 'Left', j = 'Down', k = 'Up', l = 'Right' }

local function split_nav(resize_or_move, key)
  local mods = resize_or_move == 'resize' and 'SUPER|SHIFT' or 'SUPER'
  return {
    key = key,
    mods = mods,
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to Neovim (M-h/j/k/l or M-H/J/K/L)
        local nvim_key = resize_or_move == 'resize' and key:upper() or key
        win:perform_action({ SendKey = { key = nvim_key, mods = 'META' } }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

config.keys = {
  { key = 'p', mods = 'SUPER', action = act.ActivateCommandPalette },
  { key = '+', mods = 'SUPER', action = act.IncreaseFontSize },
  { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
  { key = '0', mods = 'SUPER', action = act.ResetFontSize },
  { key = 's', mods = 'SUPER', action = act.SendString('\x1bs') },

  { key = 'd', mods = 'SUPER',       action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'SUPER|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },

  -- Pane navigation (smart-splits aware)
  split_nav('move',   'h'),
  split_nav('move',   'j'),
  split_nav('move',   'k'),
  split_nav('move',   'l'),
  split_nav('resize', 'h'),
  split_nav('resize', 'j'),
  split_nav('resize', 'k'),
  split_nav('resize', 'l'),

  { key = 't', mods = 'SUPER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'SUPER', action = act.CloseCurrentPane { confirm = false } },

  { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
  { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
  { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
  { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
  { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
  { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
  { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
  { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
  { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },
}

-- Call last, after all keybindings are defined
local cmdpicker = wezterm.plugin.require 'https://github.com/abidibo/wezterm-cmdpicker'
cmdpicker.apply_to_config(config, {
  title = 'Command Palette',
})

return config
