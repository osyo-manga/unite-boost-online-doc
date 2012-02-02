scriptencoding utf-8

function! unite#sources#boost_online_doc#define()
	return s:source
endfunction


let s:cache_libraries_url = {}

function! s:get_libraries_url(version)
	if has_key(s:cache_libraries_url, a:version) && !empty(s:cache_libraries_url[a:version])
		return s:cache_libraries_url[a:version]
	endif

	let s:cache_libraries_url[a:version] = []

	let boost_url = "http://www.boost.org/doc/libs/"
	let text = http#get("http://www.boost.org/doc/libs/".a:version."/").content
	let list = split(text, "\n")
	for line in list
		let url  = matchstr(line, '<dt><a href="/doc/libs/\zs.*\ze/">')
		if !empty(url)
			let name = matchstr(line, '<dt><a href="/doc/libs/'.url.'/">\zs.*\ze</a>')
			call add(s:cache_libraries_url[a:version],
				\ { "name" : name, "url" : boost_url.url."/" })
		endif
	endfor
	
	return s:cache_libraries_url[a:version]
endfunction


let s:source = {
\	"name" : "boost-online-doc",
\	"description" : "boost online document",
\	"default_action" : "openbrowser",
\	"action_table" : {
\		"openbrowser" : {
\			"description" : "OpenBrowser",
\			"is_selectable" : 1,
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


function! s:source.gather_candidates(args, context)
	let l:version = get(a:args, 0, "release")
	return map(copy(s:get_libraries_url(l:version)), '{
\		"word" : v:val.name,
\		"action__url" : v:val.url
\}')
endfunction


