package hxml.install;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;

using StringTools;

class Haxelib
{

	public static function getLibVersion(name:String):Null<String>
	{
		for (lib in EzProcess.execute('haxelib list').split("\n"))
		{
			if (lib.startsWith(name))
			{
				var r = ~/\[(.+)\]/;
				if (!r.match(lib)) throw 'Unexpected, can\'t match version in $lib';				
				return r.matched(1);
			}
		}
			
		
		return null;
	}
	
	public static function setLibVersion(name:String, version:String)
	{
		/* haxelib will ignore version set in .current if .dev is preset, we should rename it */
		var dotdev = Path.join([getLibPath(name), ".dev"]);
		if (FileSystem.exists(dotdev))
		{
			Sys.println('Development version is set for lib: $name: .dev will be renamed to .dev.bpk');
			var dotdevbkp = Path.withExtension(dotdev, "dev.bkp");
			FileSystem.rename(dotdev, dotdevbkp);
		}
		
		EzProcess.execute('haxelib set $name $version --always');
	}
	
	public static function hasLib(name:String, version:String)
	{
		for (lib in EzProcess.execute('haxelib list').split("\n"))
		{
			if (lib.startsWith(name))
				return lib.indexOf(version) > -1;				
		}
		
		return false;
	}
	
	public static function installLib(name:String, version:String)
	{		
		var error = ~/Error: (.+)/g;
		var hasError = error.match(EzProcess.execute('haxelib install $name $version --always'));
		if (hasError)		
			throw 'Error while installing lib: ${error.matched(1)}';	
	}
	
	/**
	 * If version is not supplied when root dir (with version folders) is returned
	 * @param	name
	 * @param	version
	 * @return
	 */
	public static function getLibPath(name:String, ?version:String):String
	{
		var r = ~/\((.+)\)/;
		if (!r.match(EzProcess.execute('haxelib setup', '\n')))
			throw 'Can\'t match haxelib path';
		var hlPath = r.matched(1);
		
		var parts = [hlPath, name];
		if (version != null) parts.push(version.replace(".", ","));
		var p = Path.join(parts);
		
		if (!FileSystem.exists(p))
			FileSystem.createDirectory(p);
			
		if (!FileSystem.isDirectory(p))
			throw 'Not a directory: $p';
			
		return p;
	}
	
	public static function installGitLib(name:String, url:String)
	{
		var error = ~/Error: (.+)/g;
		var hasError = error.match(EzProcess.execute('haxelib git $name "$url" --always', true));
		if (hasError)		
			throw 'Error while installing git lib: ${error.matched(1)}';				
	}
		
	
}