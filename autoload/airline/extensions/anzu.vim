scriptencoding utf-8

function! airline#extensions#anzu#init(ext)
	call a:ext.add_statusline_funcref(function('airline#extensions#anzu#apply'))
endfunction

function! airline#extensions#anzu#apply(...)
	let w:airline_section_z = get(w:, "airline_section_z", "")
	let w:airline_section_z = ' %{anzu#search_status()} ' . w:airline_section_z . g:airline_section_z
endfunction

