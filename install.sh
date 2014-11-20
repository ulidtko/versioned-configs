#!/bin/sh

MYDIR="$(cd "$(dirname "$0")" && pwd)"

#-- TODO: subfolders are ignored
#install_recurse () {
#	for name in *; do
#		if [ -d "$name" ]; then
#			select yn in "Yes" "No"; do
#				case $yn in
#					Yes ) break ;;
#					No ) break ;;
#				esac
#			done
#		fi
#	done
#}

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

		echo -ne "installing $name... \t"
		symlink "$PWD/$name" "$dest"
	done
)
