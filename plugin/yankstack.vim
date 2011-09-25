" TODO
"
" - when in visual mode, pasting should also add the last yank to the stack,
"   because the default register will get overwritten by the text that is
"   pasted over.
"
" - after yanking in visual block mode, then moving the text from the original
"   register to the yankstack and back, the paste no longer comes out as a visual
"   block paste.
"   Are there some special characters in the ststack that indicate that it was
"   yanked in visual block mode, and which need to be preserved?

function! g:get_current_undo_number()
  return s:get_current_undo_number()
endfunction
function! g:get_parent_undo_number()
  return s:get_parent_undo_number()
endfunction

let s:yank_keys  = ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C', 'p', 'P']
let s:paste_keys = ['p', 'P']

if !exists('s:yank_stack')
  let s:yank_stack = []
endif
if !exists('g:yank_stack_size')
  let g:yank_stack_size = 50
endif
if !exists('s:last_paste')
  let s:last_paste = { 'parent_undo_number': -1 }
endif

function! g:yank_stack(...)
  let list = [getreg('"')] + s:yank_stack
  if a:0 == 0
    return list
  else
    let index = a:1 % len(s:yank_stack)
    return list[index]
  end
endfunction

function! s:save_last_yank_and_return(input)
  call s:yank_stack_add(getreg('"'))
  return a:input
endfunction

function! s:save_new_paste_and_return(input)
  let s:last_paste = {
        \ 'undo_number': s:get_next_undo_number(),
        \ 'paste_key': a:input,
        \ 'stack_index': 0
        \ }
  return a:input
endfunction

function! s:substitute_paste(index_delta)
  if s:get_current_undo_number() == s:last_paste.undo_number
    silent undo
    let save_register = getreg('"')
    let s:last_paste.stack_index += a:index_delta
    call setreg('"', g:yank_stack(s:last_paste.stack_index))
    exec 'normal!' s:last_paste.paste_key
    call setreg('"', save_register)
    let s:last_paste.undo_number = s:get_current_undo_number()
    echo 'stack index:' s:last_paste.stack_index
  else
    echo 'Last change was not a paste'
  endif
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

for s:yank_key in s:yank_keys
  exec 'noremap <expr> <Plug>yank_stack_'. s:yank_key '<SID>save_last_yank_and_return("'. s:yank_key .'")'
endfor
for s:paste_key in s:paste_keys
  exec 'noremap <expr> <Plug>yank_stack_'. s:paste_key '<SID>save_new_paste_and_return("'. s:paste_key .'")'
endfor
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
  nmap [p <Plug>yank_stack_substitute_older_paste
  nmap ]p <Plug>yank_stack_substitute_newer_paste
  imap <M-y> <Plug>yank_stack_substitute_older_paste
  imap <M-Y> <Plug>yank_stack_substitute_newer_paste
  imap <C-y> <C-g>u<C-r>"
endif

