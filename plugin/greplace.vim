" File: greplace.vim
" Script to search and replace pattern across multiple files
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 1.2
" Last Modified: March 2, 2018
"
" Copyright: Copyright (C) 2007-2018 Yegappan Lakshmanan
"            Permission is hereby granted to use and distribute this code,
"            with or without modifications, provided that this copyright
"            notice is copied with it. Like anything else that's free,
"            greplace.vim is provided *as is* and comes with no warranty of
"            any kind, either expressed or implied. In no event will the
"            copyright holder be liable for any damamges resulting from the
"            use of this software.
"
if exists("loaded_greplace")
    finish
endif
let loaded_greplace = 1

" Requires Vim 7.0 and above
if v:version < 700
    finish
endif

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

" User-visible commands for using this plugin
command! -nargs=0 Gqfopen call greplace#show_matches('')
command! -nargs=* -complete=file Gsearch call greplace#search('grep', <f-args>)
command! -nargs=* Gargsearch call greplace#search('args', <f-args>)
command! -nargs=* Gbuffersearch call greplace#search('buffer', <f-args>)

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save

