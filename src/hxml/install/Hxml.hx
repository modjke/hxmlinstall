package hxml.install;

import sys.io.File;

using StringTools;

class Hxml
{
	
	public static function updateGitRef(hxml:String, lib:String, gitUrl:String, commit:String)
	{
		var content = File.getContent(hxml);
		var lines = content.split("\n");
		
		var updated = false;
		for (i in 0...lines.length)
		{
			var line = lines[i];
			var r = ~/-lib ([\S]+):git/;
			if (r.match(line))
			{
				var libName = r.matched(1);
				if (libName == lib)
				{
					if (i > 0)
					{
						var r = ~/#git (\S+) (\S+)/;						
						var prev = lines[i - 1];	
						if (r.match(prev))
						{							
							var newRef = '#git $gitUrl $commit';
							lines[i - 1] = r.replace(prev, newRef);
							
							updated = true;
							break;
						}
					}
				}
			}
		}
		
		if (updated)
			File.saveContent(hxml, lines.join("\n"));
		else 
			throw 'Failed to find&update $lib @ $hxml';
	}

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
		
		var prevMin = 0;
		var prevMax = 0;
		
		for (i in 0...lines.length)
		{
			var l = lines[i];
			var line = l.line;
			var index = line.indexOf(" ");
			
			var pos = {
				file: hxml,
				libMin: l.min,
				libMax: l.max,
				metaMin: prevMin,
				metaMax: prevMax
			};
			
			prevMin = l.min;
			prevMax = l.max;
			
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

typedef HxmlPosition = {
	file:String,
	metaMin:Int,
	metaMax:Int,
	libMin:Int,
	libMax:Int
}

class HxmlLib
{
	public var name(default, null):String;
	public var kind(default, null):HxmlLibKind;
	public var position(default, null):HxmlPosition;

	public function new(name:String, kind:HxmlLibKind, position:HxmlPosition)
	{
		this.name = name;
		this.kind = kind;
		this.position = position;
	}
}

