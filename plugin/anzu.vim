scriptencoding utf-8
if exists('g:loaded_anzu')
  finish
endif
let g:loaded_anzu = 1

let s:save_cpo = &cpo
set cpo&vim


function! s:push_pos(is_back)
	let s:start_pos = getpos(".")
	let s:is_back = a:is_back
endfunction


" a < b
function! s:pos_less(a, b)
	return a:a[1] == a:b[1] ? a:a[2] < a:b[2] : a:a[1] < a:b[1]
endfunction

function! s:update_search_status()
	if mode() !=# 'n'
		return
	endif

	let curs_hold = get(g:, 'anzu_enable_CursorHold_AnzuUpdateSearchStatus', 0)
	let curs_mov	= get(g:, 'anzu_enable_CursorMoved_AnzuUpdateSearchStatus', 0)

	let anzu_echo_output = (curs_hold == 1 || curs_mov == 1)

	try
		if curs_hold || curs_mov
			if anzu#update(@/,	anzu#get_on_pattern_pos(@/), s:wrapscan_mes()) != -1
		\	 && anzu_echo_output
				call feedkeys("\<Plug>(anzu-echohl_search_status)")
			endif
		endif
	catch /^Vim\%((\a\+)\)\=:E/
		echohl ErrorMsg | echo matchstr(v:exception, '^Vim(\a\+):\zs.*\ze$') | echohl None
		return
	endtry
endfunction

function! s:wrapscan_mes()
	if !exists("s:start_pos") || !exists("s:is_back")
		return ""
	endif
	let prev_pos = s:start_pos
	let pos = getpos(".")
	let result = ""
	if !empty(prev_pos) && s:pos_less(pos, prev_pos) && !s:is_back
		let result = g:anzu_bottomtop_word
	elseif !empty(prev_pos) && s:pos_less(prev_pos, pos) && s:is_back
		let result = g:anzu_topbottom_word
	endif
	unlet s:start_pos
	unlet s:is_back

	return result
endfunction


let g:anzu_status_format = get(g:, "anzu_status_format", '%p(%i/%l)')
let g:anzu_search_limit  = get(g:, "anzu_search_limit", 1000)
let g:anzu_no_match_word = get(g:, "anzu_no_match_word", "")

let g:anzu_airline_format = get(g:, "anzu_airline_format", "(%i/%l)")

let g:anzu_bottomtop_word = get(g:, "anzu_bottomtop_word", "search hit BOTTOM, continuing at TOP")
let g:anzu_topbottom_word = get(g:, "anzu_topbottom_word", "search hit TOP, continuing at BOTTOM")



command! -bar AnzuClearSearchStatus call anzu#clear_search_status()
command! -bar AnzuClearSearchCache call anzu#clear_search_cache()

command! -bar AnzuUpdateSearchStatus
\	call anzu#update(@/, anzu#get_on_pattern_pos(@/), s:wrapscan_mes())
command! -bar AnzuUpdateSearchStatusOutput
\	call anzu#update(@/, anzu#get_on_pattern_pos(@/), s:wrapscan_mes()) 
\|		call anzu#echohl_search_status()


nnoremap <silent> <Plug>(anzu-echo-search-status) :<C-u>call anzu#echohl_search_status()<CR>


nnoremap <silent> <Plug>(anzu-update-search-status) :<C-u>AnzuUpdateSearchStatus<CR>
nmap <silent> <Plug>(anzu-update-search-status-with-echo)
\	<Plug>(anzu-update-search-status)<Plug>(anzu-echo-search-status)

nnoremap <silent> <Plug>(anzu-clear-search-status) :<C-u>AnzuClearSearchStatus<CR>
nnoremap <silent> <Plug>(anzu-clear-search-cache) :<C-u>AnzuClearSearchCache<CR>


nnoremap <silent><expr> <Plug>(anzu-star)
\	":\<C-u>call \<SID>push_pos(0)\<CR>:normal! " . v:count1 . "*\<CR>:\<C-u>AnzuUpdateSearchStatus\<CR>"

nmap <silent> <Plug>(anzu-star-with-echo)
\	<Plug>(anzu-star)<Plug>(anzu-echo-search-status)

nnoremap <silent><expr> <Plug>(anzu-sharp)
\	":\<C-u>call \<SID>push_pos(1)\<CR>:normal! " . v:count1 . "#\<CR>:\<C-u>AnzuUpdateSearchStatus<CR>"

nmap <silent> <Plug>(anzu-sharp-with-echo)
\	<Plug>(anzu-sharp)<Plug>(anzu-echo-search-status)

nnoremap <silent><expr> <Plug>(anzu-n)
\	":\<C-u>call \<SID>push_pos(0)\<CR>:normal! " . v:count1 . "n\<CR>:\<C-u>AnzuUpdateSearchStatus\<CR>"

nmap <silent> <Plug>(anzu-n-with-echo)
\	<Plug>(anzu-n)<Plug>(anzu-echo-search-status)

nnoremap <silent><expr> <Plug>(anzu-N)
\	":\<C-u>call \<SID>push_pos(1)\<CR>:normal! " . v:count1 . "N\<CR>:\<C-u>AnzuUpdateSearchStatus\<CR>"


nmap <silent> <Plug>(anzu-N-with-echo)
\	<Plug>(anzu-N)<Plug>(anzu-echo-search-status)


nnoremap <silent><expr> <Plug>(anzu-jump)
\	anzu#mapexpr_jump(v:count, '')

nnoremap <silent><expr> <Plug>(anzu-jump-n)
\	anzu#mapexpr_jump(v:count, '\<Plug>(anzu-n)')

nnoremap <silent><expr> <Plug>(anzu-jump-N)
\	anzu#mapexpr_jump(v:count, '\<Plug>(anzu-N)')

nnoremap <silent><expr> <Plug>(anzu-jump-star)
\	":<C-u>normal! *N\<CR>" . anzu#mapexpr_jump(v:count, '\<Plug>(anzu-star)')

nnoremap <silent><expr> <Plug>(anzu-jump-sharp)
\	":<C-u>normal! *N\<CR>" . anzu#mapexpr_jump(v:count, '\<Plug>(anzu-sharp)')


command! -bar -nargs=* -bang
\	AnzuSignMatchLine
\	if <bang>0
\|		call anzu#sign_matchline(empty(<q-args>) ? @/ : <q-args>)
\|	else
\|		call anzu#smart_sign_matchline(empty(<q-args>) ? @/ : <q-args>)
\|	endif

command! -bar -nargs=*
\	AnzuClearSignMatchLine
\	call anzu#clear_sign_matchline()


nnoremap <silent> <Plug>(anzu-sign-matchline) :<C-u>AnzuSignMatchLine!<CR>
nnoremap <silent> <Plug>(anzu-clear-sign-matchline) :<C-u>AnzuClearSignMatchLine<CR>

nnoremap <silent> <Plug>(anzu-smart-sign-matchline) :<C-u>AnzuSignMatchLine<CR>

noremap <expr><silent> <Plug>(anzu-echohl_search_status)
\	(mode() =~ '[iR]' ? "\<C-o>" : "") . ":call anzu#echohl_search_status()\<CR>"


augroup anzu
	autocmd!
	autocmd CursorMoved * call <sid>update_search_status()

	if exists("##TextChanged")
		autocmd TextChanged * call anzu#clear_search_cache()
		autocmd TextChangedI * call anzu#clear_search_cache()
	else
		if exists("##InsertCharPre")
			autocmd InsertCharPre * call anzu#clear_search_cache()
		endif
		autocmd BufWritePost * call anzu#clear_search_cache()
	endif
augroup END


nnoremap <silent> <Plug>(anzu-mode-n) :<C-u>call anzu#mode#start(@/, "n", "", "")<CR>
nnoremap <silent> <Plug>(anzu-mode-N) :<C-u>call anzu#mode#start(@/, "N", "", "")<CR>
nnoremap <silent> <Plug>(anzu-mode) :<C-u>call anzu#mode#start(@/, "", "", "")<CR>


let &cpo = s:save_cpo
unlet s:save_cpo
