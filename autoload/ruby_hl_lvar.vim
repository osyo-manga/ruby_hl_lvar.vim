let s:self_path=expand("<sfile>")

execute 'rubyfile '.s:self_path.'.rb'

let s:hl_version = 0

function! ruby_hl_lvar#redraw() abort
	let bufnr = bufnr('%')

	" Remove current match if exists and its not for current buffer
	if exists('w:ruby_hl_lvar_hl_version')
		if exists('b:ruby_hl_lvar_hl_version') && w:ruby_hl_lvar_hl_version == b:ruby_hl_lvar_hl_version
			return
		else
			call s:try_matchdelete(w:ruby_hl_lvar_match_id)
			unlet w:ruby_hl_lvar_hl_version
		endif
	endif

	" Set match if exists
	if get(b:, 'ruby_hl_lvar_enabled', 1) && exists('b:ruby_hl_lvar_match_pattern')
		let w:ruby_hl_lvar_match_id = matchadd(g:ruby_hl_lvar_hl_group, b:ruby_hl_lvar_match_pattern)
		let w:ruby_hl_lvar_hl_version = b:ruby_hl_lvar_hl_version
	endif
endfunction

" return: [[var_name, row, col_start, col_end]...]
function! ruby_hl_lvar#extract_lvars(buffer) abort
  let bufnr = bufnr(a:buffer)
  if exists('s:ret')
    unlet s:ret
  endif
  let t = reltime()
  execute 'ruby RubyHlLvar::Vim.extract_lvars_from '.bufnr
  let b:ruby_hl_lvar_time = str2float(reltimestr(reltime(t)))
  let ret = s:ret
  unlet s:ret
  return ret
endfunction

function! ruby_hl_lvar#disable(force) abort
	if !a:force && exists('b:ruby_hl_lvar_enabled') && !b:ruby_hl_lvar_enabled
		return
	endif
	let bufnr = bufnr('%')
	if a:force
		let b:ruby_hl_lvar_enabled = 0
	endif
	call ruby_hl_lvar#redraw()
endfunction

function! s:try_matchdelete(id)
	if a:id < 0
		return
	endif
	try
		call matchdelete(a:id)
	catch /E803:/
	endtry
endfunction

function! ruby_hl_lvar#enable(force) abort
	if !a:force && exists('b:ruby_hl_lvar_enabled') && !b:ruby_hl_lvar_enabled
		return
	endif
	let bufnr = bufnr('%')
	call ruby_hl_lvar#disable(a:force)
	if !exists('b:ruby_hl_lvar_match_pattern')
		call ruby_hl_lvar#update_match_pattern('%')
	endif
	if a:force
		let b:ruby_hl_lvar_enabled = 1
	endif

	call ruby_hl_lvar#redraw()
endfunction

function! ruby_hl_lvar#refresh(force) abort
	if !a:force && exists('b:ruby_hl_lvar_enabled') && !b:ruby_hl_lvar_enabled
		return
	endif
	if exists('b:ruby_hl_lvar_match_pattern')
		unlet b:ruby_hl_lvar_match_pattern
	endif
	call ruby_hl_lvar#enable(a:force)
endfunction

function! ruby_hl_lvar#update_match_pattern(buffer) abort
	let bufnr = bufnr(a:buffer)
	let matches = map(ruby_hl_lvar#extract_lvars(a:buffer), '
		\ ''\%''.v:val[1].''l''.''\%''.v:val[2].''c''.repeat(''.'', strchars(v:val[0]))
		\ ')
	let b:ruby_hl_lvar_match_pattern = join(matches, '\|')
	let s:hl_version += 1
	let b:ruby_hl_lvar_hl_version = s:hl_version
endfunction

