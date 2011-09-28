"
" TODO
"
" - when in visual mode, pasting should also add the last yank to the stack,
"   because the default register will get overwritten by the text that is
"   pasted over.
"
" - after yanking in visual block mode, then moving the text from the original
"   register to the yankstack and back, the paste no longer comes out as a visual
"   block paste.
"   Are there some special characters in the text that indicate that it was
"   yanked in visual block mode, and which need to be preserved?

if !exists('s:yank_stack') || !exists('g:yank_stack_size') || !exists('s:last_paste')
  let s:yank_stack = []
  let g:yank_stack_size = 30
  let s:last_paste = { 'undo_number': -1 }
endif

function! g:yank_stack(...)
  let list = [@@] + s:yank_stack
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
    let s:last_paste.index += a:offset
    call s:paste_from_yankstack()
    echo 'stack index:' s:last_paste.index
  else
    echo 'Last change was not a paste'
  endif
endfunction

function! s:paste_from_yankstack()
  let [save_register, save_autoindent] = [@@, &autoindent]
  let [@@, &autoindent] = [g:yank_stack(s:last_paste.index), 0]
  let command = (s:last_paste.mode == 'i') ? 'normal! a' : 'normal! '
  silent exec command . s:last_paste.keys
  let s:last_paste.undo_number = s:get_current_undo_number()
  let [@@, &autoindent] = [save_register, save_autoindent]
endfunction

function! s:yank_with_key(...)
  let keys = a:1
  call s:yank_stack_add(@@)
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

function! s:yank_stack_add(item)
  let item_is_new = !empty(a:item) && empty(s:yank_stack) || (a:item != s:yank_stack[0])
  if item_is_new
    call insert(s:yank_stack, a:item)
  endif
  let s:yank_stack = s:yank_stack[: g:yank_stack_size-1]
endfunction

let s:yank_keys  = ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C', 'p', 'P']
let s:paste_keys = ['p', 'P']

for s:yank_key in s:yank_keys
  exec 'noremap <expr> <Plug>yank_stack_'. s:yank_key '<SID>yank_with_key("'. s:yank_key .'")'
endfor
for s:paste_key in s:paste_keys
  exec 'noremap <expr> <Plug>yank_stack_'. s:paste_key '<SID>paste_with_key("'. s:paste_key .'")'
endfor
inoremap <expr>   <Plug>yank_stack_insert_mode_paste      <SID>paste_with_key('<C-g>u<C-r>"', 'i')
nnoremap <silent> <Plug>yank_stack_substitute_older_paste :call <SID>substitute_paste(1)<CR>
nnoremap <silent> <Plug>yank_stack_substitute_newer_paste :call <SID>substitute_paste(-1)<CR>
inoremap <silent> <Plug>yank_stack_substitute_older_paste <C-o>:call <SID>substitute_paste(1)<CR>
inoremap <silent> <Plug>yank_stack_substitute_newer_paste <C-o>:call <SID>substitute_paste(-1)<CR>

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
  nmap [p    <Plug>yank_stack_substitute_older_paste
  nmap ]p    <Plug>yank_stack_substitute_newer_paste
  imap <C-y> <Plug>yank_stack_insert_mode_paste
  imap <M-y> <Plug>yank_stack_substitute_older_paste
  imap <M-Y> <Plug>yank_stack_substitute_newer_paste
endif

