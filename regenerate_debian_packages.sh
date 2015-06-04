#!/bin/bash
cd /srv/obs/build

for debian in $(ls -1 | grep Debian) ; do
	codename=$(cat "${debian}/codename")
	debian_release=$(echo $debian | grep -Eo '[0-9.]+')

	for repo in $(find $debian -mindepth 2 -maxdepth 2 -type d) ; do
		if test -e $repo/:full/debian ; then
			if ! pushd $repo/:full > /dev/null ; then
				echo "Failed to enter :full in $repo" 1>&2
				exit 1
			fi
			repos=($(basename $(dirname $repo) | cut -d_ -f2))
			parentrepo="$(echo ${codename} ; [[ "x${repos[1]}" != "x" ]] && printf "%s%s" - "${repos[0]}")"

			cp debian/dists/${parentrepo}/${repos[@]:(-1)}/binary-amd64/Packages.gz ./
			gunzip -fd Packages.gz
			find -L pool -maxdepth 2 -type d | sed 's#[.]/##g' > ../:full.subdirs
			popd > /dev/null
		fi
	done
done
/usr/sbin/obs_admin --check-all-projects x86_64
