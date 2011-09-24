" TODO
"
" - after yanking in visual block mode, then moving the text from the original
"   register to the yankstack and back, the paste no longer comes out as a visual
"   block paste.
"   Are there some special characters in the ststack that indicate that it was
"   yanked in visual block mode, and which need to be preserved?
"
" - when pasting in visual mode (overwriting text), the yank_stack
"   doesn't work
"
" - for every new paste, the yank stack should start at the latest yank

let s:yank_keys  = ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C', 'p', 'P']
let s:paste_keys = ['p', 'P']

if !exists('s:yank_stack')
  let s:yank_stack = []
endif
if !exists('s:yank_stack_max')
  let s:yank_stack_max = 50
endif
if !exists('s:last_paste')
  let s:last_paste = { 'parent_undo_number': -1 }
endif

function! g:yank_stack(...)
  let list = [getreg('"')] + s:yank_stack
  if a:0 == 0
    return list
  else
    let index = a:1 % len(list)
    return list[index]
  endif
endfunction

function! g:yank_stack_max(...)
  if a:0 > 0
    let s:yank_stack_max = max([a:1, 1])
    call s:yank_stack_truncate()
  endif
  return s:yank_stack_max
endfunction

function! g:yank_stack_last_paste()
  return s:last_paste
endfunction

function! s:push_last_yank_and_return(input)
  let last_yank = getreg('"')
  call s:yank_stack_push(last_yank)
  call s:yank_stack_truncate()
  return a:input
endfunction

function! s:record_new_paste_and_return(input)
  let current_undo_number = undotree()['seq_cur']
  let s:last_paste = {
        \ 'parent_undo_number': current_undo_number,
        \ 'paste_key': a:input,
        \ 'stack_index': 0
        \  }
  return a:input
endfunction

function! s:yank_stack_substitute_older_paste()
  let [save_cursor, save_register] = [getpos('.'), getreg('"')]
  silent undo
  if undotree()['seq_cur'] == s:last_paste['parent_undo_number']
    let s:last_paste['stack_index'] += 1
    call setreg('"', g:yank_stack(s:last_paste['stack_index']))
    silent 'normal!' s:last_paste['paste_key']
    call setreg('"', save_register)
  else
    echo 'Last change was not a paste'
    silent redo
    call setpos('.', save_cursor)
  endif
endfunction

function! s:yank_stack_substitute_newer_paste()
  let save_cursor = getpos('.')
  silent undo
  if undotree()['seq_cur'] == s:last_paste['parent_undo_number']
    let save_register = getreg('"')
    let s:last_paste['stack_index'] -= 1
    call setreg('"', g:yank_stack(s:last_paste['stack_index']))
    exec 'normal!' s:last_paste['paste_key']
    call setreg('"', save_register)
  else
    echo 'Last change was not a paste'
    silent redo
    call setpos('.', save_cursor)
  endif
endfunction

function! s:yank_stack_push(item)
  let item_is_new = !empty(a:item) && empty(s:yank_stack) || (a:item != s:yank_stack[0])
  if item_is_new
    call insert(s:yank_stack, a:item)
  endif
endfunction

function! s:yank_stack_truncate()
  let s:yank_stack = s:yank_stack[: s:yank_stack_max-1]
endfunction

for s:yank_key in s:yank_keys
  exec 'noremap <expr> <Plug>yank_stack_'. s:yank_key '<SID>push_last_yank_and_return("'. s:yank_key .'")'
endfor
for s:paste_key in s:paste_keys
  exec 'noremap <expr> <Plug>yank_stack_'. s:paste_key '<SID>record_new_paste_and_return("'. s:paste_key .'")'
endfor

nnoremap <silent> <Plug>yank_stack_substitute_older_paste :call <SID>yank_stack_substitute_older_paste()<CR>
nnoremap <silent> <Plug>yank_stack_substitute_newer_paste :call <SID>yank_stack_substitute_newer_paste()<CR>
inoremap <silent> <Plug>yank_stack_substitute_older_paste <C-o>:call <SID>yank_stack_substitute_older_paste()<CR>
inoremap <silent> <Plug>yank_stack_substitute_newer_paste <C-o>:call <SID>yank_stack_substitute_newer_paste()<CR>

if !exists('s:yank_stack_map_keys')
  let s:yank_stack_map_keys = 1
endif

if s:yank_stack_map_keys
  for s:paste_key in s:paste_keys
    exec 'map' s:paste_key '<Plug>yank_stack_'. s:paste_key
  endfor
  for s:yank_key in s:yank_keys
    exec 'map' s:yank_key '<Plug>yank_stack_'. s:yank_key
  endfor
  map [p <Plug>yank_stack_substitute_older_paste
  map ]p <Plug>yank_stack_substitute_newer_paste
  imap <M-y> <Plug>yank_stack_substitute_older_paste
  imap <M-Y> <Plug>yank_stack_substitute_newer_paste
  inoremap <C-y> <C-g>u<C-r>"
endif

