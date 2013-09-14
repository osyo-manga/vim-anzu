scriptencoding utf-8


function! airline#extensions#anzu#init(ext)
	call a:ext.add_statusline_func('airline#extensions#anzu#apply')
endfunction

function! airline#extensions#anzu#apply(builder, ...)
	let w:airline_section_z = ' %{anzu#search_status()} ' . get(w:, "airline_section_z", "") . get(g:, "airline_section_z", "")
endfunction

