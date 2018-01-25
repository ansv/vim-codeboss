" vim-codeboss - cscope helper for vim
"
" Copyright (C) 2018 Andrey Shvetsov
"
" SPDX-License-Identifier: MIT
"
" Install:
"
" If you use junegunn/vim-plug:
" Add to your .vimrc
" Plug 'ansv/vim-codeboss'
"
" Take a look at the plugin https://github.com/ansv/vim-supernext
" This helps to walk between the quickfix entries.
"
" Hint:
"
" Since this script uses the key mapping <C-g> that must print the current
" file name, you may remap <C-l> in your .vimrc to have lost functionality as
" following:
"
" nnoremap <silent> <C-l> <C-l><C-g>


if !has("cscope")
    echo expand('<sfile>:p') . " cannot start:"
    echo "vim is compiled without option '--enable-cscope'"
    finish
endif

if !executable('cscope')
    echo expand('<sfile>:p') . " cannot start:"
    echo "cscope is not installed"
    finish
endif

" use both cscope and ctag for 'ctrl-]', ':ta', and 'vim -t'
set cscopetag

" check cscope for definition of a symbol before checking ctags: set to 1
" if you want the reverse search order.
set csto=0

set cscopequickfix=s-,g-,d-,c-,t-,e-,f-,i-

let s:my_path = expand('<sfile>:p:h')
let s:updated = 1


" close and clear quickfix
function! s:hide_quickfix()
    execute "cclose"
    call setqflist([])
endfunction

nnoremap <silent> <C-g><C-h> :call <SID>hide_quickfix()<CR>
nnoremap <silent> <C-g>h     :call <SID>hide_quickfix()<CR>


function! s:scall(cmd, param)
    call system(s:my_path . "/codeboss.sh " . a:cmd . " \"" . a:param . "\"")
    return !v:shell_error
endfunction


function! s:add_object(name)
    if s:scall("add", a:name)
        let s:updated = 1
    endif
endfunction

" Add all files [R]eqursively to the cscope namefile .cboss.files
nnoremap <silent> <C-g><C-r> :call <SID>add_object(expand("%:h"))<CR>
nnoremap <silent> <C-g>r     :call <SID>add_object(expand("%:h"))<CR>

" [A]dd given file to the cscope namefile .cboss.files
nnoremap <silent> <C-g><C-a> :call <SID>add_object(expand("%"))<CR>
nnoremap <silent> <C-g>a     :call <SID>add_object(expand("%"))<CR>


function! s:reload()
    silent cscope kill -1
    call s:scall("rebuild", "")

    " add dynamic cscope database from the current directory
    if filereadable(".cboss.out")
        silent cs add .cboss.out
    endif

    " add default (static) cscope database from the current directory
    if filereadable("cscope.out")
        silent cs add cscope.out
    endif

    "redraw!
endfunction

function! s:cscope_find(cmd)
    if s:updated
        let s:updated = 0
        call s:reload()
    endif

    try
        execute "cscope find " . a:cmd
        return 1
    catch /^Vim\%((\a\+)\)\=:E259:/
    catch /^Vim\%((\a\+)\)\=:E567:/
    endtry

    return 0
endfunction


function! s:goto_def()
    call s:cscope_find("g " . expand("<cword>"))
    call setqflist([])
endfunction

" goto global [D]efinition
nnoremap <silent> <C-g><C-d> :call <SID>goto_def()<CR>
nnoremap <silent> <C-g>d     :call <SID>goto_def()<CR>
nnoremap <silent> g<C-d>     :call <SID>goto_def()<CR>


function! s:quickfix_list(cmd, id, sid)
    execute "normal mG"
    call setqflist([])
    if s:cscope_find(a:cmd . " " . a:id)
        execute "copen"
        call clearmatches()
        call matchadd("Search", a:sid)
        execute "wincmd p"
    endif
    execute "normal `G"
endfunction

function! s:find_token_refs()
    let id = expand("<cword>")
    call s:quickfix_list("s", id, '\<' . id . '\>')
endfunction

" find all refs to the token (Definition + Usages)
nnoremap <silent> <C-g><C-g> :call <SID>find_token_refs()<CR>
nnoremap <silent> <C-g>g     :call <SID>find_token_refs()<CR>


function! s:find_text()
    let str = expand("<cword>")
    call s:quickfix_list("t", str, str)
endfunction

" find all instances of the [T]ext
nnoremap <silent> <C-g><C-t> :call <SID>find_text()<CR>
nnoremap <silent> <C-g>t     :call <SID>find_text()<CR>


function! s:find_files()
    let str = input("find files with the name part: ")
    if str != ''
        call s:quickfix_list("f", str, str)
    else
        call s:quickfix_list("f", "/", "")
    endif
endfunction

" find [F]iles
nnoremap <silent> <C-g><C-f> :call <SID>find_files()<CR>
nnoremap <silent> <C-g>f     :call <SID>find_files()<CR>


function! s:on_write()
    if s:scall("is_tracked", expand("%"))
        let s:updated = 1
    endif
endfunction

au BufWritePost * call <SID>on_write()

" vim: set ts=4 sw=4 et:
