function! yankstack#setup()
  if exists('g:yank_list_did_mappings') | return | endif
  let g:yank_list_did_mappings = 1
  for key in ['x', 'y', 'd', 'c', 'X', 'Y', 'D', 'C', 'p', 'P']
    exec 'nmap' key '<Plug>yanklist_' . key
    exec 'xmap' key '<Plug>yanklist_' . key
  endfor
endfunction

