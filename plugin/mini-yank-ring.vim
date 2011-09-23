let s:yank_keys  = ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C']
let s:paste_keys = ['p', 'P']

if !exists('s:yank_ring')
  let s:yank_ring = []
endif
if !exists('s:yank_ring_max')
  let s:yank_ring_max = 50
endif

function! g:yank_ring()
  return [getreg('"')] + s:yank_ring
endfunction

function! g:yank_ring_max(...)
  if a:0 > 0
    let s:yank_ring_max = max([a:1, 1])
    call s:yank_ring_truncate()
  endif
  return s:yank_ring_max
endfunction

function! s:yank_ring_push_last_yank_and_return_argument(input)
  let last_yank = getreg('"')
  call s:yank_ring_push(last_yank)
  call s:yank_ring_truncate()
  return a:input
endfunction

function! s:yank_ring_substitute_older_paste()
  for paste_key in s:paste_keys
    if s:last_change_was_equivalent_to_normal(paste_key)
      echo 'Last change was' paste_key
      silent undo
      call s:yank_ring_step_backwards()
      exec 'normal!' paste_key
      return
    endif
  endfor
  echo 'Last change was not a paste'
endfunction

function! s:yank_ring_substitute_newer_paste()
  for paste_key in s:paste_keys
    if s:last_change_was_equivalent_to_normal(paste_key)
      echo 'Last change was' paste_key
      silent undo
      call s:yank_ring_step_forwards()
      exec 'normal!' paste_key
      return
    endif
  endfor
  echo 'Last change was not a paste'
endfunction

function! s:yank_ring_step_forwards()
  call s:yank_ring_push(getreg('"'))
  call setreg('"', remove(s:yank_ring, -1))
endfunction

function! s:yank_ring_step_backwards()
  call s:yank_ring_unshift(getreg('"'))
  call setreg('"', remove(s:yank_ring, 0))
endfunction

function! s:yank_ring_push(item)
  let item_is_new = (len(a:item) > 0) && (len(s:yank_ring) == 0 || a:item != s:yank_ring[-1])
  if item_is_new
    call insert(s:yank_ring, a:item)
  endif
endfunction

function! s:yank_ring_unshift(item)
  let item_is_new = (len(a:item) > 0) && (len(s:yank_ring) == 0 || a:item != s:yank_ring[-1])
  if item_is_new
    call add(s:yank_ring, a:item)
  endif
endfunction

function! s:yank_ring_pop(item)
  return remove(s:yank_ring, 0)
endfunction

function! s:yank_ring_shift(item)
  return remove(s:yank_ring, -1)
endfunction

function! s:yank_ring_truncate()
  let s:yank_ring = s:yank_ring[: s:yank_ring_max-1]
endfunction

function! s:last_change_was_equivalent_to_normal(input)
  let current_position = getpos('.')
  let current_undo_number = undotree()['seq_cur']
  silent undo
  exec 'normal!' a:input
  let change_line = line('.')
  let change_text = getline(change_line-2, change_line+2)
  exec 'silent undo' current_undo_number
  call setpos('.', current_position)
  let current_line = line('.')
  let current_text = getline(change_line-2, change_line+2)
  return (current_line == change_line) && (current_text == change_text)
endfunction

for s:yank_key in s:yank_keys
  exec 'noremap <expr> <Plug>yank_ring_'. s:yank_key '<SID>yank_ring_push_last_yank_and_return_argument("'. s:yank_key .'")'
endfor
nnoremap <silent> <Plug>yank_ring_substitute_older_paste :call <SID>yank_ring_substitute_older_paste()<CR>
nnoremap <silent> <Plug>yank_ring_substitute_newer_paste :call <SID>yank_ring_substitute_newer_paste()<CR>
inoremap <silent> <Plug>yank_ring_substitute_older_paste <C-o>:call <SID>yank_ring_substitute_older_paste()<CR>
inoremap <silent> <Plug>yank_ring_substitute_newer_paste <C-o>:call <SID>yank_ring_substitute_newer_paste()<CR>

if !exists('s:yank_ring_map_keys')
  let s:yank_ring_map_keys = 1
endif

if s:yank_ring_map_keys
  for s:yank_key in s:yank_keys
    exec 'nmap' s:yank_key '<Plug>yank_ring_'. s:yank_key
    exec 'xmap' s:yank_key '<Plug>yank_ring_'. s:yank_key
  endfor
  nmap [p <Plug>yank_ring_substitute_older_paste
  nmap ]p <Plug>yank_ring_substitute_newer_paste
  imap <M-y> <Plug>yank_ring_substitute_older_paste
  imap <M-Y> <Plug>yank_ring_substitute_newer_paste

  inoremap <C-y> <C-g>u<C-r>"
endif

