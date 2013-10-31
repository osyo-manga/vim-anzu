scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#anzu#define()
	return s:source
endfunction


let s:source = {
\	"name" : "anzu",
\	'syntax' : 'uniteSource__anzu',
\	"hooks" : {},
\	"default_kind" : "jump_list",
\	"sorters" : "sorter_nothing"
\}


function! s:source.hooks.on_syntax(args, context)
	let pattern = get(a:args, 0, @/)
	execute
\		  'syntax match uniteSource__anzuSearch'
\		. ' /' . pattern . '/'
\		. ' contained containedin=uniteSource__anzu'
	highlight default link uniteSource__anzuSearch Search
endfunction


function! s:source.gather_candidates(args, context)
	let pattern = get(a:args, 0, @/)
	let bufnr   = unite#get_current_unite().prev_bufnr
	let list    = {}
	for item in anzu#searchpos(pattern, bufnr)
		let list[item[0]] = getbufline(bufnr, item[0])[0]
	endfor
	return map(items(list), '{
\		"word" : v:val[1],
\		"action__line": v:val[0],
\		"action__pattern": pattern,
\		"action__buffer_nr": bufnr,
\	}')
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
