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

This plugin defines four main commands, with the following default mappings:

- ```[p - yankstack_substitute_older_paste```

- ```[P - yankstack_substitute_oldest_paste```

- ```]p - yankstack_substitute_newer_paste```

- ```]P - yankstack_substitute_newest_paste```

After pasting some text using ```p``` or ```P```, you can cycle through your yank history using these commands.

If you want to load yankstack without defining any of the default key mappings, just
``` let g:yankstack_map_keys = 0 ```
in your .vimrc file.

