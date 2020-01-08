let g:hdevtools_options = '--nostack -g-Wall -g-fdefer-type-errors'
let g:necoghc_enable_detailed_browse = 1
let g:hs_highlight_types = 1
let g:hs_highlight_boolean = 1
let g:hs_highlight_more_types = 1

setlocal omnifunc=necoghc#omnifunc
source ~/.vim/bundle/ghcmod-vim/after/ftplugin/haskell/ghcmod.vim

noremap <buffer><localleader>i :HdevtoolsInfo<CR>
noremap <buffer><localleader>t :GhcModType<CR>
noremap <buffer><localleader>s :GhcModSplitFunCase<CR>
noremap <buffer><localleader>x :GhcModExpand<CR> " TH
