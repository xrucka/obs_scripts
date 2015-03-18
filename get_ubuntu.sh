#!/bin/bash

release=$1
codename=$2

if test "x$codename" = "x" -o "x$release" = "x" ; then
	echo expected arguments denoting ubuntu release \& codename to get and prepare 21>&2
	exit 1
fi

projdir=/srv/obs/build/Ubuntu:"$release"

if test -d "$projdir" ; then
	exit 0
fi

cat $(dirname $0)/ubuntu_template.prj | sed "s#%release%#${release}#g" | sed "s#%codename%#${codename}#g" > /tmp/ubuntu${release}.prj
if osc meta prj -F /tmp/ubuntu${release}.prj Ubuntu:${release} ; then
	echo "Successfully created base for Ubuntu ${codename}"
else 
	exit 1
fi

cat $(dirname $0)/ubuntu_template.prjconf | sed "s/#ubuntuversion/${release}/g" > /tmp/ubuntu${release}.prjconf
if osc meta prjconf -F /tmp/ubuntu${release}.prjconf Ubuntu:${release} ; then
	echo "Successfully created configuration for Ubuntu ${release}/${codename}"
else 
	exit 1
fi

for repo in $(grep \<repository /tmp/ubuntu${release}.prj | cut -d\" -f 2) ; do
	mkdir -p $projdir/$repo/x86_64/
done

echo $codename > $projdir/codename
