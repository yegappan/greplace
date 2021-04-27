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

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

" Replace buffer name
if &isfname =~ '['
    let s:gRepl_bufname = '[Global\ Replace]'
else
    let s:gRepl_bufname = '\[Global\ Replace\]'
endif

let s:save_qf_list = {}

function! s:warn_msg(msg)
    echohl WarningMsg
    echomsg a:msg
    echohl None
endfunction

highlight GReplaceText term=reverse cterm=reverse gui=reverse

" get_changeset()
" Parse the lines in the Replace buffer and get a List of changed lines
function! s:get_changeset()
    let changeset = {}

    " Parse the replace buffer contents and get a List of changed lines
    let lines = getbufline('%', 1, '$')
    for l in lines
        if l !~ '[^:]\+:\d\+:.*'
            continue
        endif

        let match_l = matchlist(l, '\([^:]\+\):\(\d\+\):\(.*\)')
        let fname = match_l[1]
        let lnum = match_l[2]
        let text = match_l[3]

        let key = fname . ':' . lnum

	" Check whether the file and line number exists in the original list
	if !has_key(s:save_qf_list, key)
	    " User might have modified the filename or line number
	    continue
	endif

        if s:save_qf_list[key].text ==# text
            " This line is not changed
            continue
        endif

        let fname = s:save_qf_list[key].fname
        if !has_key(changeset, fname)
            let changeset[fname] = {}
        endif

        let changeset[fname][lnum] = text
    endfor

    return changeset
endfunction

" diff_line()
" Compute the diff between the old and new lines
" Returns the start index of the diff in the old line and the end index of the
" diff in the old and new lines as a list
function! s:diff_line(old_line, new_line)
    " Find the index of the leftmost character that is different
    let s_idx = 0
    while a:old_line[s_idx] ==# a:new_line[s_idx]
	let s_idx += 1
    endwhile

    " Find the index of the rightmost character that is different
    let e_idx1 = strlen(a:old_line) - 1
    let e_idx2 = strlen(a:new_line) - 1
    while e_idx1 >= 0 && e_idx1 > s_idx &&
		\ a:old_line[e_idx1] ==# a:new_line[e_idx2]
	let e_idx1 -= 1
	let e_idx2 -= 1
    endwhile

    return [s_idx, e_idx1, e_idx2]
endfunction

" highlight_diff()
" Highlight the characters between the start and end indexes in the specified
" line.
function! s:highlight_diff(lnum, s_idx, e_idx)
    let scol = a:s_idx
    let ecol = a:e_idx

    " We are going to highlight characters greater than s_idx and less
    " than e_idx (between s_idx + 1 and e_idx - 1). Highlighting
    " uses columns which start at 1 while string index starts at 0. So
    " increment e_idx by 2.
    let ecol += 2

    " If there is nothing to highlight, then highlight the last character
    if (scol + 1) == ecol
	let ecol += 1
    elseif scol == ecol
	let ecol += 2
    endif

    let hl_pat = '/\%'.a:lnum.'l\%>'.scol.'c.*\%<'.ecol.'c/'
    exe '2match GReplaceText ' . hl_pat
    redraw!
endfunction

" process_change_set()
" Merge the changes made by the user to the corresponding files/buffers
function! s:process_changeset(changeset, bang)
    let change_all = (a:bang == '!')

    " Merge the changes made by the user to the buffers
    for f in keys(a:changeset)
        let f_l = a:changeset[f]
        if !filereadable(f)
            continue
        endif

	" Don't use silent when editing the file as it hides the swap file
	" exists prompt. To the user, it looks like Vim is hanging.
        exe 'hide edit ' . f

	" If a swap file is present and the user decided not to edit the file,
	" then handle the condition here.
	if bufname('%') == ''
	    continue
	endif

        let change_buf_all = 0   " Accept all the changes in this buffer

        for lnum in keys(f_l)
            exe lnum

            let prev_line = getline(lnum)
            let new_line = f_l[lnum]

	    " Compute the diff between the old and new lines
	    let [s_idx, e_idx1, e_idx2] = s:diff_line(prev_line, new_line)

	    " Highlight the diff
	    call s:highlight_diff(lnum, s_idx, e_idx1)

            try
                let change_line = 0

                if !change_all && !change_buf_all
                    let new_text_frag = strpart(new_line, s_idx,
                                \ e_idx2 - s_idx + 1)

                    echo "Replace with '" . new_text_frag . "' (y/n/a/b/q)?"
                    let ans = 'x'
                    while ans !~? '[ynab]'
                        let ans = nr2char(getchar())
                        if ans ==? 'q' || ans == "\<Esc>"      " Quit
                            return
                        endif
                    endwhile
                    if ans ==? 'a'       " Accept all
                        let change_all = 1
                    endif
                    if ans ==? 'b'       " Accept changes in the current buffer
                        let change_buf_all = 1
                    endif
                    if ans ==? 'y'       " Yes
                        let change_line = 1
                    endif
                endif

                if change_all || change_buf_all || change_line
                    call setline(lnum, f_l[lnum])
                endif
            finally
                2match none
            endtry
        endfor
    endfor
endfunction

" gReplace()
" Get a list of lines changed in the replace buffer and merge the changes
" back into the files.
function! s:gReplace(bang)
    if empty(s:save_qf_list)
        return
    endif

    let changeset = s:get_changeset()
    if empty(changeset)
        " The replace buffer is not modified by the user
        call s:warn_msg('Error: No changes in the replace buffer')
        return
    endif

    " Merge the changes made by the user to the buffers
    call s:process_changeset(changeset, a:bang)
endfunction

" gRepl_Jump_To_File
" Jump to the file under the cursor and position the cursor on the
" line with the line number under the cursor
function! s:gRepl_Jump_To_File()
    let l = getline('.')

    if l !~ '[^:]\+:\d\+:'
	return
    endif

    let match_l = matchlist(l, '\([^:]\+\):\(\d\+\):\(.*\)')
    if len(match_l) == 0
	return
    endif

    let fname = match_l[1]
    let lnum = match_l[2]

    if !filereadable(fname)
	return
    endif

    let found_win = 0

    let wnum = bufwinnr(fname)
    if wnum != -1
	exe wnum . 'wincmd w'
	let found_win = 1
    else
	" locate a usable window
	for wnum in range(1, winnr('$'))
	    let bnr = winbufnr(wnum)
	    if getbufvar(bnr, '&buftype') == ''
		exe wnum . 'wincmd w'
		let found_win = 1
		break
	    endif
	endfor
    endif

    if found_win
	exe 'edit +' . lnum . ' ' . fname
    else
	exe 'below new +' . lnum . ' ' . fname
    endif
endfunction

" greplace#show_matches
" Display the search results in the replace buffer
function! greplace#show_matches(search_pat)
    let s:save_qf_list = {}

    let qf = getqflist()
    if empty(qf)
        call s:warn_msg('Error: Quickfix list is empty')
        return
    endif

    let new_qf = {}

    " Populate the buffer with the current quickfix list
    let lines = []
    for l in qf
        if l.valid && l.lnum > 0 && l.bufnr > 0
            let fname = fnamemodify(bufname(l.bufnr), ':.')
            let buf_text = fname . ':' . l.lnum . ':' . l.text
            let k = fname . ':' . l.lnum
            let new_qf[k] = {}
            let new_qf[k].fname = fnamemodify(bufname(l.bufnr), ':p')
            let new_qf[k].text = l.text
        else
            let buf_text = l.text
        endif

        call add(lines, buf_text)
    endfor

    if empty(lines)
        " No valid matching lines
        return
    endif

    let w = bufwinnr(s:gRepl_bufname)
    if w == -1
        " Create a new window
        silent! exe 'new ' . s:gRepl_bufname
    else
        exe w . 'wincmd w'

        " Discard the contents of the buffer
        %d _
    endif

    let first_line = 0
    if a:search_pat != ''
        call append(0, '# Search pattern: ' . a:search_pat)
        let first_line = 1
    endif
    call append(first_line, '# Modify the contents of this buffer and ' .
                \ 'then use the ":Greplace" command')
    call append(first_line + 1, '# to merge the changes.')
    call append(first_line + 2, lines)
    let start_lnum = first_line + 3

    if has('gui_running') || &t_Co > 2
        syntax match gReplaceComment /^#.*/
        syntax match gReplaceFileName
                    \ /^.\+\ze:\d\+:/ nextgroup=gReplaceSeparator
        syntax match gReplaceSeparator /:/ nextgroup=gReplaceLineNr
        syntax match gReplaceLineNr /\d\+/

        highlight default link gReplaceComment Comment
        highlight default link gReplaceFileName Title
        highlight default link gReplaceLineNr LineNr
    endif

    call cursor(start_lnum, 1)
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal nomodified

    " Map the Enter key to jump to file and line under cursor
    nnoremap <silent> <buffer> <CR> :call <SID>gRepl_Jump_To_File()<CR>
    nnoremap <silent> <buffer> <2-LeftMouse> :call <SID>gRepl_Jump_To_File()<CR>

    command! -buffer -nargs=0 -bang Greplace call s:gReplace("<bang>")

    let s:save_qf_list = new_qf
endfunction

" greplace#search
" Search for a pattern in a group of files using ':grep'
function! greplace#search(type, ...)
    let grep_opt  = ''
    let pattern   = ''
    let filenames = ''

    " Parse the arguments
    " grep command-line flags are specified using the "-flag" format
    " (on MS-Windows, the findstr program is used for 'grepprg' and
    "  the options start with '/')
    " the next argument is assumed to be the pattern
    " and the next arguments are assumed to be filenames or file patterns
    let argcnt = 1
    while argcnt <= a:0
        if &grepprg =~ 'findstr' && a:{argcnt} =~ '^/'
            let grep_opt = grep_opt . ' ' . a:{argcnt}
        elseif a:{argcnt} =~ '^-'
            let grep_opt = grep_opt . ' ' . a:{argcnt}
        elseif pattern == ''
            let pattern = a:{argcnt}
        else
            let filenames = filenames . ' ' . a:{argcnt}
        endif
        let argcnt += 1
    endwhile

    " If search pattern is not specified on command-line, ask for it
    if pattern == ''
        let pattern = input('Search pattern: ', expand('<cword>'))
        if pattern == ''
            return
        endif

	" Escape the special characters in the supplied pattern
	let pattern = shellescape(pattern)
    endif

    if a:type == 'grep'
        if filenames == ''
            let filenames = input('Search in files: ', '', 'file')
        endif
    elseif a:type == 'args'
        " Search in all the filenames in the argument list
        let arg_cnt = argc()

        if arg_cnt == 0
            call s:warn_msg('Error: Argument list is empty')
            return
        endif

        let filenames = ''
        for i in range(0, arg_cnt - 1)
            let filenames .= ' ' . argv(i)
        endfor
    else
        " Get a list of all the buffer names
        let filenames = ''
        for i in range(1, bufnr('$'))
            let bname = bufname(i)
            if bufexists(i) && buflisted(i) && filereadable(bname) &&
                        \ getbufvar(i, '&buftype') == ''
                let filenames .= ' ' . bufname(i)
            endif
        endfor
    endif

    if a:type != 'grep' && filenames == ''
        call s:warn_msg('Error: No valid file names')
        return
    endif

    " Use ! after grep, so that Vim doesn't automatically jump to the
    " first match
    let grep_cmd = 'grep! ' . grep_opt . ' ' . pattern . ' ' . filenames

    " Run the grep and get the matches
    " Don't use silent to suppress the command output, as it is useful
    " for the user to look at the command output in case of failure.
    exe grep_cmd

    call greplace#show_matches(pattern)
endfunction

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save
