yankstack.vim
=============

[Yankstack.vim](https://github.com/maxbrunsfeld/vim-yankstack) is a lightweight
implementation of the Emacs 'kill ring' for Vim.  It allows you to yank and
delete things without worrying about losing the text that you yanked
previously. It effectively turns your default register into a stack, and lets
you cycle through the items in the stack after doing a paste.

This plugin is intended to be a simpler alternative to the
[yankring](https://github.com/chrismetcalf/vim-yankring) plugin.

## Installation ##

I recommend loading your plugins with
[pathogen](https://github.com/tpope/vim-pathogen), so you can just clone this
repo into your ```bundle``` directory.

## Compatibility ##

Yankstack works by mapping the yank and paste keys to functions that do some
book-keeping before calling through to the normal yank/paste keys. You may want
to define your own mappings of the yank and paste keys. For example, I like to
map the ```Y``` key to ```y$```, so that it behaves the same as ```D``` and
```C```. The yankstack mappings need to happen **before** you define any such
mappings of your own. To achieve this, just call ```yankstack#setup()``` in
your vimrc, before defining your mappings:

```
call yankstack#setup()
nmap Y y$
" other mappings involving y, d, c, etc
```

## Key Bindings ##

By default, yankstack adds only 2 key bindings, in normal and visual modes:

- ```alt-p```  - cycle *backward* through your history of yanks

- ```alt-shift-p```  - cycle *forwards* through your history of yanks

After pasting some text using ```p``` or ```P```, you can cycle through your
yank history using these commands.

## Commands ##

You can see the contents of the yank-stack using the ```:Yanks``` command.
Its output is similar to the ```:registers``` command.

## Configuration ##

Yankstack defines three plugin mappings that you can map to keys of your choosing.
The same mappings work in normal and insert modes.

- ```<Plug>yankstack_substitute_older_paste``` - cycle backwards through your history of yanks
- ```<Plug>yankstack_substitute_newer_paste``` - cycle forwards through your history of yanks
- ```<Plug>yankstack_insert_mode_paste``` - paste in insert mode, and create an undo entry, so that yankstack will register the paste

For example, if you wanted to define some mappings based on your 'leader' key,
you could do this:

```
nmap <leader>p <Plug>yankstack_substitute_older_paste
nmap <leader>P <Plug>yankstack_substitute_older_paste
```

Or, if you wanted to define emacs style bindings in insert mode, you could do this:

```
imap <C-y> <Plug>yankstack_insert_mode_paste
imap <M-y> <Plug>yankstack_substitute_older_paste
imap <M-Y> <Plug>yankstack_substitute_older_paste
```

Also, if you want to load yankstack without the default key mappings, just
``` let g:yankstack_map_keys = 0 ```
in your .vimrc file.

## Contributing, Feedback ##

I'd enjoy hearing anybody's feedback on yankstack, and welcome any contribution.
Check it out on [github](https://github.com/maxbrunsfeld/vim-yankstack)!


