#!/bin/bash

latest=$(ls -1 /mnt/pub_linux_cz/linux/fedora/enchilada/linux/releases | sort -n | tail -n 1)

if test "x$latest" = "x" ; then
	echo chyba ve skriptu 21>&2
	exit 1
fi

projdir=/srv/obs/build/Fedora:"$latest"

if test -d "$projdir" ; then
	exit 0
fi

$(dirname $0)/get_fedora.sh ${latest}
