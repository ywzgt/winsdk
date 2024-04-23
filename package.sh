#!/bin/bash
set -ex

git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools
cp depot_tools/win_toolchain/* .

workdir=$PWD
channel=Enterprise  # Community Professional

cd "C:/Program Files/Microsoft Visual Studio/2022/$channel/VC/Tools/MSVC"
latest=$(ls | sort -V | tail -1)
for i in $(ls); do
	[[ $i != $latest ]] || { rm -rf $i/{,atlmfc/}lib/spectre; continue; }
	mv "$i" orig."$i"; rm -r orig.$i &
done

cd "C:/Program Files/Microsoft Visual Studio/2022/$channel/VC/redist/MSVC"
latest=$(ls | sed '/^v/d' | sort -V | tail -1)
for i in $(ls | sed '/^v/d'); do
	[[ $i != $latest ]] || { rm -rf $i/{spectre,vc_redist.arm64.exe}; continue; }
	rm -r "$i"
done

cd $workdir
find "C:/Program Files/Microsoft Visual Studio/2022/$channel" ! -type d -name \*.png -delete
find "C:/Program Files/Microsoft Visual Studio/2022/$channel" ! -type d -name clang_rt.\* -delete
find "C:/Program Files/Microsoft Visual Studio/2022/$channel" -type d -iname Windows7 | xargs rm -rf
wget "https://chrome-infra-packages.appspot.com/dl/infra/3pp/tools/cpython3/windows-amd64/+/latest" \
	-nv -O python3-windows-x64_zip
7z x python3-windows-x64_zip

./run.cmd
version=$(cat vs_version|sed 's/\s//g')
echo "version=${version}" >> $GITHUB_ENV

for i in *.zip; do mv "$i" "VisualStudio-${version}-$i"; done
unzip -qd vs VisualStudio-${version}-*.zip
(cd vs; 7z a ../VisualStudio-${version}-${i%.zip}.7z .)
sha256sum "VisualStudio-${version}-$i" > VisualStudio-${version}-$i.sha256
sha256sum "VisualStudio-${version}-${i%.zip}.7z" > VisualStudio-${version}-${i%.zip}.7z.sha256
