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

	#if macro
	public static function warnIfOutdated()
	{
		#if display
		return;
		#end
		
		
		var libs = collectLibs();
		for (l in libs)
		{
			switch (l.kind)
			{
				case HAXELIB(ver):	//do nothing
				case GIT(url, commit):					
					var libVer = Haxelib.getLibVersion(l.name);
					if (libVer == "git")
					{
						if (commit != null)
						{
							var libPath = Haxelib.getLibPath(l.name, "git");
							var git = new Git(libPath);
							var checkedoutCommit = git.getCheckedoutCommit();
							if (checkedoutCommit != commit)
								haxe.macro.Context.warning('Library ${l.name} is outdated, run haxelib run hxmlinstall', l.position);
							git.close();
						} else 
							haxe.macro.Context.warning('Library ${l.name} has no commit or tag set', l.position);
					} else 
						haxe.macro.Context.warning('Library ${l.name} current version is not git (${libVer})', l.position);
			}
		}
	}
	#end
	
	public static function install()
	{
		#if display
		return;
		#end
				
		var libs = collectLibs();
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
					
				case GIT(url, commit):
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
					
					if (commit == null)
						throw 'For git lib ${lib.name} either a tag or commit should be specified';
						
					
					var checkedOutCommit = git.getCheckedoutCommit();
					Sys.println('Last checked out commit: $checkedOutCommit');
					if (checkedOutCommit != commit)
					{
						Sys.println('Last commit should be: $commit, fetching/checking out...');
						
						if (!git.isWorkDirClean())
						{
							Sys.println('Work directory $path is not clean');
							Sys.exit(1);
						}
						
						git.fetch();
						git.checkout(commit);
						
						checkedOutCommit = git.getCheckedoutCommit();
						if (checkedOutCommit != commit)
						{							
							Sys.println('Failed to checkout $commit');
							Sys.exit(1);
						}
					}
				
					
					
					git.close();
					
			}		
		}
		
	}
	
	static function collectLibs():StringMap<HxmlLib>
	{
		var hxmls = resolveHxmlPaths();
		
		var libs:StringMap<HxmlLib> = new StringMap();
		
		for (hxml in hxmls)
		{			
			for (lib in Hxml.getLibs(hxml))
			{
				if (libs.exists(lib.name)) throw 'Duplicate lib declaration: ${lib.name}';
				
				libs.set(lib.name, lib);
			}
		}
		
		
		return libs;
	}
	
	static function resolveHxmlPaths()
	{		
		var workDir = Sys.getCwd();
		return FileSystem.readDirectory(workDir)
			.filter(function (name) return Path.extension(name) == "hxml")
			.map(function (name) return Path.join([workDir, name]));
			
	}
	

}
