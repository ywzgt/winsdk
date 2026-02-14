#!/bin/bash

failed() {
	tasklist | findstr vs_setup_bootstrapper
	tasklist | findstr vs_enterprise
	tasklist | findstr setup
	rm -rf "C:\ProgramData\Package Cache"
	echo "You can kill these processes and try again."
	exit 1
}

sed '/winget install/d' reinstall.sh > reins_vs.sh
case "$1" in VisualStudio.*.Release*)
	sed -i "s|\./vs_enterprise.exe|& --channelId $1|" reins_vs.sh
	;;
esac
bash -ex reins_vs.sh || failed
bash -ex package.sh

. "$GITHUB_ENV"
gh release create $version \
	--generate-notes \
	MSVS_HASH \
	VisualStudio-*.7z* \
	VisualStudio-*.zip* \
	$origin_file
