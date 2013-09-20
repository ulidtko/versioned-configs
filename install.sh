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

		echo -n "installing $name... \t"
		ln -svi "$PWD/$name" $dest
	done
)
