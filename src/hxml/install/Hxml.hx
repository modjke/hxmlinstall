package hxml.install;

import sys.io.File;

using StringTools;

typedef Position = 
	#if macro
	haxe.macro.Expr.Position;
	#else
	{};
	#end
	

class Hxml
{

	public static function getLibs(hxml:String):Array<HxmlLib>
	{
		var hxmlData = File.getContent(hxml);
		
		var splitted = hxmlData.split("\n");
		var min = 0;
		var max = 0;
		var lines = [];
		
		
		for (l in splitted) {			
			max = min + l.length;
			lines.push({
				line: l.trim(),
				min: min,
				max: max
			});
			min = max + 1;
		}
			
		
			
			
		var libs:Array<HxmlLib> = [];
		
		var i = lines.length;
		while (i-- > 0)
		{
			var l = lines[i];
			var line = l.line;
			var index = line.indexOf(" ");
			
			var pos = 
				#if macro
				haxe.macro.Context.makePosition({min:l.min, max:l.max, file:hxml});
				#else
				null;
				#end
		
				
			if (index > -1)
			{
				var arg = line.substr(0, index);				
				if (arg == "-lib")
				{
					var value = line.substr(index + 1).split(":");
					var lib = value[0];					
					var version = value.length > 1 ? value[1] : null;
					
					//previous line
					var prev = i > 0 ? lines[i - 1].line : null;
					if (prev != null && prev.startsWith("#git")) {
						value = prev.split(" ");
						var gitUrl = value.length > 1 ? value[1] : null;						
						if (gitUrl == null)
							throw 'Expected git url for lin: $lib';
							
						var commit = value.length > 2 ? value[2] : null;
						
						if (version != null && version != "git")
							throw 'Version specified for lib: $lib';
						
						libs.push(new HxmlLib(lib, GIT(gitUrl, commit), pos));
					} else {
						libs.push(new HxmlLib(lib, HAXELIB(version), pos));
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
	GIT(url:String, commit:String);
}


class HxmlLib
{
	public var name(default, null):String;
	public var kind(default, null):HxmlLibKind;
	public var position(default, null):Position;

	public function new(name:String, kind:HxmlLibKind, position:Position)
	{
		this.name = name;
		this.kind = kind;
		this.position = position;
	}
}

