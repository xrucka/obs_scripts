#!/bin/bash

release=$1
codename=$2

if test "x$codename" = "x" -o "x$release" = "x" ; then
	echo expected arguments denoting ubuntu release \& codename to get and prepare 21>&2
	exit 1
fi

projbase=/srv/obs/build
projdir="${projbase}/"Ubuntu:"$release"

#if test -d "$projdir" ; then
#	exit 0
#fi

cat $(dirname $0)/ubuntu_template.prj | sed "s#%release%#${release}#g" | sed "s#%codename%#${codename}#g" > /tmp/ubuntu${release}.prj
cat $(dirname $0)/ubuntu_template_repos.prj | sed "s#%release%#${release}#g" | sed "s#%codename%#${codename}#g" > /tmp/ubuntu${release}_repos.prj

subprojects=main,universe,multiverse,restricted

for repo in $(eval echo ""{$subprojects}) ; do
	cat /tmp/ubuntu${release}_repos.prj | sed -r "s#(:|\"| )main(\"|<)#\\1${repo}\\2#g" > /tmp/ubuntu${release}:${repo}.prj
done

for metafile in "" $(eval echo :{$subprojects}) ; do
	( osc meta prj -F /tmp/ubuntu"${release}${metafile}".prj \
		$(grep "<project name=" /tmp/ubuntu"${release}${metafile}".prj | cut -d'"' -f 2) \
		&& echo "Successfully created base for Ubuntu ${codename}" ) \
		|| echo "Error creating base for Ubuntu ${codename}, manual import needed" >&2
done

cat $(dirname $0)/ubuntu_template.prjconf | sed "s/#ubuntuversion/${release}/g" > /tmp/ubuntu${release}.prjconf
( osc meta prjconf -F /tmp/ubuntu${release}.prjconf Ubuntu:${release} \
	&& echo "Successfully created configuration for Ubuntu ${release}/${codename}" ) \
	|| echo "Error loading base configuration for Ubuntu ${codename}" >&2


for subproject in "" $(eval echo ":{$subprojects}") ; do
	for repo in $(grep \<repository /tmp/ubuntu${release}${subproject}.prj | cut -d\" -f 2) ; do
		mkdir -p ${projbase}/Ubuntu:${release}${subproject}/${repo}/x86_64/
	done
done

mkdir -p $projbase/Ubuntu:${release}
echo $codename > $projbase/Ubuntu:${release}/codename
