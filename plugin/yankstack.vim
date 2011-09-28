"
" TODO
"
" - when in visual mode, pasting should also add the last yank to the stack,
"   because the default register will get overwritten by the text that is
"   pasted over.
"
" - after yanking in visual block mode, then moving the text from the original
"   register to the yankstack and back, the paste no longer comes out as a visual
"   block paste. Are there some special characters in the text that indicate that it was
"   yanked in visual block mode, and which need to be preserved?
"

if !exists('s:yankstack') || !exists('g:yankstack_size') || !exists('s:last_paste')
  let s:yankstack = []
  let g:yankstack_size = 30
  let s:last_paste = { 'undo_number': -1 }
endif

function! g:yankstack(...)
  let list = [@@] + s:yankstack
  if a:0 == 0
    return list
  else
    let index = a:1 % len(list)
    return list[index]
  end
endfunction

function! s:substitute_paste(offset)
  if s:get_current_undo_number() == s:last_paste.undo_number
    silent undo
    if a:offset == 'newest'
      let s:last_paste.index = 0
    elseif a:offset == 'oldest'
      let s:last_paste.index = len(s:yankstack)
    else
      let s:last_paste.index += a:offset
    endif
    call s:paste_from_yankstack()
    echo 'Yank-stack index:' s:last_paste.index
  else
    echo 'Last change was not a paste'
  endif
endfunction

function! s:paste_from_yankstack()
  let [save_register, save_autoindent] = [@@, &autoindent]
  let [@@, &autoindent] = [g:yankstack(s:last_paste.index), 0]
  let command = (s:last_paste.mode == 'i') ? 'normal! a' : 'normal! '
  silent exec command . s:last_paste.keys
  let s:last_paste.undo_number = s:get_current_undo_number()
  let [@@, &autoindent] = [save_register, save_autoindent]
endfunction

function! s:yank_with_key(...)
  let keys = a:1
  call s:yankstack_add(@@)
  return keys
endfunction

function! s:paste_with_key(...)
  let keys = a:1
  let mode = (a:0 > 1) ? a:2 : 'n'
  let s:last_paste = {
        \ 'undo_number': s:get_next_undo_number(),
        \ 'keys': keys,
        \ 'index': 0,
        \ 'mode': mode
        \ }
  return keys
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

function! s:yankstack_add(item)
  let item_is_new = !empty(a:item) && empty(s:yankstack) || (a:item != s:yankstack[0])
  if item_is_new
    call insert(s:yankstack, a:item)
  endif
  let s:yankstack = s:yankstack[: g:yankstack_size-1]
endfunction

nnoremap <silent> <Plug>yankstack_substitute_oldest_paste :call <SID>substitute_paste('oldest')<CR>
nnoremap <silent> <Plug>yankstack_substitute_newest_paste :call <SID>substitute_paste('newest')<CR>
nnoremap <silent> <Plug>yankstack_substitute_older_paste  :call <SID>substitute_paste(1)<CR>
nnoremap <silent> <Plug>yankstack_substitute_newer_paste  :call <SID>substitute_paste(-1)<CR>
inoremap <silent> <Plug>yankstack_substitute_older_paste  <C-o>:call <SID>substitute_paste(1)<CR>
inoremap <silent> <Plug>yankstack_substitute_newer_paste  <C-o>:call <SID>substitute_paste(-1)<CR>
inoremap <expr>   <Plug>yankstack_insert_mode_paste       <SID>paste_with_key('<C-g>u<C-r>"', 'i')

if !exists('g:yankstack_map_keys')
  let g:yankstack_map_keys = 1
endif

if g:yankstack_map_keys
  let s:yank_keys  = ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C', 'p', 'P']
  let s:paste_keys = ['p', 'P']
  for s:yank_key in s:yank_keys
    exec 'noremap <expr>' s:yank_key '<SID>yank_with_key("' . s:yank_key . '")'
  endfor
  for s:paste_key in s:paste_keys
    exec 'noremap <expr>' s:paste_key '<SID>paste_with_key("'. s:paste_key .'")'
  endfor
  nmap [p    <Plug>yankstack_substitute_older_paste
  nmap [P    <Plug>yankstack_substitute_oldest_paste
  nmap ]p    <Plug>yankstack_substitute_newer_paste
  nmap ]P    <Plug>yankstack_substitute_newest_paste
  imap <M-y> <Plug>yankstack_substitute_older_paste
  imap <M-Y> <Plug>yankstack_substitute_newer_paste
  imap <C-y> <Plug>yankstack_insert_mode_paste
endif

