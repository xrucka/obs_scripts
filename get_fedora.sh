#!/bin/bash

release=$1

if test "x$latest" = "x" ; then
	echo expected argument denoting fedora version to get and prepare 21>&2
	exit 1
fi

projbase=/srv/obs/build
projdir="${projbase}/"Fedora:"$release"

#if test -d "$projdir" ; then
#	exit 0
#fi

sed "s#%release%#${release}#g" "$(dirname $0)/fedora_template.prj" > /tmp/fedora${release}.prj
sed "s#%release%#${release}#g" "$(dirname $0)/fedora_template_system.prj" | sed "s#%codename%#${codename}#g" > /tmp/fedora${release}_system.prj
sed "s#%release%#${release}#g" "$(dirname $0)/fedora_template_rpmfusion.prj" | sed "s#%codename%#${codename}#g" > /tmp/fedora${release}_rpmfusion.prj

subprojects_system=release,updates
subprojects_rpmfusion=free,nonfree
subprojects_rpmfusion_update=free,nonfree

if osc meta prj -F /tmp/fedora${release}.prj Fedora:${release} ; then
	echo "Successfully created base for Fedora ${release}"
else
	exit 1
fi

for repo in $(eval echo ""{$subprojects_system}) ; do
	repofile="/tmp/fedora${release}:${repo}.prj"
	sed -r "s#(:|\"| )%repository%(\"|<)#\\1${repo}\\2#g" /tmp/fedora${release}_system.prj > "${repofile}"
	( osc meta prj -F "${repofile}" \
		$(grep "<project name=" "${repofile}" | cut -d'"' -f 2) \
		&& echo "Successfully created $repo for Fedora ${release}" ) \
		|| echo "Error creating $repo for Fedora ${release}, manual import needed" >&2
done
for repo in $(eval echo ""{$subprojects_rpmfusion}) ; do
	repofile="/tmp/fedora${release}:${repo}.prj"
	sed -r "s#(:|\"| )%repository%(\"|<)#\\1${repo}\\2#g" /tmp/fedora${release}_rpmfusion.prj > "${repofile}"
	( osc meta prj -F "${repofile}" \
		$(grep "<project name=" "${repofile}" | cut -d'"' -f 2) \
		&& echo "Successfully created $repo for Fedora rpmfusion ${release}" ) \
		|| echo "Error creating $repo for Fedora rpmfusion ${release}, manual import needed" >&2
done
for repo in $(eval echo ""{$subprojects_rpmfusion_update}) ; do
	repofile="/tmp/fedora${release}:${repo}.prj"
	sed -r "s#(:|\"| )%repository%(\"|<)#\\1${repo}\\2#g" /tmp/fedora${release}_rpmfusion_update.prj > "${repofile}"
	( osc meta prj -F "${repofile}" \
		$(grep "<project name=" "${repofile}" | cut -d'"' -f 2) \
		&& echo "Successfully created $repo for Fedora rpmfusion update ${release}" ) \
		|| echo "Error creating $repo for Fedora rpmfusion update ${release}, manual import needed" >&2
done


cat $(dirname $0)/fedora_template.prjconf | sed "s/#fedoraversion/${release}/g" > /tmp/fedora${latest}.prjconf
if osc meta prjconf -F /tmp/fedora${release}.prjconf Fedora:${release} ; then
	echo "Successfully created configuration for Fedora ${release}"
else
	exit 1
fi

for subproject in "" $(eval echo ":{$subprojects_system}") $(eval echo ":{$subprojects_rpmfusion}") ; do
	for repo in $(grep \<repository /tmp/fedora${release}${subproject}.prj | cut -d\" -f 2) ; do
		mkdir -p ${projbase}/Fedora:${release}${subproject}/${repo}/x86_64/:full
	done
done

pushd $projdir:release/standard/x86_64/
mkdir -p :full
ln -s /mnt/pub_linux_cz/linux/fedora/enchilada/linux/releases/${release}/Everything/x86_64/os/Packages ./:full/
popd

pushd $projdir:updates/standard/x86_64/
mkdir -p :full
ln -s /mnt/pub_linux_cz/linux/fedora/enchilada/linux/updates/${release}/x86_64/ ./:full/Packages
popd

