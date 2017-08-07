package hxml.install;


class Git
{

	var prevWorkDir:String;
	
	public function new(dir:String) 
	{
		prevWorkDir = Sys.getCwd();
		Sys.setCwd(dir);
	}
	
	public function initialized():Bool
	{

		var r = ~/On branch/;
		return r.match(EzProcess.execute("git status"));
	}

	public function getFetchOrigin():String
	{
		var r = ~/origin\s+(.+)\s+\(fetch\)/;
		if (!r.match(EzProcess.execute('git remote -v')))
			throw 'Can\'t match fetch origin';
			
		return r.matched(1);
	}
	
	public function isWorkDirClean():Bool
	{
		var r = ~/nothing to commit, working (directory|tree) clean/;		
		return r.match(EzProcess.execute('git status'));
	}
	
	public function getCheckedoutCommit():String
	{
		var r = ~/commit ([0-9,a-f]{40})/;
		if (!r.match(EzProcess.execute('git show')))
			throw 'Can\'t match last checked out commit';			
		return r.matched(1);
	}
	
	public function fetch()
	{
		EzProcess.execute('git fetch');
	}
	
	public function checkout(branchOrCommit:String)
	{
		EzProcess.execute('git checkout $branchOrCommit');
	}
	
	public function close()
	{
		Sys.setCwd(prevWorkDir);
	}
}

