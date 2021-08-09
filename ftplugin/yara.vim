nnoremap <buffer> <nowait> <silent> q :bw!<CR>
nnoremap <buffer> <nowait> <silent> <Esc> :bw!<CR>

nnoremap <buffer> <nowait> <silent> > :lua require("yara.mappings").current_issue_next_state()<CR>
nnoremap <buffer> <nowait> <silent> < :lua require("yara.mappings").current_issue_prev_state()<CR>
nnoremap <buffer> <nowait> <silent> I :lua require("yara.mappings").toggle_filter_only_current_user()<CR>
nnoremap <buffer> <nowait> <silent> s :lua require("yara.mappings").toggle_filter_by_active_sprint()<CR>

augroup _yara_mappings
    autocmd!
    autocmd BufWipeout <buffer> lua _G.yara.view:dispose()
augroup END
