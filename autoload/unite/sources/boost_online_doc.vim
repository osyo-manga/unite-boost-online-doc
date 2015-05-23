scriptencoding utf-8

function! unite#sources#boost_online_doc#define()
	return s:source
endfunction

let s:V = vital#of("boost_online_doc")
let s:HTTP = s:V.import("Web.HTTP")

function! s:http_get(...)
	return call(s:HTTP.get, a:000, s:HTTP)
endfunction

let s:cache_libraries_url = {}

function! s:get_libraries_url(version)
	if has_key(s:cache_libraries_url, a:version) && !empty(s:cache_libraries_url[a:version])
		return s:cache_libraries_url[a:version]
	endif

	let s:cache_libraries_url[a:version] = []
	
	if a:version == "trunk"
		let boost_url = "http://svn.boost.org/svn/boost/trunk/libs/"
		let text = s:http_get("http://svn.boost.org/svn/boost/trunk/libs/libraries.htm").content
		let list = split(matchstr(text, '<ul>\zs.*\ze<\/ul>'), "\n")
		
		for line in list
			let url  = matchstr(line, '<li><a href="\zs[^"]*\ze">')
			if !empty(url)
				let name = matchstr(line, '<li><a href="'.url.'">\zs[^"]*\ze</a>')
				call add(s:cache_libraries_url[a:version],
						\ { "name" : name, "url" : boost_url.url })
				endif
		endfor
	else
		let boost_url = "http://www.boost.org/doc/libs/"
		let text = s:http_get("http://www.boost.org/doc/libs/".a:version."/").content
		let list = split(text, "\n")
		for line in list
			let url  = matchstr(line, '<dt><a href="/doc/libs/\zs.*\ze/">')
			if !empty(url)
				let name = matchstr(line, '<dt><a href="/doc/libs/'.url.'/">\zs.*\ze</a>')
				call add(s:cache_libraries_url[a:version],
					\ { "name" : name, "url" : boost_url.url."/" })
			endif
		endfor
	endif
	return s:cache_libraries_url[a:version]
endfunction


let s:source = {
\	"name" : "boost-online-doc",
\	"description" : "boost online document",
\	"default_action" : "start",
\	"action_table" : {
\		"openbrowser" : {
\			"description" : "OpenBrowser",
\			"is_selectable" : 1,
\		},
\		"ref_lynx" : {
\			"description" : "Ref lynx {url}",
\			"is_selectable" : 0,
\		},
\		"ref_lynx_tabnew" : {
\			"description" : "tabnew Ref lynx {url}",
\			"is_selectable" : 0,
\		},
\	},
\}

function! s:source.action_table.openbrowser.func(candidates)
	for candidate in a:candidates
		if has_key(candidate, "action__url")
			call openbrowser#open(candidate.action__url)
		endif
	endfor
endfunction

function! s:open_ref_lynx(url)
	if !exists("g:ref_lynx_cmd")
		echoerr "Not found ref-lynx"
		return
	endif

	if !exists("g:ref_lynx_cmd")
		echoerr "Not found ref.vim"
		return
	endif
	call ref#open("lynx", a:url)
endfunction

function! s:source.action_table.ref_lynx.func(candidate)
	call s:open_ref_lynx(a:candidate.action__url)
endfunction

function! s:source.action_table.ref_lynx_tabnew.func(candidate)
	let old = get(g:, "ref_open", "")
	let g:ref_open="tabnew"
	call s:open_ref_lynx(a:candidate.action__url)
	let g:ref_open = old
endfunction


function! s:source.gather_candidates(args, context)
	let l:version = get(a:args, 0, "release")
	return map(copy(s:get_libraries_url(l:version)), '{
\		"word" : v:val.name,
\		"action__url" : v:val.url,
\		"action__path" : v:val.url,
\		"kind" : "uri"
\}')
endfunction



if expand("%:p") == expand("<sfile>:p")
	call unite#define_source(s:source)
endif


