syn match Author '<.*>'
" syn region description start="XX" end="XX" transparent fold
syn match issue_header '^[-*].*' contains=issue_status,issue_header,issue_key

syn match issue_status /\[.*\]/
syn match issue_author /<.*>/
syn match issue_key '^[*-]\s\+\S\+'

" group name for conventions.. :h group-name
hi def link description Comment
hi def link issue_status Comment
hi def link issue_author Statement
hi def link issue_key Constant
