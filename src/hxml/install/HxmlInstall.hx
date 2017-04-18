package hxml.install;

using Lambda;

import haxe.ds.StringMap;
import haxe.io.Path;
import hxml.install.Hxml.HxmlLib;
import sys.FileSystem;
import sys.io.File;


class HxmlInstall
{

	public static function main()
	{	
		var args = Sys.args();
		if (args.length > 0)
			Sys.setCwd(args[0]);
			
		Sys.println('Running hxml install...');				
		Sys.println('Current working dir: ${Sys.getCwd()}');
		install();
	}
	
	public static function install()
	{
		var hxmls = resolveHxmlPaths();
		
		var libs:StringMap<HxmlLib> = new StringMap();
		
		for (hxml in hxmls)
		{
			var hxmlData = File.getContent(hxml);
			for (lib in Hxml.getLibs(hxmlData))
			{
				if (libs.exists(lib.name)) throw 'Duplicate lib declaration: ${lib.name}';
				
				libs.set(lib.name, lib);
			}
		}
		
		for (lib in libs)
		{
			Sys.println('Processing lib: ${lib.name}...');
			switch (lib.kind)
			{
				case HAXELIB(ver):
					if (ver != null)
					{
						Sys.println('Making sure that ${lib.name} : $ver is installed');
								
						if (!Haxelib.hasLib(lib.name, ver))							
							Haxelib.installLib(lib.name, ver);
							
			
						
					} else {
						Sys.println('No version specified, skipped');
					}
					
				case GIT(url, branchOrCommit):
					var currentLibVersion = Haxelib.getLibVersion(lib.name);
					Sys.println('Current lib version is $currentLibVersion');
					if (currentLibVersion != "git")
					{
						Sys.println('Installing library from git: $url');
						Haxelib.installGitLib(lib.name, url);
					}
						
					var path = Haxelib.getLibPath(lib.name, "git");
					var git = new Git(path);
					
					var fetchOrigin = git.getFetchOrigin();
					Sys.println('Fetch origin is: $fetchOrigin');
					if (fetchOrigin != url)											
					{
						Sys.println('Fetch origin should be $url, installing from other url...');
						if ( git.isWorkDirClean() )						
							Haxelib.installGitLib(lib.name, url);
						else 
							throw 'Lib ${lib.name} installed with different origin ($url) and working directory is not clean';
					}
					
					if (branchOrCommit == null)
						throw 'For git lib ${lib.name} either a branch name or commit should be specified';
						
					if (branchOrCommit.commit)
					{
						var checkedOutCommit = git.getCheckedoutCommit();
						Sys.println('Last checked out commit: $checkedOutCommit');
						if (checkedOutCommit != branchOrCommit)
						{
							Sys.println('Last commit should be: $branchOrCommit, fetching/checking out...');
							git.fetch();
							git.checkout(branchOrCommit);
						}
							
					} else if (branchOrCommit.branch) {
						Sys.println('Fetching / checking out lastest changed for branch: $branchOrCommit');
						git.fetch();
						git.checkout(branchOrCommit);
						
					} else 
						throw 'Unexpected: $branchOrCommit';
					
					git.close();
					
			}		
		}
		
	}
	
	static function resolveHxmlPaths()
	{		
		var workDir = Sys.getCwd();
		return FileSystem.readDirectory(workDir)
			.filter(function (name) return Path.extension(name) == "hxml")
			.map(function (name) return Path.join([workDir, name]));
			
	}
}
