" File: greplace.vim
" Script to search and replace pattern across multiple files
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 2.0
" Last Modified: March 5, 2018
"
" License: MIT License
" Copyright (c) 2007-2018 Yegappan Lakshmanan
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.
" =======================================================================

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
