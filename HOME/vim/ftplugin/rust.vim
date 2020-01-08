let g:rust_fold=1

let g:syntastic_rust_checkers = ['rustc'] " rustc or cargo

vmap <leader>f :RustFmtRange<CR>
nmap <leader>r :RustRun<CR>
nnoremap <leader>t :RustTest<CR>


