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


" a <= b
function! s:pos_less_equal(a, b)
	return a:a[0] == a:b[0] ? a:a[1] <= a:b[1] : a:a[0] <= a:b[0]
endfunction

function! s:search_less_pos(pos_list, pos)
	let index = 0
	for pos in a:pos_list
		if s:pos_less_equal(a:pos, pos)
			return index
		endif
		let index = index + 1
	endfor
	return -1
endfunction


function! anzu#update(pattern, cursor_pos)
	let pattern = a:pattern
	let cursor = a:cursor_pos
	if empty(pattern)
		return
	endif

	let pos_all = s:searchpos(pattern)
	
	if empty(pos_all)
		let s:status_cache = g:anzu_no_match_word
		return -1
	endif


" 	let index = s:search_less_pos(pos_all, [cursor[1], cursor[2]])
	let index = index(pos_all, [cursor[1], cursor[2]])
	if index == -1
		return -1
	endif

	let pattern = substitute(pattern, '\\', '\\\\', 'g')
	let s:status_cache = substitute(substitute(substitute(g:anzu_status_format, "%p", pattern, "g"), "%i", index+1, "g"), "%l", len(pos_all), "g")
endfunction


function! anzu#clear_search_cache(...)
	let bufnr = get(a:, 1, bufnr("%"))
	call setbufvar(bufnr, "anzu_searchpos_cache", {})
endfunction



function! s:searchpos(pattern, ...)
	let bufnr = get(a:, 1, bufnr("%"))
	let cache = getbufvar(bufnr, "anzu_searchpos_cache")
	if type(cache) == type("")
		unlet cache
		let cache = {}
	endif

	if has_key(cache, a:pattern)
		return deepcopy(cache[a:pattern])
	endif
	let searchpos = s:searchpos_all(a:pattern)
	let cache[a:pattern] = searchpos
	call setbufvar(bufnr, "anzu_searchpos_cache", cache)
	return deepcopy(searchpos)
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
			if len(result) >= g:anzu_search_limit
				break
			endif
		endwhile
	finally
		call setpos(".", old_pos)
	endtry
	return result
endfunction





function! anzu#clear_sign_matchline()
	call s:clear_sign_all()
endfunction


" 1はダミーに使用
let s:sign_id_dummy = 1
let s:sign_id_init = 2
let s:sign_id_count = s:sign_id_init
function! s:sign(line, bufnr)
	execute printf("sign place %d line=%d name=anzu_sign_matchline buffer=%d", s:sign_id_count, a:line, a:bufnr)
	let s:sign_id_count += 1
endfunction

function! s:clear_sign_id(id)
	execute printf("sign unplace %d", a:id)
endfunction

function! s:clear_sign_all()
	call map(range(s:sign_id_init, s:sign_id_count), "s:clear_sign_id(v:val)")
	let s:sign_id_count = s:sign_id_init
endfunction

function! s:is_signed()
	return s:sign_id_count != s:sign_id_init
endfunction


function! anzu#sign_matchline(pattern)
	highlight AnzuMatchline ctermbg=Yellow ctermfg=Yellow guibg=Yellow guifg=Yellow
	sign define anzu_sign_matchline text=>> texthl=AnzuMatchline

	highlight AnzuDummyhighlight ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
	sign define anzu_sign_dummy texthl=AnzuDummyhighlight

	call s:update_sign(a:pattern)
endfunction


let s:cache_top = 0
let s:cache_bottom = 0
function! anzu#smart_sign_matchline(pattern)
	let top = line("w0")
	let bottom = line("w$")
	if s:is_signed() && (top == s:cache_top && bottom == s:cache_bottom)
		return
	endif
	let s:cache_top = top
	let s:cache_bottom = bottom
	call anzu#sign_matchline(a:pattern)
endfunction


function! s:sign_lines(pattern)
	let top = line("w0")
	let bottom = line("w$")
	let height = bottom - top
	let rate = str2float(height) / line("$")
	let lines = map(s:searchpos(a:pattern), "float2nr(v:val[0] * rate) + top")
	return lines
endfunction


function! s:update_sign(pattern)
	let lines = s:sign_lines(a:pattern)
	if empty(lines)
		return
	endif

	let lines = s:uniq_sort(lines)

	" チラツキ防止用
	execute printf("sign place %d line=1 name=anzu_sign_dummy buffer=%d", s:sign_id_dummy, bufnr("%"))
	try
		AnzuClearSignMatchLine
		let bufnr = bufnr("%")
		call map(lines, "s:sign(v:val, bufnr)")
	finally
		execute printf("sign unplace %d", s:sign_id_dummy)
	endtry
endfunction

function! s:uniq_sort(list)
	let result = []
	for item in a:list
		if index(result, item) == -1
			call add(result, item)
		endif
	endfor
	return result
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
