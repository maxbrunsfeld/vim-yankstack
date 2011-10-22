yankstack.vim
=============

Yankstack.vim is a lightweight implementation of the Emacs 'kill ring' for Vim.
It allows you to yank and delete things without worrying about losing the text
that you yanked previously. It effectively turns your default register into a stack,
and lets you cycle through the items in the stack after doing a paste.

This plugin is intended to be a simpler alternative to the [yankring](https://github.com/chrismetcalf/vim-yankring) plugin.

## Installation ##

I recommend loading your plugins with [pathogen](https://github.com/tpope/vim-pathogen), so you can
just clone this repo into your ```bundle``` directory.

## Configuration ##

Here are the mappings that this plugins defines.

```unimpaired.vim```-style mappings in normal mode:

- ```[p (yankstack_substitute_older_paste)``` - cycle backward through the history of strings you've yanked

- ```]p - (yankstack_substitute_newer_paste)``` - cycle forwards through the history of strings you've yanked

emacs-style mappings in insert mode:

- ```CTRL-y ``` - create an undo entry and paste (yankstack needs an undo entry to recognize pastes)

- ```ALT-y``` - cycle backwards through the history of strings you've yanked

- ```ALT-Y``` - cycle forwards through the history of strings you've yanked

After pasting some text using ```p``` or ```P```, you can cycle through your yank history using these commands.

If you want to load yankstack without defining any of the default key mappings, just
``` let g:yankstack_map_keys = 0 ```
in your .vimrc file.

