function! yankstack#setup()
  if exists('g:yankstack_did_setup') | return | endif
  let g:yankstack_did_setup = 1

  let yank_keys  = ['c', 'C', 'd', 'D', 's', 'S', 'x', 'X', 'y', 'Y']
  let paste_keys = ['p', 'P']

  for key in yank_keys + paste_keys
    exec 'nmap' key '<Plug>yankstack_key_' . key
    exec 'xmap' key '<Plug>yankstack_key_' . key
  endfor
endfunction

