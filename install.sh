#!/bin/sh

MYDIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$TERM" = cygwin ]; then
	symlink () {
		symlink_name="$2"
		symlink_target="$1"

		if [ $# -gt 2 ]; then
			echo >&2 "only two argument form is accepted: ln <LINKTARGET> <LINKNAME>"
			exit 1
		fi

		symlink_flags=""
		[ -d "$symlink_target" ] && symlink_flags="/D"

		[ -e "$symlink_name" ] && {
			echo >&2 "link name \"$symlink_name\" is already a file, skipping"
			return
		}

		cmd /C mklink \
			"$symlink_flags" \
			"$(cygpath -w "$symlink_name")" \
			"$(cygpath -w "$symlink_target")"
	}

else
	symlink () { ln -svi "$@"; }
fi

install_link() {
	message=$1
	path=$2
	dest=$3

	#-- silently skip symlinks, probably we installed them already
	[ ! -L "$dest" ] || return

	if test -d "$dest"; then
		echo "$dest is a plain directory; would not symlink"
		return
	fi

	printf "symlinking %s \t" "$message"
	symlink "$path" "$dest"
}

#-- Symlink classic "~/.foorc" dotfiles first
( cd "$MYDIR"/HOME || exit
	for name in *; do
		install_link "rc-style" "$PWD/$name" "$HOME/.$name"
	done
)

#-- Symlink XDG-style "~/.config/foo" as well
( cd "$MYDIR"/XDG || exit
	STD_CFG=${XDG_CONFIG_HOME:-$HOME/.config}

	mkdir -p "$STD_CFG/git"
	install_link "XDG-style" "$PWD/git/config" "$STD_CFG/git/config"
	install_link "XDG-style" "$PWD/git/ignore" "$STD_CFG/git/ignore"

	mkdir -p "$STD_CFG/fish"
	install_link "XDG-style" "$PWD/fish/config.fish" "$STD_CFG/fish/config.fish"
)

# vim: sw=4 ts=4 noet
