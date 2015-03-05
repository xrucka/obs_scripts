#!/bin/bash
cd /srv/obs/build 
for cuda in $(ls -1 | grep Cuda) ; do 
	osc meta prj $cuda > /tmp/$cuda.regenerate
	if ! pushd $cuda > /dev/null ; then
		echo "failed to iterate $cuda" 1>&2
		exit 1
	fi

	for repo in $(ls -1) ; do
		repolines=$(grep download /tmp/$cuda.regenerate | grep $repo | tr ' ' $'\n')
		arch=$(echo "$repolines" | grep arch= | cut -f2 -d\" )
		type=$(echo "$repolines" | grep mtype= | cut -f2 -d\" )
		baseurl=$(echo "$repolines" | grep baseurl= | cut -f2 -d\" )
		metafile=$(echo "$repolines" | grep metafile= | cut -f2 -d\" )

		if test "x$type" = "xrpmmd" -a -d "$repo/$arch" ; then
			mkdir -p $repo/$arch/:full
			pushd $repo/$arch/:full > /dev/null

			wget -r -np -nd -l 1 --no-host-directories -o /dev/null "$baseurl"/repodata/ -A "*"$metafile"*"

			if ! test "x$(ls -1 | fgrep  $metafile'.gz')" = x ; then
				for meta in *$metafile'.gz' ; do
					gunzip -d $meta
				done
			fi
			if ! test "x$(ls -1 | fgrep $metafile)" = x ; then
				for meta in *?$metafile ; do
					mv $meta $metafile
				done
			fi
			rm -f *?"$metafile"*
			popd > /dev/null
		fi
	done
	popd > /dev/null

done
