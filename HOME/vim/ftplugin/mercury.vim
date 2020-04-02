" Settings for https://github.com/khorser/vim-mercury

let mercury_highlight_full_comment = 1
let mercury_no_highlight_overlong = 1

" HACK: forcibly reload vim-mercury's syntax defs. Necessary because
" the options above must be set BEFORE loading syntax/mercury.vim; however,
" THIS file won't be sourced until vim-mercury's ftdetect script triggers.
" By which time, it's already too late to change the options.
unlet b:current_syntax
source $HOME/.vim/bundle/vim-mercury/syntax/mercury.vim
" It'd be easier to just shove the lines into main vimrc.
" We necessitate the hack by insisting on per-language settings separation.
