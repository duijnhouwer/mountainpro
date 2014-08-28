function runScriptBackup
	%runScriptBackup Runs a startup check to list all .m files in specified
	%location and copies them to the target location
	%
	%	Version 1.0 [2014-06-02]
	%	2014-06-02; Created by Jorrit Montijn
	
	%run backup
	strTargetDir = 'D:\Dropbox\Processing';
	strDataDir = 'F:\Data\Processing';
	intStartRelativePath = length(strDataDir)+1;
	if exist(strDataDir,'dir') && exist(strTargetDir,'dir')
		%msg
		fprintf('\nChecking for .m and .fig files to backup...\n');
		
		%get list of all directories
		cellPaths = getSubDirs(strDataDir,inf,{'Toolboxes','old','backup'});
		intNew = 0;
		
		%loop through folders to check for script files
		for intPath=1:length(cellPaths)
			sScriptFiles=dir([cellPaths{intPath} filesep '*.m']);
			strRelPath = [cellPaths{intPath}(intStartRelativePath:end) filesep];
			[boolSuccess,strMsg]=mkdir([strTargetDir strRelPath]); %create path in target folder
			for intFile=1:length(sScriptFiles)
				strFile = sScriptFiles(intFile).name;
				intNew = intNew + 1;
				[boolSuccess,strMsg] = copyfile([cellPaths{intPath} filesep strFile],[strTargetDir strRelPath strFile]);
				if ~boolSuccess,fprintf('Copying failed for file [%d] at dir [%d/%d]: [%s] Msg was: "%s" [%s]\n',intNew,intPath,length(cellPaths),[strRelPath strFile],strMsg,getTime);end
			end
		end
		
		%loop through folders to check for script files
		for intPath=1:length(cellPaths)
			sFigFiles=dir([cellPaths{intPath} filesep '*.fig']);
			for intFile=1:length(sFigFiles)
				strFile = sFigFiles(intFile).name;
				intNew = intNew + 1;
				strRelPath = [cellPaths{intPath}(intStartRelativePath:end) filesep];
				[boolSuccess,strMsg] = copyfile([cellPaths{intPath} filesep strFile],[strTargetDir strRelPath strFile]);
				if ~boolSuccess,fprintf('Copying failed for file [%d] at dir [%d/%d]: [%s] Msg was: "%s" [%s]\n',intNew,intPath,length(cellPaths),[strRelPath strFile],strMsg,getTime);end
			end
		end
		
		fprintf('%d programming files were copied\n',intNew);
	else
		warning([mfilename ':NoDataDir'],'Data [%s] or target [%s] directory not found',strDataDir,strTargetDir)
	end
end