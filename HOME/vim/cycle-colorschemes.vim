" From https://www.reddit.com/r/vim/comments/w4iv6b/is_there_a_quick_way_to_cycle_through_vim/
" To use, :source it

vim9script

var schemes = globpath(&rtp, 'colors/*.vim')
      ->split("\n")
      ->map((_, f) => fnamemodify(f, ':t:r'))

def KeyHandler(id: number, key: string): bool
  var menuline = line('.', id)
  if key == "\<Space>" || key == "\<Enter>" || key == 'l'
    execute 'colo' schemes[menuline - 1]
  elseif key == 'j'
    win_execute(id, 'normal! j')
  elseif key == 'k'
    win_execute(id, 'normal! k')
  elseif key == "\<Esc>" || key == 'x' || key == 'q'
    popup_close(id)
  endif
  return true
enddef

popup_create(schemes, {
  maxheight: 20,
  minwidth: 20,
  cursorline: true,
  border: [0, 0, 0, 0],
  padding: [1, 2, 1, 2],
  filter: KeyHandler,
})
