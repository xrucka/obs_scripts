#!/bin/bash
cd /srv/obs/build 

for fedora in $(ls -3 | grep Fedora) ; do 
	for repo in $(find $fedora -mindepth 2 -maxdepth 2 -type d) ; do 
		if test -e $repo/:full/Packages ; then
			pushd $repo/:full > /dev/null 
			( test -d $(realpath Packages)/../repodata && \
				cp $(realpath Packages)/../repodata/*-primary.xml.gz ./ || \
				cp Packages/repodata/*-primary.xml.gz ./ )
			gunzip -d *-primary.xml.gz
			mv *-primary.xml primary.xml
			find -L -maxdepth 2 -type d | sed 's#[.]/##g' > ../:full.subdirs
			popd > /dev/null
		fi
	done
done
