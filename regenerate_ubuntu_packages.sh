#!/bin/bash
cd /srv/obs/build 

for ubuntu in $(ls -1 | grep Ubuntu) ; do 

	osc meta prj $ubuntu > /tmp/$ubuntu.regenerate
	if ! pushd $ubuntu > /dev/null ; then
		echo "failed to iterate $ubuntu" 1>&2
		exit 1
	fi

	codename=$(cat $ubuntu/codename)
	ubuntu_release=$(echo $ubuntu | grep -Eo '[0-9]+')

	for repo in $(ls -1) ; do
		repolines=$(grep download /tmp/$ubuntu.regenerate | grep $repo | tr ' ' $'\n')
		arch=$(echo "$repolines" | grep arch= | cut -f2 -d\" )
		type=$(echo "$repolines" | grep mtype= | cut -f2 -d\" )
		baseurl=$(echo "$repolines" | grep baseurl= | cut -f2 -d\" )
		metafile=$(echo "$repolines" | grep metafile= | cut -f2 -d\" )

		debarch=$(echo $arch | sed 's#x86_64#amd64#g')
		basepath=$(dirname "$(dirname "$baseurl"))"
		
		baseurl="$basepath/dists/$codename/$repo/binary-$debarch"


		mkdir -p "$repo/:full"
		if ! pushd $repo/:full > /dev/null ; then
			echo "Failed to enter :full in $repo" 1>&2
			exit 1
		fi
		rm $metafile
			
		wget -r -np -nd -l 1 --no-host-directories -o /dev/null "$baseurl/" -A "*"$metafile"*"

		if ! test "x$(ls -1 | fgrep  $metafile'.gz')" = x ; then
			for meta in *$metafile'.gz' ; do
				gunzip -d $meta
			done
		fi
		rm -f *?"$metafile"*
		rm -f *"$metafile"?*

		popd > /dev/null
	done
done
