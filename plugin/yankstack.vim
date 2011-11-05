"
" TODO
"
" - support counts
"
" - make sure entries don't get unnecessarily repeated in the yank list
"
" - support repeat.vim
"
" - when yanking in visual block mode, store a flag with the yanked text
"   that it was a blockwise yank. then, when that text is pasted, use setreg
"   with the 'b' option to make the paste work blockwise.
"

let s:yanklist = []
let g:yanklist_size = 30
let s:last_paste = { 'undo_number': -1, 'key': '', 'mode': 'n' }

function! s:yank_with_key(key)
  call s:yanklist_add(@@)
  return a:key
endfunction

function! s:paste_with_key(key, mode)
  if a:mode == 'v'
    call s:yanklist_add(@@)
    call s:yanklist_rotate(1)
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
  call s:yanklist_rotate(a:offset)
  call s:paste_from_yanklist()
endfunction

function! s:yanklist_rotate(offset)
  if empty(s:yanklist)
    return
  elseif a:offset > 0
    call add(s:yanklist, getreg('"'))
    call setreg('"', remove(s:yanklist, 0))
  elseif a:offset < 0
    call insert(s:yanklist, getreg('"'))
    call setreg('"', remove(s:yanklist, -1))
  endif
endfunction

function! s:yanklist_add(item)
  if !empty(a:item) && empty(s:yanklist) || (a:item != s:yanklist[0])
    call insert(s:yanklist, a:item)
    let s:yanklist = s:yanklist[: g:yanklist_size]
  endif
endfunction

function! s:paste_from_yanklist()
  let [&autoindent, save_autoindent] = [0, &autoindent]
  let s:last_paste.undo_number = s:get_next_undo_number()
  if s:last_paste.mode == 'i'
    silent exec 'normal! a' . s:last_paste.key
  elseif s:last_paste.mode == 'v'
    silent exec 'normal! gv' . s:last_paste.key
  else
    silent exec 'normal!' s:last_paste.key
  endif
  let &autoindent = save_autoindent
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

nnoremap <silent> <Plug>yanklist_substitute_older_paste  :call <SID>substitute_paste(1)<CR>
inoremap <silent> <Plug>yanklist_substitute_older_paste  <C-o>:call <SID>substitute_paste(1)<CR>
nnoremap <silent> <Plug>yanklist_substitute_newer_paste  :call <SID>substitute_paste(-1)<CR>
inoremap <silent> <Plug>yanklist_substitute_newer_paste  <C-o>:call <SID>substitute_paste(-1)<CR>
inoremap <expr>   <Plug>yanklist_insert_mode_paste       <SID>paste_with_key('<C-g>u<C-r>"', 'i')

let s:yank_keys  = ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C', 'p', 'P']
let s:paste_keys = ['p', 'P']
for s:key in s:yank_keys
  exec 'nnoremap <expr> <Plug>yanklist_' . s:key '<SID>yank_with_key("' . s:key . '")'
  exec 'xnoremap <expr> <Plug>yanklist_' . s:key '<SID>yank_with_key("' . s:key . '")'
endfor
for s:key in s:paste_keys
  exec 'nnoremap <expr> <Plug>yanklist_' . s:key '<SID>paste_with_key("' . s:key . '", "n")'
  exec 'xnoremap <expr> <Plug>yanklist_' . s:key '<SID>paste_with_key("' . s:key . '", "v")'
endfor

if !exists('g:yanklist_map_keys') || g:yanklist_map_keys
  for s:key in s:yank_keys + s:paste_keys
    exec 'nmap' s:key '<Plug>yanklist_' . s:key
    exec 'xmap' s:key '<Plug>yanklist_' . s:key
  endfor
  nmap [p    <Plug>yanklist_substitute_older_paste
  nmap ]p    <Plug>yanklist_substitute_newer_paste
  imap <M-y> <Plug>yanklist_substitute_older_paste
  imap <M-Y> <Plug>yanklist_substitute_newer_paste
  imap <C-y> <Plug>yanklist_insert_mode_paste
endif

