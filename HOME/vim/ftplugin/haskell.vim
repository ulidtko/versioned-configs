let g:syntastic_haskell_hdevtools_args = '--nostack -g-Wall -g-fdefer-type-errors'
let g:hs_highlight_types = 1
let g:hs_highlight_boolean = 1
let g:hs_highlight_more_types = 1

" let g:necoghc_enable_detailed_browse = 1
" setlocal omnifunc=necoghc#omnifunc

noremap <buffer><localleader>i :HdevtoolsInfo<CR>
noremap <buffer><localleader>t :HdevtoolsType<CR>
