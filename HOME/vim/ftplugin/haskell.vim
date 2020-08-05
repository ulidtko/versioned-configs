let g:syntastic_haskell_hdevtools_args = '--nostack -g-Wall -g-fdefer-type-errors'

let g:hs_highlight_types = 1
let g:hs_highlight_boolean = 1
let g:hs_highlight_more_types = 1

" let g:necoghc_enable_detailed_browse = 1
" setlocal omnifunc=necoghc#omnifunc

noremap <buffer><localleader>i :HdevtoolsInfo<CR>
noremap <buffer><localleader>t :HdevtoolsType<CR>

" raichoo/haskell-vim highlighting settings
let g:haskell_enable_quantification = 1   " to enable highlighting of `forall`
let g:haskell_enable_recursivedo = 1      " to enable highlighting of `mdo` and `rec`
let g:haskell_enable_arrowsyntax = 0      " to enable highlighting of `proc`
let g:haskell_enable_pattern_synonyms = 1 " to enable highlighting of `pattern`
let g:haskell_enable_typeroles = 1        " to enable highlighting of type roles
let g:haskell_enable_static_pointers = 0  " to enable highlighting of `static`
let g:haskell_backpack = 0                " to enable highlighting of backpack keywords

" ALE
let b:ale_linters = ['hie', 'cabal_ghc', 'hlint']
let b:ale_fixers = ['stylish-haskell']

" LanguageClient-neovim
let g:LanguageClient_serverCommands = { 'haskell': ['haskell-language-server', '--lsp'] }
let g:LanguageClient_rootMarkers = ['*.cabal', 'stack.yaml']

nnoremap <F5> :call LanguageClient_contextMenu()<CR>
map <Leader>k :call LanguageClient#textDocument_hover()<CR>
map <Leader>g :call LanguageClient#textDocument_definition()<CR>
map <Leader>r :call LanguageClient#textDocument_rename()<CR>
map <Leader>f :call LanguageClient#textDocument_formatting()<CR>
map <Leader>b :call LanguageClient#textDocument_references()<CR>
map <Leader>a :call LanguageClient#textDocument_codeAction()<CR>
map <Leader>s :call LanguageClient#textDocument_documentSymbol()<CR>


map <Leader>r :let g:LanguageClient_trace = "messages"<CR>
            \ :let g:LanguageClient_windowLogMessageLevel = "Log"<CR>
            \ :LanguageClientStop<CR>:LanguageClientStart<CR>
