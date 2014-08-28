function runStartup
	%runStartup Runs a data backup and script backup
	%
	%	Version 1.0 [2014-06-02]
	%	2014-06-02; Created by Jorrit Montijn
	
	%run script backup
	runScriptBackup
	
	%run data backup
	runDataBackup
end

