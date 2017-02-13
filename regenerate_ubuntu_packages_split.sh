#!/bin/bash
cd /srv/obs/build

for ubuntu in $(ls -1 | grep Ubuntu | grep -E '^Ubuntu:[^:]+:.+$') ; do
	echo $ubuntu
	osc meta prj $ubuntu > /tmp/$ubuntu.regenerate
	pwd
	if ! pushd $ubuntu > /dev/null ; then
		echo "failed to iterate $ubuntu" 1>&2
		exit 1
	fi
	codename=$(cat "/srv/obs/build/$(echo $ubuntu | grep -Eo '^Ubuntu:[^:]+')/codename")
	ubuntu_release=$(echo $ubuntu | grep -Eo '[0-9.]+')
	subproject=$(echo ${ubuntu} | cut -d: -f3)
	repo=standard

	repolines=$(grep \<download /tmp/$ubuntu.regenerate | head -n 1 | tr ' ' $'\n')
	arch=$(echo "$repolines" | grep arch= | cut -f2 -d\" )
	type=$(echo "$repolines" | grep mtype= | cut -f2 -d\" )
	baseurl=$(echo "$repolines" | grep baseurl= | cut -f2 -d\" )
	metafile=$(echo "$repolines" | grep metafile= | cut -f2 -d\" )

	debarch=$(echo $arch | sed 's#x86_64#amd64#g')
	basepath="$baseurl"
	baseurl="$basepath/dists/$codename/$subproject/binary-$debarch"

	mkdir -p "$repo/$arch/:full"
	if ! pushd "$repo/$arch/:full" > /dev/null ; then
		echo "Failed to enter :full in $subproject" 1>&2
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
	popd > /dev/null
done


/usr/sbin/obs_admin --check-all-projects x86_64
