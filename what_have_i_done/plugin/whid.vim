if exists('g:loaded_whid') | finish | endif " prevent loading file twice

hi def link WhidHeader Number
hi def link WhidSubHeader Identifier

" common practice preventing custom coptions (sequence of single char flags) from
" interfering with plugin.
" Lack of this wouldn't hurt a simple plugin, but is good practice
let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" command to run plugin
" Requires plugin's lua module and calls its main method
command! Whid lua require'whid'.whid()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_whid = 1
