package hxml.install;
import haxe.macro.Context;

using StringTools;

class Hxml
{

	public static function getLibs(hxmlData:String):Array<HxmlLib>
	{
		var lines = hxmlData.split("\n")
			.map(StringTools.trim)
			.filter(function (s) return s.length > 0);
			
		var libs:Array<HxmlLib> = [];
		
		var i = lines.length;
		while (i-- > 0)
		{
			var line = lines[i];
			var index = line.indexOf(" ");
			if (index > -1)
			{
				var arg = line.substr(0, index);				
				if (arg == "-lib")
				{
					var value = line.substr(index + 1).split(":");
					var lib = value[0];
					var version = value.length > 1 ? value[1] : null;
					
					//previous line
					var prev = i > 0 ? lines[i - 1] : null;
					if (prev != null && prev.startsWith("#git")) {
						value = prev.split(" ");
						var gitUrl = value.length > 1 ? value[1] : null;						
						if (gitUrl == null)
							throw 'Expected git url for lin: $lib';
							
						var branchOrCommit = value.length > 2 ? value[2] : null;
						
						if (version != null)
							Context.fatalError('Version specified for lib: $lib', Context.currentPos());
						
						libs.push(new HxmlLib(lib, GIT(gitUrl, branchOrCommit)));
					} else {
						libs.push(new HxmlLib(lib, HAXELIB(version)));
					}
				}
			}
			
		}
		return libs;
	}
	
}

enum HxmlLibKind
{
	HAXELIB(?version:String);
	GIT(url:String, ?branchOrCommit:BranchOrCommit);
}

abstract BranchOrCommit(String) from String to String
{
	
	public var branch(get, never):Bool;
	inline function get_branch() return !commit;
	public var commit(get, never):Bool;
	inline function get_commit() return ~/([a-f,0-9]{40})/.match(this.toLowerCase());
	
}

class HxmlLib
{
	public var name(default, null):String;
	public var kind(default, null):HxmlLibKind;
	
	public function new(name:String, kind:HxmlLibKind)
	{
		this.name = name;
		this.kind = kind;
	}
}

