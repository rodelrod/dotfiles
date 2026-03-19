local M = {}

function M.setup(app_focus)
	-- Ctrl-shift + Number bindings for left-handed access
	hs.hotkey.bind({ "ctrl", "shift" }, "1", app_focus.focus_or_launch_emacs)
	hs.hotkey.bind({ "ctrl", "shift" }, "2", function() app_focus.focus_or_launch_with_cmd_n("Ghostty") end)
	hs.hotkey.bind({ "ctrl", "shift" }, "3", app_focus.safari_focus_or_new_window)
	hs.hotkey.bind({ "ctrl", "shift" }, "4", app_focus.finder_focus_or_new)
	hs.hotkey.bind({ "ctrl", "shift" }, "5", function() app_focus.focus_or_launch("ChatGPT") end)
	hs.hotkey.bind({ "ctrl", "shift" }, "6", function() app_focus.focus_or_launch("Gemini") end)
	hs.hotkey.bind({ "ctrl", "shift" }, "7", function() app_focus.focus_or_launch_with_cmd_n("Google Chrome") end)

	-- Hyper bindings (hyper is mapped by karabiner to the physical right opt)
	local hyper = { "cmd", "alt", "ctrl", "shift" }

	hs.hotkey.bind(hyper, "E", app_focus.focus_or_launch_emacs)
	hs.hotkey.bind(hyper, "T", function() app_focus.focus_or_launch_with_cmd_n("Ghostty") end)
	hs.hotkey.bind(hyper, "S", app_focus.safari_focus_or_new_window)
	hs.hotkey.bind(hyper, "F", app_focus.finder_focus_or_new)
	hs.hotkey.bind(hyper, "G", function() app_focus.focus_or_launch_with_cmd_n("Google Chrome") end)
	hs.hotkey.bind(hyper, "C", function() app_focus.focus_or_launch("Codex") end)
end

return M
