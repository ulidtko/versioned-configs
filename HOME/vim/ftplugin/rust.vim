" Using rust-lang/rust.vim
" Great for single-file foo.rs

let g:rust_fold=1

let g:syntastic_rust_checkers = ['rustc'] " rustc or cargo

"vmap <leader>f :RustFmtRange<CR>
nmap <leader>r :RustRun<CR>
nmap <leader>t :RustTest<CR>


