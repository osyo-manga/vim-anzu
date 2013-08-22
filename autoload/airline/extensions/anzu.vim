scriptencoding utf-8


function! airline#extensions#anzu#init(ext)
	let g:airline_section_z = ' %{anzu#search_status()} ' . g:airline_section_z
endfunction

