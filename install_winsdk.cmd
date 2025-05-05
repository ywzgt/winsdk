@echo off

set ISO="SDK.iso\Installers"

"%ISO%\SDK Debuggers-x86_en-us.msi" /quiet /norestart
"%ISO%\Universal CRT Redistributable-x86_en-us.msi" /quiet /norestart
"%ISO%\Universal CRT Headers Libraries and Sources-x86_en-us.msi" /quiet /norestart
