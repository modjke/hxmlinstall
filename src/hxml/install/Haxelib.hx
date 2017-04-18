package hxml.install;
import haxe.io.Path;
import sys.FileSystem;

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
		EzProcess.execute('haxelib install $name $version --always');
	}
	
	public static function getLibPath(name:String, version:String):String
	{
		var r = ~/\((.+)\)/;
		if (!r.match(EzProcess.execute('haxelib setup', '\n')))
			throw 'Can\'t match haxelib path';
		var hlPath = r.matched(1);
		
		var p = Path.join([hlPath, name, version.replace(".", ",")]);
		
		if (!FileSystem.exists(p))
			throw 'Does not exist: $p';
			
		if (!FileSystem.isDirectory(p))
			throw 'Not a directory: $p';
			
		return p;
	}
	
	public static function installGitLib(name:String, url:String)
	{
		EzProcess.execute('haxelib git $name $url');
	}
		
	
}