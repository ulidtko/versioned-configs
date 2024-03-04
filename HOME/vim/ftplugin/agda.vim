" https://github.com/isovector/cornelis

nnoremap <buffer> <leader>a :CornelisAuto<CR>
nnoremap <buffer> <leader>e :CornelisElaborate<CR>
nnoremap <buffer> <leader>v :CornelisGive<CR>
nnoremap <buffer> <leader>l :CornelisLoad<CR>
nnoremap <buffer> <leader>d :CornelisMakeCase<CR>
nnoremap <buffer> <leader>n :CornelisNormalize<CR>
nnoremap <buffer> <leader>r :CornelisRefine<CR>
nnoremap <buffer> <leader>n :CornelisSolve<CR>
nnoremap <buffer> <leader>, :CornelisTypeContext<CR>
nnoremap <buffer> <leader>. :CornelisTypeContextInfer<CR>
nnoremap <buffer> <leader>t :CornelisTypeInfer<CR>
nnoremap <buffer> <leader>w :CornelisWhyInScope<CR>
nnoremap <buffer> gd        :CornelisGoToDefinition<CR>
nnoremap <buffer> [/        :CornelisPrevGoal<CR>
nnoremap <buffer> ]/        :CornelisNextGoal<CR>
nnoremap <buffer> <C-A>     :CornelisInc<CR>
nnoremap <buffer> <C-X>     :CornelisDec<CR>

" TODO fix visual-mode input() in the plugin
"vmap <buffer> <leader>t :CornelisTypeInfer<CR>

au QuitPre *.agda :CornelisCloseInfoWindows

function! CornelisLoadWrapper()
  if exists(":CornelisLoad") ==# 2
    CornelisLoad
  endif
endfunction
au BufReadPre *.agda,*.lagda call CornelisLoadWrapper()
au BufWritePost *.agda,*.lagda call CornelisLoadWrapper()
