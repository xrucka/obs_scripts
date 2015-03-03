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

cat $(dirname $0)/fedora_template.prj | sed "s#%release%#${latest}#g" > /tmp/fedora${latest}.prj
if osc meta prj -F /tmp/fedora${latest}.prj Fedora:${latest} ; then
	echo "Successfully created base for Fedora ${latest}"
else 
	exit 1
fi

cat $(dirname $0)/fedora_template.prjconf | sed "s/#fedoraversion/${latest}/g" > /tmp/fedora${latest}.prjconf
if osc meta prjconf -F /tmp/fedora${latest}.prjconf Fedora:${latest} ; then
	echo "Successfully created configuration for Fedora ${latest}"
else 
	exit 1
fi

pushd $projdir/standard/x86_64/
mkdir -p :full
ln -s /mnt/pub_linux_cz/linux/fedora/enchilada/linux/releases/${latest}/Everything/x86_64/os/Packages ./:full/
