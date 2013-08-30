scriptencoding utf-8


function! airline#extensions#anzu#init(ext)
	let g:airline_section_z = ' %{anzu#search_status()} ' . get(g:, "airline_section_z", "")
endfunction

