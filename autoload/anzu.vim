scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:status_cache = ""

function! anzu#search_status()
	return substitute(s:status_cache, '<anzustatushighlight>.\{-}<\/anzustatushighlight>', "", "g")
endfunction

function! anzu#clear_search_status()
	let s:status_cache = ""
endfunction

function! anzu#echohl_search_status()
	if empty(s:status_cache)
		return
	endif
	let text = s:status_cache
	try
		let len = 0
		let max_len = &columns * (&cmdheight -1) + &columns / 2
		for word in split(text . "<anzustatushighlight>None<\/anzustatushighlight>", '<anzustatushighlight>.\{-}<\/anzustatushighlight>\zs')
			let output = matchstr(word, '\zs.*\ze<anzustatushighlight>.*<\/anzustatushighlight>')
			if max_len > len + len(output)
				echon output
				let len += len(output)
			else
				echon output[ : max_len - len -1 ]
				return
			endif
			execute "echohl" matchstr(word, '.*<anzustatushighlight>\zs.*\ze<\/anzustatushighlight>')
		endfor
	finally
		echohl None
	endtry
endfunction


" a <= b
function! s:pos_less_equal(a, b)
	return a:a[0] == a:b[0] ? a:a[1] <= a:b[1] : a:a[0] <= a:b[0]
endfunction


" function! s:search_less_pos(pos_list, pos)
" 	let index = 0
" 	for pos in a:pos_list
" 		if s:pos_less_equal(a:pos, pos)
" 			return index
" 		endif
" 		let index = index + 1
" 	endfor
" 	return -1
" endfunction


function! s:print_status(format, pattern, index, len, wrap)
	let result = a:format
	let result = substitute(result, '%#\(.\{-}\)#', '<anzustatushighlight>\1<\/anzustatushighlight>', "g")
	let result = substitute(result, '%i', a:index, "g")
	let result = substitute(result, '%l', a:len, "g")
	let result = substitute(result, '%w', a:wrap, "g")
	let result = substitute(result, '%p', a:pattern, "g")
	" Fix \<homu\> to view
	let result = substitute(result, '%/', substitute(histget("/", -1), '\\', '\\\\', "g"), "g")
	return result
endfunction


function! s:clamp_pos(pos, min, max)
	return s:pos_less_equal(a:min, a:pos) && s:pos_less_equal(a:pos, a:max)
endfunction


function! anzu#get_on_pattern_pos(pat)
	if a:pat == ""
		return getpos(".")
	endif
	let pos = getpos(".")
	let first = searchpos(a:pat, 'nWbc')
	let last  = searchpos(a:pat, 'nWeb')
	if s:pos_less_equal(last, first)
		let last  = searchpos(a:pat, 'nWec')
	endif
	if s:clamp_pos(pos[1:2], first, last)
		return [0, first[0], first[1], 0]
	endif
	return pos
endfunction


function! anzu#update(pattern, cursor_pos, ...)
	let pattern = a:pattern
	let cursor = a:cursor_pos
	if pattern == ""
		return
	endif

	let pos_all = s:searchpos(pattern)
	
	if empty(pos_all)
		let s:status_cache = s:print_status(g:anzu_no_match_word, pattern, "", "", "")
		return -1
	endif

	let index = index(pos_all, [cursor[1], cursor[2]])
	if index == -1
		return -1
	endif

	let wrap_mes = get(a:, 1, "")

	let pattern = substitute(pattern, '\\', '\\\\', 'g')
	let s:status_cache = s:print_status(g:anzu_status_format, pattern, index+1, len(pos_all), wrap_mes)
endfunction


function! anzu#clear_search_cache(...)
	let bufnr = get(a:, 1, bufnr("%"))
	call setbufvar(bufnr, "anzu_searchpos_cache", {})
endfunction


function! anzu#getpos(pattern, count)
	return get(s:searchpos(a:pattern), a:count, [])
endfunction


function! anzu#jump(pattern, count)
	let pos = anzu#getpos(a:pattern, a:count)
	if empty(pos)
		return
	endif
	call setpos(".", [0] + pos + [0])
endfunction


function! anzu#jump_key(key, count)
	if a:count
		call anzu#jump(@/, a:count - 1)
		AnzuUpdateSearchStatus
	else
		if !empty(a:key)
			try
				execute "normal" a:key
			catch
				echohl ErrorMsg | echo matchstr(v:exception, 'Vim(normal):\zs.*\ze') | echohl None
				call anzu#clear_search_status()
				return -1
			endtry
" 			execute "normal" a:key
		endif
	endif
endfunction


function! anzu#mapexpr_jump(...)
	let l:count  = get(a:, 1, "")
	let key = get(a:, 2, "")
	return ":\<C-u>if anzu#jump_key(\"" . key . "\", " . l:count . ") != -1 \<Bar> set hlsearch \<Bar> endif\<CR>"
endfunction


function! s:searchpos(pattern, ...)
	let bufnr = get(a:, 1, bufnr("%"))
	let uncache = get(a:, 2, 0)
	if uncache
		return s:searchpos_all(a:pattern)
	endif
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
	return searchpos
endfunction



function! s:searchpos_all(pattern)
	" winsave view correctly restores curswant
	let old_pos = winsaveview()
	let result = []
	try
		call setpos(".", [0, line("$"), strlen(getline("$")), 0])
		while 1
			silent! let pos = searchpos(a:pattern, "w")
			if pos == [0, 0] || index(result, pos) != -1
				break
			endif
			call add(result, pos)
			if len(result) >= g:anzu_search_limit
				break
			endif
		endwhile
	finally
		call winrestview(old_pos)
	endtry
	return result
endfunction

function! anzu#searchpos(...)
	return call("s:searchpos", a:000)
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
	let lines = map(deepcopy(s:searchpos(a:pattern)), "float2nr(v:val[0] * rate) + top")
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
