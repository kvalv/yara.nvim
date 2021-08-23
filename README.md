yara.nvim
===
yet another jira wrapper (for neovim)

This plugin enables the most used jira workflows inside of neovim using as few keystrokes as possible.

----

### Quickstart

#### Preqrequisites
You need [go-jira][go-jira] installed! It should work once you're able to run `jira list` in your terminal and it returns a list of issues.

#### Installation
Use your favourite package manager.

```
Plug 'kvalv/yara.nvim'
```

Additional options can be provided like this (full syntax for `format.lines` will be provided once it's a bit more stable):
```
lua << EOF
require('yara').setup({
    jira_executable = "jira",
    email = "some-email@bigcorp.com",
    format = {
        lines = {
            "$(key) by $(assignee:unassigned) in $(sprint.name:backlog) [$(status)]", 
            "$(time.spent) / $(time.estimate)",
            "$(summary)",
            "",
        }
    }
})
EOF
```

#### Usage
Once installed, you can open up the window by calling `:YaraOpen`. Keys:

* `>`: Move issue to next state
* `<`: Move issue to previous state
* `I`: Toggle showing issues only to the current user (i.e. issues connected to the e-mail you wrote in the config).
* `S`: Toggle showing issues only in the current sprint
* `s`: Display a menu where you can select issues in a particular sprint (or backlog). E.g. `s0` will display issues only in the backlog.
* `P`: Interactively add worklog hours for the task the cursor is on

----

### Motivation

The Jira web interface is not ideal for frequent viewing and updating tasks during a sprint. Consequently, tracking tasks properly is
not easy to do, and I lose a lot of learning and insight by not keeping the tasks up-to-date. This plugin seeks to make it
easier to view, filter and update my tasks in a sprint.

Better documentation / customization will probably come in place once all the feature goals are in place.

### Feature goals (somewhat in order)

- [x] List all tasks, along with status and assignee
- [x] Filter by current user
- [x] View issues hierarchically; tasks and subtasks are grouped together.
- [x] Move tasks forward (`>`) and backwards (`<`)
- [ ] Filter by other users
- [x] View issues in backlog, current sprint, next sprint etc.
- [ ] bind git branches to tasks, and automatically track time used
- [ ] Bugs are displayed distinctively
- [ ] Refresh tasks
- [x] Log hours on tasks
- [ ] Create new tasks

[go-jira]: https://github.com/go-jira/jira
