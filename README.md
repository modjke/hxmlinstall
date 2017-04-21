# hxmlinstall
hxmlinstall: git hosted haxe libraries made easy

### Story goes first
>New project! You've got your favourite libs all set up via hxml file.  
You start developing your brand new haxe application.  
And when suddenly most usefull lib in your hxml is buggy.  
First you search lib.haxe.org for updates or alternative, no luck there.  
Next you check github.com/maitainer/usefulllib - nothing.  
There is no stopping you at that point - you fork it!  
You've located the bug, you've eliminated it, you've commited the fix.  
There it is, the greatest pull request of your life, waiting to be merged   
(and published to lib.haxe.org as a new version), but you need to move forward.  
Your project depends on the forked version of the lib you've just fixed.  

# how to use

Add hxmlinstall to your main hxml
```
-lib hxmlinstall
```
annotate the git libs like so (```#git [origin] [commit]```)
```
#git https://github.com/you/forkedlib 854d90f04ba07ff37f51fbdc315da64c07c5c22c
-lib forkedlib:git
```
to install or update everything run from the dir with hxml
```
haxelib run hxmlinstall
```
it will collect all the libs from any hxml in current directory and install or update them 
for git libs: sets haxelib current version to git (if it is not already), fetches/checksout required changes
for non-git libs: 'haxelib install lib:version' if it is not installed

# Building your project
After initial 
```haxelib run hxmlinstall``` 
it is safe to assume that 
```haxe yourbuildhxml.hxml```
will not fail with 'lib not installed' errors

**There is no need to run hxmlinstall everytime before build,
if there is any git lib that is pointing to a different commit or fetches from wrong origin
initialization macro will trigger a warning @ build time.**

# Updating hxml refs
Consider use-case: you've just updated a git lib and commited/pushed your changes, 
now you want your project hxml to point to a newer version, you can do that with
```
haxelib run hxmlinstall upref [libname]
```
***Warning***: if libname is not specified when hxmlinstall will update every git lib reference in your hxml files
