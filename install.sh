#!/bin/sh

MYDIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$TERM" = cygwin ]; then
	symlink () {
		local linkname="$2"
		local linktarget="$1"

		if [ $# -gt 2 ]; then
			echo >&2 "only two argument form is accepted: ln <LINKTARGET> <LINKNAME>"
			exit 1
		fi

		local mklinkflags=""
		[ -d "$linktarget" ] && mklinkflags="/D"

		[ -e "$linkname" ] && {
			echo >&2 "link name \"$linkname\" is already a file, skipping"
			return
		}

		cmd /C mklink $mklinkflags "$(cygpath -w "$linkname")" "$(cygpath -w "$linktarget")"
	}

else
	symlink () { ln -svi "$@"; }
fi

#-- Symlink classic "~/.foorc" dotfiles first
( cd "$MYDIR"/HOME
	for name in *
	do
		dest=~/.$name

		#-- silently skip symlinks, probably we installed them already
		[ ! -L $dest ] || continue

		if [ -d $dest ]
		then
			echo "$dest is a plain directory; would not symlink"
			continue
		fi

		echo -ne "installing rc-style... \t"
		symlink "$PWD/$name" "$dest"
	done
)

#-- Symlink XDG-style "~/.config/foo" as well
STD_CFG=${XDG_CONFIG_HOME:-$HOME/.config}
( cd "$MYDIR"/XDG
	for name in *
	do
		dest="$STD_CFG"/$name

		#-- silently skip symlinks, probably we installed them already
		[ ! -L $dest ] || continue

		if test -d $dest
		then
			echo "Skipping pre-existing XDG dir: $dest"
			continue
		fi

		echo -ne "installing XDG subdir... \t"
		symlink "$PWD/$name" "$dest"
	done
)

# vim: sw=4 ts=4 noet
