#!/bin/bash
cd /srv/obs/build 
for cuda in $(ls -1 | grep 'Cuda_deb:') ; do 
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

		debarch=$(echo $arch | sed 's#x86_64#amd64#g')

		if test "x$type" = "xdebmd" -a -d "$repo/$arch" ; then
			mkdir -p $repo/$arch/:full
			pushd $repo/$arch/:full > /dev/null

			wget -r -np -nd -l 1 --no-host-directories -o /dev/null "$baseurl"/ -A "*"$metafile"*"

			rm -f $metafile

			if ! test "x$(ls -1 | fgrep  $metafile'.gz')" = x ; then
				for meta in *$metafile'.gz' ; do
					gunzip -d $meta
				done
			fi

			rm -f *?"$metafile"*
			rm -f *"$metafile"?*
			popd > /dev/null
		fi
	done
	popd > /dev/null

done
/usr/sbin/obs_admin --check-all-projects x86_64
