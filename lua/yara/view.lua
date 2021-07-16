local api = vim.api

local utils = require("yara.utils")
local class = require("yara.class")

ViewState = class(function(self)
	self.win = nil
	self.buf = nil
end)

local function add_format_lines(issue, is_subtask)
	local prefix = utils.cond(is_subtask, "-     ", "* ")
	local lines = {}
	table.insert(
		lines,
		string.format(
			"%s %s [%s] <%s> %s",
			prefix,
			issue.key,
			utils.cond(issue:is_modified(), "+", " "),
			issue.status,
			issue.assignee or "UNASSIGNED",
			"4h30m/8h"
		)
	)
	table.insert(lines, "      " .. (issue.summary or "<No summary>"))
	return lines
end

function ViewState:show(issues_list)
	local opts = {
		relative = "editor",
		width = vim.o.columns / 2,
		height = vim.o.lines - 10,
		anchor = "NW",
		style = "minimal",
		border = "rounded", -- rounded, solid, shadow, single, double
		row = 5,
		col = vim.o.columns / 4,
	}

	opts.width = 100
	opts.height = 300
	-- opts.width = math.min(longest + 2, vim.o.columns - 2)
	-- opts.height = math.min(#lines + 1, vim.o.lines - 2)
	opts.row = (vim.o.lines - opts.height) / 2
	opts.col = (vim.o.columns - opts.width) / 2

	if self.buf == nil then
		self.buf = api.nvim_create_buf(false, true)
	end
	api.nvim_buf_set_option(self.buf, "modifiable", true)
	api.nvim_buf_set_name(self.buf, "yara2")
	api.nvim_buf_set_option(self.buf, "filetype", "yara")
	api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")

	if self.win == nil then
		self.win = api.nvim_open_win(self.buf, true, opts)
	end

	-- api.nvim_buf_set_lines(self.buf, 0, -1, true, lines)
	self.ns_id = api.nvim_create_namespace("yara")
	self.active_issues_list = issues_list

	api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
	local i = 0
	for issue, children in pairs(issues_list:grouped_filtered_issues()) do
		-- TODO: parent lines are not displayed...
		-- local lines = add_format_lines(parent_issue, false)
		for k, line in ipairs(add_format_lines(issue, false)) do
			api.nvim_buf_set_lines(self.buf, i, i, true, { line })
			if k == 1 then
				api.nvim_buf_set_extmark(self.buf, self.ns_id, i, 0, { id = issue.id })
			end
			i = i + 1
		end

		for _, c in ipairs(children) do
			for k, line in ipairs(add_format_lines(c, true)) do
				api.nvim_buf_set_lines(self.buf, i, i, true, { line })
				if k == 1 then
					api.nvim_buf_set_extmark(self.buf, self.ns_id, i, 0, { id = c.id })
				end
				i = i + 1
			end
		end
	end

	api.nvim_win_set_option(self.win, "winhl", "Normal:Normal")
	api.nvim_win_set_option(self.win, "wrap", false)
	api.nvim_win_set_option(self.win, "conceallevel", 3)
	api.nvim_win_set_option(self.win, "concealcursor", "nvic")
	api.nvim_buf_set_option(self.buf, "modifiable", false)
	api.nvim_buf_set_var(self.buf, "indent_blankline_enabled", false)
end

function ViewState:redraw_issue(issue)
	local pos = api.nvim_buf_get_extmark_by_id(self.buf, self.ns_id, issue.id, {})
	if #pos == 0 then
		utils.echo_warning(string.format("no issue with id %d found", issue.id))
		return
	end
	local row = pos[1] -- { row, col } -> row
	api.nvim_buf_set_option(self.buf, "modifiable", true)
	for k, line in ipairs(add_format_lines(issue, issue.parent ~= nil)) do
		api.nvim_buf_set_lines(self.buf, row + k - 1, row + k, true, { line })
	end
	api.nvim_buf_set_extmark(self.buf, self.ns_id, row, 0, { id = issue.id })
	api.nvim_buf_set_option(self.buf, "modifiable", false)
end

function ViewState:dispose()
	print("disposed! ", self.buf, self.win)
	self.buf = nil
	self.win = nil
	self.ns_id = nil
end

--- Returns the issue id (a number) of the current issue.
function ViewState:get_current_issue()
	local row = api.nvim_win_get_cursor(0)[1]
	local marks = api.nvim_buf_get_extmarks(self.buf, self.ns_id, { row - 2, 0 }, { row - 1, 0 }, {})
	assert(#marks == 1, "Expected only a single extended mark to be found")
	local issue_id = marks[1][1] -- { { issue_id, row, col } } --> issue_id
	local issue = _G.yara.board.issues.issues[issue_id]
	return issue
end

return { ViewState = ViewState }
