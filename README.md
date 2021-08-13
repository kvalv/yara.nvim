yara.nvim
===
yet another jira wrapper for neovim

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

Additional options (currently only e-mail and executable) can be provided like this:
```
lua << EOF
require('yara').setup({
    jira_executable="jira",
    email="some-email@bigcorp.com",
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

----

### Motivation

Jira is a behemoth that serves all kinds of organizations and workflows. Consequently, it has a vast web interface that is slow
and painful to use. As a developer, I want jira to stay out of my way as much as possible so I can focus on software development rather than spending time in jira. This plugin aims to make it as easy as possible to do the basic workflows related to agile development in jira.

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
- [ ] Log hours on tasks
- [ ] Create new tasks

[go-jira]: https://github.com/go-jira/jira
