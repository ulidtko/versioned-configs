setlocal shiftwidth=4 expandtab textwidth=99

let python_highlight_all=1

" pip3 install --user pylint mypy flake8

"let b:ale_linters = ['flake8', 'mypy', 'pylint']
let g:ale_fixers = ['reorder-python-imports', 'black']

" use # noqa in-source to silence it...
"let g:ale_linters_ignore = ['flake8']
" pip3 install --user flake8-2020 flake8-bugbear
