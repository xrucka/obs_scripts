#!/bin/bash
cd /srv/obs/build 

for fedora in $(ls -1 | grep Fedora) ; do 
	for repo in $(find $fedora -mindepth 2 -maxdepth 2 -type d) ; do 
		if test -e $repo/:full/Packages ; then
			if ! pushd $repo/:full > /dev/null ; then
				echo "Failed to enter :full in $repo" 1>&2
				exit 1
			fi
			( test -d $(realpath Packages)/../repodata && \
				cp $(realpath Packages)/../repodata/*-primary.xml.gz ./ || \
				cp Packages/repodata/*-primary.xml.gz ./ )
			gunzip -d *-primary.xml.gz
			mv *-primary.xml primary.xml
			find -L -maxdepth 2 -type d | sed 's#[.]/##g' > ../:full.subdirs
			popd > /dev/null
		fi
	done

	fedora_release=$(echo $fedora | grep -Eo '[0-9]+')

	for fusion in free nonfree ; do
		if test -d "$fedora/rpmfusion-$fusion" ; then
			mkdir -p "$fedora/rpmfusion-$fusion/x86_64/:full"
			if ! pushd $fedora/rpmfusion-$fusion/x86_64/:full > /dev/null ; then
				echo "Failed to enter :full in $fusion" 1>&2
				exit 1
			fi
			yes | wget --unlink --timestamping -O primary.xml.gz "http://download1.rpmfusion.org/$fusion/fedora/releases/${fedora_release}/Everything/x86_64/os/repodata/primary.xml.gz" \
				&& gunzip primary.xml.gz
			rm -rf primary.xml.gz
			popd > /dev/null
		fi
	done
done
