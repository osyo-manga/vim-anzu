scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:status_cache = ""

function! anzu#search_status()
	return s:status_cache
endfunction

function! anzu#clear_search_status()
	let s:status_cache = ""
endfunction


function! anzu#update(pattern, cursor_pos)
	let pattern = a:pattern
	let cursor = a:cursor_pos
	if empty(pattern)
		return
	endif
	let pos_all = s:searchpos_all(pattern)
	if empty(pos_all)
		let s:status_cache = "nothing"
		return
	endif

	let cursor = getpos(".")
	let index = index(pos_all, [cursor[1], cursor[2]])
	if index == -1
		return
	endif

	let s:status_cache = substitute(substitute(substitute(g:anzu_status_format, "%p", pattern, "g"), "%i", index+1, "g"), "%l", len(pos_all), "g")
endfunction


function! s:searchpos_all(pattern)
	let old_pos =getpos(".")
	let result = []
	try
		call setpos(".", [0, 0, 0, 0])
		while 1
			let pos = searchpos(a:pattern, "")
			if pos == [0, 0] || index(result, pos) != -1
				break
			endif
			call add(result, pos)
		endwhile
	finally
		call setpos(".", old_pos)
	endtry
	return result
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
