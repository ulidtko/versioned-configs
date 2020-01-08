setlocal shiftwidth=4 expandtab textwidth=99

let python_highlight_all=1

" pip3 install --user pylint mypy flake8
let g:syntastic_python_checkers = ['mypy', 'python', 'pylint'] " flake8
"let g:syntastic_python_pylint_exec = 'pylint3'
let g:syntastic_python_python_exec = 'python3'
let g:syntastic_python_mypy_args = '--ignore-missing-imports'

