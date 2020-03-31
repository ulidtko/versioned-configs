setlocal shiftwidth=4 expandtab textwidth=99

let python_highlight_all=1

" pip3 install --user pylint mypy flake8

"let b:ale_linters = ['flake8', 'mypy', 'pylint']
let g:ale_fixers = ['reorder-python-imports', 'black']
