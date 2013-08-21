scriptencoding utf-8

function! airline#autoload_extensions#anzu#init()
	let g:airline_section_z = ' %{anzu#search_status()} ' . g:airline_section_z
endfunction


function! airline#autoload_extensions#anzu#apply()
	" apply
endfunction

