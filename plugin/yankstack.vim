"
" TODO
"
" - make :Yanks command display number of lines in yank
"
" - investigate whether an s: variable is the best way to
"   scope the yankstack_tail
"
" - support repeat.vim
"

let s:yankstack_tail = []
let g:yankstack_size = 30
let s:last_paste = { 'undo_number': -1, 'key': '', 'mode': 'normal' }

function! s:yank_with_key(key)
  call s:yankstack_before_add()
  return a:key
endfunction

function! s:paste_with_key(key, mode)
  if a:mode == 'visual'
    call s:yankstack_before_add()
    call s:yankstack_rotate(1)
  endif
  let s:last_paste = { 'undo_number': s:get_next_undo_number(), 'key': a:key, 'mode': a:mode }
  return a:key
endfunction

function! s:substitute_paste(offset)
  if s:get_current_undo_number() != s:last_paste.undo_number
    echo 'Last change was not a paste'
    return
  endif
  silent undo
  call s:yankstack_rotate(a:offset)
  call s:paste_from_yankstack()
endfunction

function! s:yankstack_before_add()
  let head = s:get_yankstack_head()
  if !empty(head.text) && (empty(s:yankstack_tail) || (head != s:yankstack_tail[0]))
    call insert(s:yankstack_tail, head)
    let s:yankstack_tail = s:yankstack_tail[: g:yankstack_size]
  endif
endfunction

function! s:yankstack_rotate(offset)
  if empty(s:yankstack_tail) | return | endif
  let offset_left = a:offset
  while offset_left != 0
    let head = s:get_yankstack_head()
    if offset_left > 0
      let entry = remove(s:yankstack_tail, 0)
      call add(s:yankstack_tail, head)
      let offset_left -= 1
    elseif offset_left < 0
      let entry = remove(s:yankstack_tail, -1)
      call insert(s:yankstack_tail, head)
      let offset_left += 1
    endif
    call s:set_yankstack_head(entry)
  endwhile
endfunction

function! s:paste_from_yankstack()
  let [&autoindent, save_autoindent] = [0, &autoindent]
  let s:last_paste.undo_number = s:get_next_undo_number()
  if s:last_paste.mode == 'insert'
    silent exec 'normal! a' . s:last_paste.key
  elseif s:last_paste.mode == 'visual'
    let head = s:get_yankstack_head()
    silent exec 'normal! gv' . s:last_paste.key
    call s:set_yankstack_head(head)
  else
    silent exec 'normal!' s:last_paste.key
  endif
  let &autoindent = save_autoindent
endfunction

function! s:get_yankstack_head()
  return { 'text': getreg('"'), 'type': getregtype('"') }
endfunction

function! s:set_yankstack_head(entry)
  call setreg('"', a:entry.text, a:entry.type)
endfunction

function! s:get_next_undo_number()
  return undotree().seq_last + 1
endfunction

function! s:get_current_undo_number()
  let entries = undotree().entries
  if !empty(entries) && has_key(entries[-1], 'curhead')
    return s:get_parent_undo_number()
  else
    return undotree().seq_cur
  endif
endfunction

function! s:get_parent_undo_number()
  let entry = undotree().entries[-1]
  while has_key(entry, 'alt')
    let entry = entry.alt[0]
  endwhile
  return entry.seq - 1
endfunction

function! s:show_yanks()
  echohl WarningMsg | echo "--- Yanks ---" | echohl None
  let i = 0
  for yank in [s:get_yankstack_head()] + s:yankstack_tail
    let i += 1
    echo s:format_yank(yank.text, i)
  endfor
endfunction
command! -nargs=0 Yanks call s:show_yanks()

function! s:format_yank(yank, i)
  let line = printf("%-4d %s", a:i, a:yank)
  return split(line, '\n')[0][: 80]
endfunction

function! s:define_yank_and_paste_mappings()
  let yank_keys  = ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C', 'p', 'P']
  let paste_keys = ['p', 'P']
  for key in yank_keys
    exec 'nnoremap <expr> <Plug>yankstack_' . key '<SID>yank_with_key("' . key . '")'
    exec 'xnoremap <expr> <Plug>yankstack_' . key '<SID>yank_with_key("' . key . '")'
  endfor
  for key in paste_keys
    exec 'nnoremap <expr> <Plug>yankstack_' . key '<SID>paste_with_key("' . key . '", "normal")'
    exec 'xnoremap <expr> <Plug>yankstack_' . key '<SID>paste_with_key("' . key . '", "visual")'
  endfor
endfunction

call s:define_yank_and_paste_mappings()
call yankstack#setup()

nnoremap <silent> <Plug>yankstack_substitute_older_paste  :<C-u>call <SID>substitute_paste(v:count1)<CR>
nnoremap <silent> <Plug>yankstack_substitute_newer_paste  :<C-u>call <SID>substitute_paste(-v:count1)<CR>
inoremap <silent> <Plug>yankstack_substitute_older_paste  <C-o>:<C-u>call <SID>substitute_paste(v:count1)<CR>
inoremap <silent> <Plug>yankstack_substitute_newer_paste  <C-o>:<C-u>call <SID>substitute_paste(-v:count1)<CR>
inoremap <expr>   <Plug>yankstack_insert_mode_paste       <SID>paste_with_key('<C-g>u<C-r>"', 'insert')

if !exists('g:yankstack_map_keys') || g:yankstack_map_keys
  nmap [p    <Plug>yankstack_substitute_older_paste
  nmap ]p    <Plug>yankstack_substitute_newer_paste
  imap <M-y> <Plug>yankstack_substitute_older_paste
  imap <M-Y> <Plug>yankstack_substitute_newer_paste
  imap <C-y> <Plug>yankstack_insert_mode_paste
endif

