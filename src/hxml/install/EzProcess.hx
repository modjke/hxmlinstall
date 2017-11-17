package hxml.install;
import sys.io.Process;


class EzProcess
{

	public static function execute(cmd:String, ?writeStdin:String = null, log = false):String
	{
		var process = new Process(cmd);			
		
		if (writeStdin != null)
			process.stdin.writeString(writeStdin);
		
		var all = process.stdout.readAll().toString();
		process.close();
		
		if (log)
		{
			Sys.println('Running: $cmd');
			Sys.print(all);
		}
		
		
		return all;
	}
	
}