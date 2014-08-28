function runDataBackup
	%runDataBackup Runs a startup check for new session files and creates
	%backup if they have not been backed up yet
	%
	%	Version 1.0 [2014-06-02]
	%	2014-06-02; Created by Jorrit Montijn
	
	%run backup
	strTargetDir = 'D:\Dropbox\DataBackup';
	strDataDir = 'D:\Data\Processed\imagingdata';
	if exist(strDataDir,'dir') && exist(strTargetDir,'dir')
		%check which ones are already copied
		fprintf('\nChecking for new session files to backup...\n');
		sSesFilesBackedUp=dir([strTargetDir filesep '*_ses.mat']);
		cellSesCopied = cell(1,length(sSesFilesBackedUp));
		for intCopiedFile=1:length(sSesFilesBackedUp)
			cellSesCopied{intCopiedFile} = sSesFilesBackedUp(intCopiedFile).name;
		end
		
		%get list of all directories, 2 subfolders deep
		cellPaths = getSubDirs(strDataDir,2);
		intNew = 0;
		
		%loop through folders to check for session files
		for intPath=1:length(cellPaths)
			sSesFiles=dir([cellPaths{intPath} filesep '*_ses.mat']);
			for intFile=1:length(sSesFiles)
				strFile = sSesFiles(intFile).name;
				if ~ismember(strFile,cellSesCopied)
					intNew = intNew + 1;
					fprintf('Found new file [%d/%d]! Copying [%s] from [%s] to [%s]\n',intPath,length(cellPaths),strFile,cellPaths{intPath},strTargetDir);
					[boolSuccess,strMsg] = copyfile([cellPaths{intPath} filesep strFile],[strTargetDir filesep strFile],'f');
					if boolSuccess,fprintf('   Success! [%s]\n',getTime)
					else fprintf('   Error! Message is: %s [%s]\n',strMsg,getTime);end
				end
			end
		end
		fprintf('%d new session files were found\n',intNew);
	else
		warning([mfilename ':NoDataDir'],'Data [%s] or target [%s] directory not found',strDataDir,strTargetDir)
	end
end

