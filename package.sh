#!/bin/bash
set -ex

git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools
cp depot_tools/win_toolchain/* .

workdir=$PWD
channel=Enterprise  # Community Professional

cd "C:/Program Files/Microsoft Visual Studio/2022/$channel/VC/Tools/MSVC"
latest=$(ls | sort -V | tail -1)
for i in $(ls); do
	[[ $i != $latest ]] || continue
	mv "$i" orig."$i"; rm -r orig.$i &
done

cd "C:/Program Files/Microsoft Visual Studio/2022/$channel/VC/redist/MSVC"
latest=$(ls | sed '/^v/d' | sort -V | tail -1)
for i in $(ls | sed '/^v/d'); do
	[[ $i != $latest ]] || continue
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
win_ver=$(cat win_version|sed 's/\s//g')
echo "version=${version}-${win_ver}" >> $GITHUB_ENV

for i in *.zip; do
	mv "$i" "VisualStudio-${version}-$i"
	ln -s "VisualStudio-${version}-$i" "$i"
done
echo "origin_file=$i" >> $GITHUB_ENV
echo "${i%.zip} ${version} ${win_ver}" > MSVS_HASH

unzip -qd vs VisualStudio-${version}-*.zip
(cd vs; 7z a ../VisualStudio-${version}-${i%.zip}.7z .)
sha256sum "VisualStudio-${version}-$i" > VisualStudio-${version}-$i.sha256
sha256sum "VisualStudio-${version}-${i%.zip}.7z" > VisualStudio-${version}-${i%.zip}.7z.sha256

fsize="$(du -s VisualStudio-${version}-$i|awk '{print$1}')"
if [[ $fsize -ge 2147483 ]]; then
	rm -f "VisualStudio-${version}-$i"*
	echo "origin_file=" >> $GITHUB_ENV
fi

mkdir vs-noarm
cd vs-noarm
echo "::pack VisualStudio NO arm..."
../bin/python3 ../package_from_installed.py --noarm -w $win_ver 2022
unzip -qd ../vs-x86 *.zip
(cd ../vs-x86; 7z a ../VisualStudio-${version}-${win_ver}-noarm.7z .)
cd ..
sha256sum "VisualStudio-${version}-${win_ver}-noarm.7z" > VisualStudio-${version}-${win_ver}-noarm.7z.sha256
