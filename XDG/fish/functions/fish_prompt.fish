# TODO:
#  • add git
#  • test fancy fish prompt symbol
function fish_prompt
  echo -s (set_color blue) (__kube_prompt) (set_color $fish_color_cwd) " " (prompt_pwd) (set_color normal) "> "
end
