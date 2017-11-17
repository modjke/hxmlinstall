@echo off
del haxelib.zip
7z.exe a haxelib.zip src build.hxml extraParams.hxml haxelib.json LICENSE README.md run.n
haxelib submit haxelib.zip
del haxelib.zip