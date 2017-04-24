package hxml.install;


using Lambda;

import haxe.ds.StringMap;
import haxe.io.Path;
import hxml.install.Hxml.HxmlLib;
import hxml.install.Hxml.HxmlPosition;
import sys.FileSystem;
import sys.io.File;


class HxmlInstall
{


	public static function main()
	{	
		var args = Sys.args();

		//consume the last argument (set by haxelib run) if it is a path and set it as a current working dir
		if (args.length > 0) 
		{			
			
			if (~/[a-z,A-Z]:(?:\\|\/)/.match(args[args.length - 1]))	
			{
				var dir = args.pop();
				Sys.setCwd(dir);
			}
		}
		
		inline function getArgAt(index:Int):Null<String> return args.length > index ? args[index] : null;
			
		var command:String = getArgAt(0);
		if (command == null) command = "install";
			
		Sys.println('Running hxmlinstall');				
		Sys.println('Current working dir is ${Sys.getCwd()}');
		switch (command)
		{
			case "install": 
				install();
			case "upref": 
				upref(getArgAt(1));
			case _: 
				Sys.println('Invalid argument: $command');
		}		
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
								haxe.macro.Context.warning('Library ${l.name} is outdated, run haxelib run hxmlinstall', libPos(l.position));
							git.close();
						} else 
							haxe.macro.Context.warning('Library ${l.name} has no commit or tag set', libPos(l.position));
					} else 
						haxe.macro.Context.warning('Library ${l.name} current version is not git (${libVer})', libPos(l.position));
			}
		}
	}
	
	//converts HxmlPosition to haxe.macro.Expr.Position
	inline static function libPos(p:HxmlPosition) return haxe.macro.Context.makePosition({ file: p.file, min: p.libMin, max: p.libMax });
	#end
	
	public static function upref(?lib:String)
	{
		var libs = collectLibs();
		if (lib != null) 		
		{
			if (libs.exists(lib))
				libs = [lib => libs.get(lib)]
			else 
			{
				Sys.println('Lib $lib is not referenced in any hxmls');
				return;
			}
		}
		
		for (l in libs)
		{
			
			switch (l.kind)
			{
				case GIT(url, commit):
					Sys.println('Processing ${l.name}');
					makeSureThisIsAGitLib(l.name, url);
					var git = new Git(Haxelib.getLibPath(l.name, "git"));
					var checkedOut = git.getCheckedoutCommit();
					var fetchUrl = git.getFetchOrigin();
					if (checkedOut != commit ||
						fetchUrl != url)
					{						
						Sys.println('Updating git reference for ${l.name}');
						Hxml.updateGitRef(l.position.file, l.name, fetchUrl, checkedOut);
						
						if (fetchUrl != url)
							Sys.println('Updated origin from $url to $fetchUrl');
							
						if (checkedOut != commit)
							Sys.println('Updated from $commit to $checkedOut');
							
					} else {
						Sys.println('Up to date');
					}
				case _:
			}
		}
	}
	
	static function makeSureThisIsAGitLib(lib:String, url:String)
	{
		var currentLibVersion = Haxelib.getLibVersion(lib);
		//Sys.println('Current $lib version is $currentLibVersion');
		if (currentLibVersion != "git")
		{
			Sys.println('Installing library from git: $url');
			Haxelib.installGitLib(lib, url);
			Haxelib.setLibVersion(lib, "git");
		}				
	}
	
	public static function install()
	{		
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
					makeSureThisIsAGitLib(lib.name, url);
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
