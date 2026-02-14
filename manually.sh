#!/bin/bash

failed() {
	tasklist | findstr vs_setup_bootstrapper
	tasklist | findstr vs_enterprise
	tasklist | findstr setup
	rm -rf "C:\ProgramData\Package Cache"
	echo "You can kill these processes and try again."
	exit 1
}
sed '/winget install/d' reinstall.sh | bash -ex || failed
bash -ex package.sh
. "$GITHUB_ENV"
gh release create $version \
	MSVS_HASH \
	VisualStudio-*.7z* \
	VisualStudio-*.zip* \
	$origin_file
