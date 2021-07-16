local mod = {}
local List = require("plenary.collections.py_list")
local class = require("yara.class")
local utils = require("yara.utils")

local TransitionState = List({ "To Do", "In Progress", "Review", "Done" })
local JIRA_QUERYFIELDS = "customfield_10020,summary,description,assignee,labels,priority,issuetype,status,parent"
local JIRA_DEFAULT_ARGS = { " ", "--template", "json", "-f", JIRA_QUERYFIELDS }
-- jira list  --template json -f customfield_10020,summary,description,assignee,labels,priority,issuetype,status,parent

IssueCollection = class(function(self, issues)
	self.issues = issues
	self.filters = { by_assignee = nil, by_status = nil }
end)

function IssueCollection.load_from_jira_cli(jira_executable)
	local json_response = vim.fn.json_decode(
		vim.fn.system(jira_executable .. " list " .. table.concat(JIRA_DEFAULT_ARGS, " "))
	)
	local issues = vim.tbl_map(Issue.from_json_entry, json_response.issues)
	local keyed_issues = {}
	for _, v in ipairs(issues) do
		keyed_issues[v.id] = v
	end
	return IssueCollection(keyed_issues)
end

--- Adds a filter that keeps only the issues created by `assignee`
-- @param assignee str the assignee to filter on
function IssueCollection:filter_by_assignee(assignee)
	local function func(issues)
		local out = {}
		for k, v in pairs(issues) do
			if v.assignee == assignee then
				out[k] = v
			end
		end
		return out
	end
	self.filters.by_assignee = func
end

--- Adds a filter that keeps only the issues in state `transition_state`
-- @param transition_state, str `To Do|In Progress|Review|Done`
function IssueCollection:filter_by_status(transition_state)
	local function func(issues)
		local out = {}
		for k, v in pairs(issues) do
			if v.status == transition_state then
				out[k] = v
			end
		end
		return out
	end
	self.filters.by_status = func
end

function IssueCollection:clear_filter_by_status()
	self.filters.by_status = nil
end

function IssueCollection:clear_filter_by_assignee()
	self.filters.by_assignee = nil
end

-- @return Issue[] the issues that matches the current filters
function IssueCollection:filtered_issues()
	local result = self.issues
	for _, f in pairs(self.filters) do
		if f ~= nil then
			result = f(result)
		end
	end
	return result
end

-- @return Issue[], keys are issues, and values are a list of (child) issues
function IssueCollection:grouped_filtered_issues()
	local issues = self:filtered_issues()
	local out = {}
	for _, v in pairs(issues) do
		if v.parent == nil then
			out[v] = vim.tbl_map(function(e)
				return self.issues[e]
			end, v.subtasks)
		end
	end
	return out
end

function IssueCollection:_bind_users() end

--- Updates `issue.subtasks` collection for every parent task.
-- We only have string references to parent / child, not the actual
-- objects themselves. However, it's possible to get the parent by just
-- doing `IssueCollection.issues[issue.parent]`
function IssueCollection:_bind_parent_and_subtasks()
	for _, issue in pairs(self.issues) do
		local parent_key = issue.parent
		if parent_key ~= nil then
			local parent = self.issues[parent_key]
			-- issue.parent = parent
			table.insert(parent.subtasks, 1, issue.id)
		end
	end
end

--- A jira issue
-- @field key str
-- @field assignee str
-- @field summary str
-- @field status str "To Do|In Progress|Review|Done"
-- @field url str
-- @field sprint_no str
-- @field parent nil|Issue
-- @field subtasks nil|array[Issue]
--
Issue = class(function(self)
	self._modifications = {}
	self.parent = nil
	self.subtasks = {}
end)

function Issue:is_modified()
	return #self._modifications > 0
end
Sprint = class(function(self, id, name)
	self.id = id
	self.name = name
end)

--- Create an `Issue` from a json entry
-- This does not bind the issue to its parents (if any) or subtasks. In other words,
-- if `Issue.parent` is not nil, it'll be a string which is the key to the parent task,
-- and some other function should probably bind the task to its parent task (and vice
-- versa).
-- @param entry the json entry (object)
function Issue.from_json_entry(entry)
	local out = Issue()
	out.key = entry.key
	out.id = tonumber(entry.id)
	out.assignee = utils.lookup(entry.fields, "assignee", "emailAddress")
	out.summary = string.gsub(utils.lookup(entry.fields, "summary"), "\n", "") -- strip newlines
	out.status = utils.lookup(entry.fields.status, "name")
	out.url = nil
	out.sprint = Sprint(
		utils.lookup(entry.fields, "customfield_10020", 1, "name"),
		utils.lookup(entry.fields, "customfield_10020", 1, "id")
	)
	out.parent = utils.lookup(entry.fields, "parent", "id")
	if out.parent ~= nil then
		out.parent = tonumber(out.parent)
	end
	return out
end

function Issue:refresh()
	-- os.execute("sleep 2")
	local cmd = 'jira list -q "id=' .. self.key .. '" ' .. table.concat(JIRA_DEFAULT_ARGS, " ")
	local json_response = vim.fn.json_decode(vim.fn.system(cmd))
	local refreshed = Issue.from_json_entry(json_response.issues[1])
	for k, v in pairs(refreshed) do
		self[k] = v
	end
end

function Issue:flush_changes(jira_executable)
	for _, change in ipairs(self._modifications) do
		local cmd = jira_executable .. " " .. change.cmd .. " " .. table.concat(change.args, " ")

		vim.fn.system(cmd)
		if vim.v.shell_error > 0 then
			utils.echo_warning("Failed to flush changes, got exit code: " .. vim.v.shell_error)
		end
	end
	self:refresh()
end

function Issue:is_in_current_sprint() end

function Issue:next_state()
	local i = utils.tbl_index(TransitionState, function(s)
		return self.status == s
	end)
	assert(i ~= -1)
	if i == 4 then
		utils.echo_warning('Tried to go to next state but already is in "Done" state')
		return
	end
	local new_state = '"' .. TransitionState[i + 1] .. '"' -- quote them
	local change = IssueModification.transition(self, new_state)
	table.insert(self._modifications, change)
end

function Issue:prev_state()
	local i = utils.tbl_index(TransitionState, function(s)
		return self.status == s
	end)
	assert(i ~= -1)
	if i == 0 then
		utils.echo_warning('Tried to go to previous state but already is in "To Do" state')
		return
	end
	local new_state = '"' .. TransitionState[i - 1] .. '"' -- quote them
	local change = IssueModification.transition(self, new_state)
	table.insert(self._modifications, change)
end

function Issue:add_worklog() end

function Issue:update_remaining_hours() end

function Issue:clock_in() end

function Issue:clock_out() end

IssueModification = class(function(self)
	self.cmd = nil
	self.args = nil
end)

function IssueModification.transition(issue, new_state)
	local obj = IssueModification()
	obj.cmd = "transition"
	obj.args = { new_state, issue.key, "--noedit" }
	return obj
end

--- Compute the net change that would happen if we applied all modifications
-- @param modifications array[IssueModification]
-- @return array[IssueModification] a new collection of modifications, possibly smaller than the original set, but yields the same net change.
function IssueModification.get_net_modifications(modifications) end

--- Creates a new Jira board object
-- This is a high-level object that holds all issues and configuration
Board = class(function(b, config, issues)
	b.config = config
	b.issues = issues
	-- return b
end)

--- Loads and stores all issues in `self.issues`, removing any existing changes.
function Board:load_issues()
	self.issues = IssueCollection.load_from_jira_cli(self.config.jira_executable)
	self.issues:_bind_parent_and_subtasks()
	self.issues:_bind_users()
	-- self.issues:filter_by_assignee("Mikael Kvalvær")
end
function Board:print_me()
	return self, self.issues, self.config
end

mod.Issue = Issue
mod.IssueCollection = IssueCollection
mod.Board = Board
return mod
