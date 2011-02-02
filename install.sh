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
		if [ -f "$name" ]
		then
			echo -n "installing $name... "
			ln -svi "$PWD/$name" ~/.$name
		fi
	done
)
