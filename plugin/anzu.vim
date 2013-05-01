scriptencoding utf-8
if exists('g:loaded_anzu')
  finish
endif
let g:loaded_anzu = 1

let s:save_cpo = &cpo
set cpo&vim


let g:anzu_status_format = get(g:, "g:anzu_status_format", "%p(%i/%l)")


command! AnzuClearSearchStatus call anzu#clear_search_status()


nnoremap <silent> <SID>(anzu-echo-search-status) :<C-u>echo anzu#search_status()<CR>
nnoremap <silent> <Plug>(anzu-update-search-status) :<C-u>call anzu#update(@/, getpos("."))<CR>
nmap <silent> <Plug>(anzu-update-search-status-with-echo)
\	<Plug>(anzu-update-search-status)<SID>(anzu-echo-search-status)


nnoremap <silent> <Plug>(anzu-star) *:<C-u>call anzu#update(@/, getpos("."))<CR>
nmap <silent> <Plug>(anzu-star-with-echo)
\	<Plug>(anzu-star)<SID>(anzu-echo-search-status)

nnoremap <silent> <Plug>(anzu-sharp) #:<C-u>call anzu#update(@/, getpos("."))<CR>
nmap <silent> <Plug>(anzu-sharp-with-echo)
\	<Plug>(anzu-sharp)<SID>(anzu-echo-search-status)

nnoremap <silent> <Plug>(anzu-n) n:<C-u>call anzu#update(@/, getpos("."))<CR>
nmap <silent> <Plug>(anzu-n-with-echo)
\	<Plug>(anzu-n)<SID>(anzu-echo-search-status)

nnoremap <silent> <Plug>(anzu-N) N:<C-u>call anzu#update(@/, getpos("."))<CR>
nmap <silent> <Plug>(anzu-N-with-echo)
\	<Plug>(anzu-N)<SID>(anzu-echo-search-status)


let &cpo = s:save_cpo
unlet s:save_cpo
