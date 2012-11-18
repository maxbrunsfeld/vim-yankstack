" yankstack.vim - keep track of your history of yanked/killed text
"
" Maintainer:   Max Brunsfeld <https://github.com/maxbrunsfeld>
" Version:      1.0.5
" Todo:
"

let s:yankstack_tail = []
let g:yankstack_size = 30
let s:last_paste = { 'changedtick': -1, 'key': '', 'mode': 'n' }

function! s:yank_with_key(key)
  call s:before_yank()
  return a:key
endfunction

function! s:paste_with_key(key, mode, register, count)
  let with_count = a:count . a:key
  let keys = (a:register == s:default_register()) ? with_count : ('"' . a:register . with_count)
  return s:paste_from_yankstack(keys, a:mode, 1)
endfunction

function! s:paste_from_yankstack(key, mode, is_new)
  let s:last_paste = { 'changedtick': -1, 'key': a:key, 'mode': a:mode }
  call feedkeys("\<Plug>yankstack_after_paste", "m")

  if a:mode == 'n'
    exec 'normal!' a:key
  elseif a:mode == 'v'
    if a:is_new
      call s:before_yank()
      call feedkeys("\<Plug>yankstack_substitute_older_paste", "t")
      exec 'normal! gv' . a:key
    else
      let head = s:get_yankstack_head()
      exec 'normal! gv' . a:key
      call s:set_yankstack_head(head)
    endif

  " In insert mode, this function's return value is used in an
  " expression mapping. In other modes, it is called for its
  " side effects only.
  elseif a:mode == 'i'
    return a:key
  endif
endfunction

function! s:substitute_paste(offset, current_mode)
  if s:last_change_was_paste()
    let is_new = 0
    let mode = s:last_paste.mode
    let key = s:last_paste.key
    silent undo
    call s:yankstack_rotate(a:offset)
  else
    let is_new = 1
    let mode = a:current_mode
    let key = s:default_paste_key(a:current_mode)
  endif
  return s:paste_from_yankstack(key, mode, is_new)
endfunction

function! s:before_yank()
  let head = s:get_yankstack_head()
  if !empty(head.text) && (empty(s:yankstack_tail) || (head != s:yankstack_tail[0]))
    call insert(s:yankstack_tail, head)
    let s:yankstack_tail = s:yankstack_tail[: g:yankstack_size-1]
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

function! s:get_yankstack_head()
  let reg = s:default_register()
  return { 'text': getreg(reg), 'type': getregtype(reg) }
endfunction

function! s:set_yankstack_head(entry)
  let reg = s:default_register()
  call setreg(reg, a:entry.text, a:entry.type)
endfunction

function! s:after_paste()
  let s:last_paste.changedtick = b:changedtick
endfunction

function! s:last_change_was_paste()
  return b:changedtick == s:last_paste.changedtick
endfunction

function! s:default_register()
  let clipboard_flags = split(&clipboard, ',')
  if index(clipboard_flags, 'unnamedplus') >= 0
    return "+"
  elseif index(clipboard_flags, 'unnamed') >= 0
    return "*"
  else
    return "\""
  endif
endfunction

function! s:default_paste_key(mode)
  if a:mode == 'i'
    return "\<C-g>u\<C-r>" . s:default_register()
  else
    return "p"
  endif
endfunction

function! g:yankstack()
  return [s:get_yankstack_head()] + s:yankstack_tail
endfunction

command! -nargs=0 Yanks call s:show_yanks()
function! s:show_yanks()
  echohl WarningMsg | echo "--- Yanks ---" | echohl None
  let i = 0
  for yank in g:yankstack()
    call s:show_yank(yank, i)
    let i += 1
  endfor
endfunction

function! s:show_yank(yank, index)
  let index = printf("%-4d", a:index)
  let lines = split(a:yank.text, '\n')
  let line = empty(lines) ? '' : lines[0]
  let line = substitute(line, '\t', repeat(' ', &tabstop), 'g')
  if len(line) > 80 || len(lines) > 1
    let line = line[: 80] . '…'
  endif

  echohl Directory | echo  index
  echohl None      | echon line
  echohl None
endfunction

function! yankstack#setup()
  if exists('g:yankstack_did_setup') | return | endif
  let g:yankstack_did_setup = 1

  let yank_keys  = ['c', 'C', 'd', 'D', 's', 'S', 'x', 'X', 'y', 'Y']
  let paste_keys = ['p', 'P', 'gp', 'gP']
  let word_characters = split("qwertyuiopasdfghjklzxcvbnm1234567890_", '\zs')

  for key in yank_keys
    exec 'nnoremap <expr>'  key '<SID>yank_with_key("' . key . '")'
    exec 'xnoremap <expr>'  key '<SID>yank_with_key("' . key . '")'
  endfor

  let clear_cmd = ':echo ""<CR>'
  for key in paste_keys
    exec 'nnoremap' key ':<C-u>call <SID>paste_with_key("' . key . '", "n", v:register, v:count1)<CR>' . clear_cmd
    exec 'xnoremap' key ':<C-u>call <SID>paste_with_key("' . key . '", "v", v:register, v:count1)<CR>' . clear_cmd
  endfor

  for key in word_characters
    exec 'smap <expr>' key '<SID>yank_with_key("' . key . '")'
  endfor
endfunction

nnoremap <silent> <Plug>yankstack_substitute_older_paste :<C-u>call <SID>substitute_paste(v:count1, 'n')<CR>
nnoremap <silent> <Plug>yankstack_substitute_newer_paste :<C-u>call <SID>substitute_paste(-v:count1, 'n')<CR>
xnoremap <silent> <Plug>yankstack_substitute_older_paste :<C-u>call <SID>substitute_paste(v:count1, 'v')<CR>
xnoremap <silent> <Plug>yankstack_substitute_newer_paste :<C-u>call <SID>substitute_paste(-v:count1, 'v')<CR>
inoremap <silent> <Plug>yankstack_substitute_older_paste <C-r>=<SID>substitute_paste(v:count1, 'i')<CR>
inoremap <silent> <Plug>yankstack_substitute_newer_paste <C-r>=<SID>substitute_paste(-v:count1, 'i')<CR>

nnoremap <silent> <Plug>yankstack_after_paste :call <SID>after_paste()<CR>
xnoremap <silent> <Plug>yankstack_after_paste :<C-u>call <SID>after_paste()<CR>
inoremap <silent> <Plug>yankstack_after_paste <C-o>:call <SID>after_paste()<CR>

if !exists('g:yankstack_map_keys') || g:yankstack_map_keys
  nmap <M-p> <Plug>yankstack_substitute_older_paste
  xmap <M-p> <Plug>yankstack_substitute_older_paste
  imap <M-p> <Plug>yankstack_substitute_older_paste
  nmap <M-P> <Plug>yankstack_substitute_newer_paste
  xmap <M-P> <Plug>yankstack_substitute_newer_paste
  imap <M-P> <Plug>yankstack_substitute_newer_paste
endif

