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

#-- Symlink classic "~/.foorc" dotfiles first
( cd "$MYDIR"/HOME || exit
	for name in *
	do
		dest=~/.$name

		#-- silently skip symlinks, probably we installed them already
		[ ! -L "$dest" ] || continue

		if [ -d "$dest" ]
		then
			echo "$dest is a plain directory; would not symlink"
			continue
		fi

		printf "installing rc-style... \t"
		symlink "$PWD/$name" "$dest"
	done
)

#-- Symlink XDG-style "~/.config/foo" as well
STD_CFG=${XDG_CONFIG_HOME:-$HOME/.config}
( cd "$MYDIR"/XDG || exit
	for name in *
	do
		dest="$STD_CFG"/$name

		#-- silently skip symlinks, probably we installed them already
		[ ! -L "$dest" ] || continue

		if test -d "$dest"
		then
			echo "Skipping pre-existing XDG dir: $dest"
			continue
		fi

		printf "installing XDG subdir... \t"
		symlink "$PWD/$name" "$dest"
	done
)

# vim: sw=4 ts=4 noet
