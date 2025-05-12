#!/bin/bash -e

PATH="/c/Users/$(id -un)/AppData/Local/Microsoft/WindowsApps:$PATH"
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\InstallCleanup.exe"

for sdk in `yes | winget list | grep -i WindowsSDK | cut -d' ' -f7`
do
	[[ $sdk ]] || continue
	printf ":: Uninstalling $sdk..."
	winget uninstall $sdk >/dev/null
	printf "done.\n"
done
rm -rf "C:\Program Files (x86)\Windows Kits"
rm -rf /c/Program\ Files*/Microsoft\ Visual\ Studio

wget -nv -c https://aka.ms/vs/17/release/vs_enterprise.exe
echo y | winget install --id Microsoft.VisualStudio.2022.Enterprise >log || echo ":: Winget install VS failed"

printf ":: Update VisualStudio installer..."
./vs_enterprise.exe --quiet --wait --installerOnly >/dev/null
printf "done.\n"
printf ":: Install VisualStudio from config-file: vsconfig.json..."
./vs_enterprise.exe --quiet --wait --config vsconfig.json >vs.log
printf "done.\n"

# https://developer.microsoft.com/windows/downloads/windows-sdk
SDKURL="https://download.microsoft.com/download/cb9de490-6e67-4ac6-8c2c-6dfabb824e8a/22621.5040.250311-1927.ni_release_svc_im_WindowsSDK.iso"

echo ":: Download WindowsSDK ISO"
wget -nv -cO WindowsSDK.iso "$SDKURL"
7z x WindowsSDK.iso -oSDK.iso

printf ":: Install WindowsSDK..."
./install_winsdk.cmd
printf "done.\n"
