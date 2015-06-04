#!/bin/bash

release=$1
codename=$2

if test "x$codename" = "x" -o "x$release" = "x" ; then
	echo expected arguments denoting debian release \& codename to get and prepare 21>&2
	exit 1
fi

projdir=/srv/obs/build/Debian:"$release"

#if test -d "$projdir" ; then
#	exit 0
#fi

cat $(dirname $0)/debian_template.prj | sed "s#%release%#${release}#g" | sed "s#%codename%#${codename}#g" > /tmp/debian${release}.prj
if osc meta prj -F /tmp/debian${release}.prj Debian:${release} ; then
	echo "Successfully created base for Debian ${codename}"
else
	exit 1
fi

cat $(dirname $0)/debian_template.prjconf | sed "s/#debianversion/"$( echo ${release} | sed -r 's#^([^.]+)[.](.+)$#\1\20#g')"/g" > /tmp/debian${release}.prjconf
if osc meta prjconf -F /tmp/debian${release}.prjconf Debian:${release} ; then
	echo "Successfully created configuration for Debian ${release}/${codename}"
else
	exit 1
fi

echo $codename > $projdir/codename
for repo in $(grep \<repository /tmp/debian${release}.prj | cut -d\" -f 2) ; do
	mkdir -p $projdir/$repo/x86_64/:full
	ln -s /mnt/pub_linux_cz/linux/debian $projdir/$repo/x86_64/:full

#stupid resolver does not accout for architecture in case of local access
#	repos=( $(echo $repo | cut -d_ -f2))
#	ln -s debian/pool/${repos[@]:(-1)}/ $projdir/$repo/x86_64/:full/pool
done
