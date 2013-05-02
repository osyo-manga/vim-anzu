scriptencoding utf-8
if exists('g:loaded_anzu')
  finish
endif
let g:loaded_anzu = 1

let s:save_cpo = &cpo
set cpo&vim


let g:anzu_status_format = get(g:, "g:anzu_status_format", "%p(%i/%l)")


command! -bar AnzuClearSearchStatus call anzu#clear_search_status()

command! -bar AnzuUpdateSearchStatus call anzu#update(@/, getpos("."))


nnoremap <silent> <Plug>(anzu-echo-search-status) :<C-u>echo anzu#search_status()<CR>
nnoremap <silent> <Plug>(anzu-update-search-status) :<C-u>AnzuUpdateSearchStatus<CR>
nmap <silent> <Plug>(anzu-update-search-status-with-echo)
\	<Plug>(anzu-update-search-status)<Plug>(anzu-echo-search-status)


nnoremap <silent> <Plug>(anzu-star) *:<C-u>AnzuUpdateSearchStatus<CR>
nmap <silent> <Plug>(anzu-star-with-echo)
\	<Plug>(anzu-star)<Plug>(anzu-echo-search-status)

nnoremap <silent> <Plug>(anzu-sharp) #:<C-u>AnzuUpdateSearchStatus<CR>
nmap <silent> <Plug>(anzu-sharp-with-echo)
\	<Plug>(anzu-sharp)<Plug>(anzu-echo-search-status)

nnoremap <silent> <Plug>(anzu-n) n:<C-u>AnzuUpdateSearchStatus<CR>
nmap <silent> <Plug>(anzu-n-with-echo)
\	<Plug>(anzu-n)<Plug>(anzu-echo-search-status)

nnoremap <silent> <Plug>(anzu-N) N:<C-u>AnzuUpdateSearchStatus<CR>
nmap <silent> <Plug>(anzu-N-with-echo)
\	<Plug>(anzu-N)<Plug>(anzu-echo-search-status)


let &cpo = s:save_cpo
unlet s:save_cpo
