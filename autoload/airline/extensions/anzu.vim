scriptencoding utf-8


function! airline#extensions#anzu#init(ext)
	call airline#parts#define_function('anzu', 'anzu#search_status')
	call a:ext.add_statusline_func('airline#extensions#anzu#apply')
endfunction

function! airline#extensions#anzu#apply(...)
	let g:anzu_status_format='[%i/%l]'
	let g:anzu_enable_CursorMoved_AnzuUpdateSearchStatus=2
	call airline#extensions#append_to_section("y", " %{anzu#search_status()}")
endfunction
