#!/bin/bash
cd /srv/obs/build

rel='[^:]+'

if test "x$1" != "x" ; then
	rel="$1"
fi

for fedora in $(ls -1 | grep -E '^Fedora:'"$rel"'$') ; do
	echo "processing project $fedora"
	for repo in $(find $fedora -mindepth 2 -maxdepth 2 -type d) ; do
	printf "\trepo $repo\n"
		if test -e $repo/:full/Packages ; then
			if ! pushd $repo/:full > /dev/null ; then
				echo "Failed to enter :full in $repo" 1>&2
				exit 1
			fi
			( test -d $(realpath Packages)/../repodata && \
				cp $(realpath Packages)/../repodata/*-primary.xml.gz ./ || \
				cp Packages/repodata/*-primary.xml.gz ./ )
			rm primary.xml
			gunzip -d *-primary.xml.gz
			mv *-primary.xml primary.xml
			find -L -maxdepth 2 -type d | sed 's#[.]/##g' > ../:full.subdirs
			popd > /dev/null
		fi
	done

	fedora_release=$(echo $fedora | grep -Eo '[0-9]+')

	for fusion in free nonfree ; do
		printf "\trepo rpmfusion-$fusion\n"
		if test -d "$fedora/rpmfusion-$fusion" ; then
			mkdir -p "$fedora/rpmfusion-$fusion/x86_64/:full"
			if ! pushd $fedora/rpmfusion-$fusion/x86_64/:full > /dev/null ; then
				echo "Failed to enter :full in $fusion" 1>&2
				exit 1
			fi
			rm primary.xml

			metafile=primary.xml
			baseurl="http://download1.rpmfusion.org/$fusion/fedora/releases/${fedora_release}/Everything/x86_64/os/"

			wget -r -np -nd -l 1 --no-host-directories -o /dev/null "$baseurl"/repodata/ -A "*"$metafile"*"

			if ! test "x$(ls -1 | fgrep  $metafile'.gz')" = x ; then
				for meta in *$metafile'.gz' ; do
					gunzip -d $meta
				done
			fi
			if ! test "x$(ls -1 grep .$metafile )" = x ; then
				for meta in *?$metafile ; do
					mv $meta $metafile
				done
			fi
			rm -f *?"$metafile"*

			popd > /dev/null
		fi
	done
done


# new repo format
for fedora in $(ls -1 | grep -E '^Fedora:'"$rel"':([^:]+)$') ; do
	echo "processing project $fedora"
	fedora_release=$(echo $fedora | cut -d: -f2 )

	for repo in $(find $fedora -mindepth 2 -maxdepth 2 -type d) ; do
	printf "\trepo $repo\n"
		if test -e $repo/:full/Packages ; then
			if ! pushd $repo/:full > /dev/null ; then
				echo "Failed to enter :full in $repo" 1>&2
				exit 1
			fi
			( test -d $(realpath Packages)/../repodata && \
				cp $(realpath Packages)/../repodata/*-primary.xml.gz ./ || \
				cp Packages/repodata/*-primary.xml.gz ./ )
			rm primary.xml
			gunzip -d *-primary.xml.gz
			mv *-primary.xml primary.xml
			find -L -maxdepth 2 -type d | sed 's#[.]/##g' > ../:full.subdirs
			popd > /dev/null

		elif test -e $repo/:full/ ; then
			if ! pushd $repo/:full > /dev/null ; then
				echo "Failed to enter :full in $repo" 1>&2
				exit 1
			fi

			osc meta prj $fedora > /tmp/$fedora.regenerate
			repolines=$(grep \<download /tmp/$fedora.regenerate | head -n 1 | tr ' ' $'\n')
			baseurl=$(echo "$repolines" | grep baseurl= | cut -f2 -d\" )
			metafile=primary.xml

			rm primary.xml
			rm /tmp/$fedora.regenerate
			wget -r -np -nd -l 1 --no-host-directories -o /dev/null "$baseurl"/repodata/ -A "*"$metafile"*"

			if ! test "x$(ls -1 | fgrep  $metafile'.gz')" = x ; then
				for meta in *$metafile'.gz' ; do
					gunzip -d $meta
				done
			fi
			if ! test "x$(ls -1 | grep .$metafile )" = x ; then
				for meta in *?$metafile ; do
					mv $meta $metafile
				done
			fi
			rm -f *?"$metafile"*

			popd > /dev/null
		fi
	done
done
