local M = {}

local function window_in_focused_space(app)
	if not app then
		return nil
	end

	local focusedSpace = hs.spaces.focusedSpace()

	for _, win in ipairs(app:allWindows() or {}) do
		if win:isStandard() then
			local spaces = hs.spaces.windowSpaces(win)
			if spaces and hs.fnutils.contains(spaces, focusedSpace) then
				return win
			end
		end
	end

	return nil
end

local function focus_window(win)
	if not win then
		return false
	end

	if win:isMinimized() then
		win:unminimize()
	end

	win:focus()
	return true
end

local function first_standard_window(app)
	if not app then
		return nil
	end

	for _, win in ipairs(app:allWindows() or {}) do
		if win:isStandard() then
			return win
		end
	end

	return nil
end

local function focus_window_in_focused_space_by_name(app_name)
	local app = hs.application.get(app_name)
	local win = window_in_focused_space(app)
	return focus_window(win)
end

local function wait_for_window_in_focused_space_by_name(app_name, timeout_seconds)
	local deadline = hs.timer.secondsSinceEpoch() + timeout_seconds
	while hs.timer.secondsSinceEpoch() < deadline do
		if focus_window_in_focused_space_by_name(app_name) then
			return true
		end
		hs.timer.usleep(50000)
	end

	return focus_window_in_focused_space_by_name(app_name)
end

function M.focus_or_launch(app_name)
	local app = hs.application.get(app_name)
	if focus_window(window_in_focused_space(app)) then
		return
	end

	hs.application.launchOrFocus(app_name)
end

local function spawn_emacs_frame_with_emacsclient(app_name)
	local paths = {
		"/opt/homebrew/bin/emacsclient",
		"/usr/local/bin/emacsclient",
		"/usr/bin/emacsclient",
	}

	for _, path in ipairs(paths) do
		if hs.fs.attributes(path) then
			local task = hs.task.new(path, nil, { "-a", "", "-n", "-c" })
			if task and task:start() then
				if wait_for_window_in_focused_space_by_name(app_name, 2.0) then
					focus_window_in_focused_space_by_name(app_name)
					return true
				end
			end
		end
	end

	return false
end

function M.focus_or_launch_with_cmd_n(app_name)
	local app = hs.application.get(app_name)
	if focus_window(window_in_focused_space(app)) then
		return
	end

	if app then
		hs.eventtap.keyStroke({ "cmd" }, "n", 0, app)
		return
	end

	hs.application.launchOrFocus(app_name)
end

function M.focus_or_launch_emacs()
	local app_name = "Emacs"
	local app = hs.application.get(app_name)
	if focus_window(window_in_focused_space(app)) then
		return
	end

	if app and spawn_emacs_frame_with_emacsclient(app_name) then
		return
	end

	hs.application.launchOrFocus(app_name)
end

function M.finder_focus_or_new()
	local app = hs.application.get("Finder")

	if focus_window(window_in_focused_space(app)) then
		return
	end

	if focus_window(first_standard_window(app)) then
		return
	end

	hs.osascript.applescript([[
    tell application "Finder"
      activate
      make new Finder window to (path to home folder)
    end tell
  ]])
end

function M.safari_focus_or_new_window()
	local app = hs.application.get("Safari")

	if focus_window(window_in_focused_space(app)) then
		return
	end

	hs.osascript.applescript([[
    tell application "Safari"
      activate
      make new document
    end tell
  ]])
end

return M
