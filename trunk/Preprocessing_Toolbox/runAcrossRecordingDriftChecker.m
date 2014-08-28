%runAcrossRecordingDriftChecker Runs z-drift checking algorithm over recordings
%Use this function to check the z-stability over your recordings. It
%requires a xyz stack as well as multiple time series recordings; it then
%calculates the similarity for at the start, middle and end of each
%recording to the different planes in the z-stack, allowing you to
%investigate slow drifts in z-level over time between recordings. It uses
%the subfunction doAcrossRecordingDriftCheck to perform the registration
%and the subfunction doPlotAcrossRecordingDriftCheck to show the results.
%doAcrossRecordingDriftCheck also saves a data file to the hard drive in
%the recording folder for later subsequent analysis
%
%	Version history:
%	1.0 - May 16 2014
%	Created by Jorrit Montijn

%% input variables
%source data
clear all
strMasterPath = 'F:\Data\Processed\imagingdata\';
boolDoPlots = true;

intMouse=6;
if intMouse == 3
	strDirRawStackZ = 'G:\Data\Raw\imagingdata\20140425\xyz_2';
	strSession = '20140425';
	vecRecordings = 1:8;
elseif intMouse == 4
	strDirRawStackZ = 'G:\Data\Raw\imagingdata\20140430\xyz';
	strSession = '20140430';
	vecRecordings = 1:8; %xyt01 is not used for analysis
elseif intMouse == 5
	strDirRawStackZ = 'G:\Data\Raw\imagingdata\20140507\xyz';
	strSession = '20140507';
	vecRecordings = 1:3;
elseif intMouse == 6
	strDirRawStackZ = 'G:\Data\Raw\imagingdata\20140530\xyz';
	strSession = '20140530';
	vecRecordings = 1:9;
end

%put data in structure
sSourceData.strMasterPath = strMasterPath;
sSourceData.strDirRawStackZ = strDirRawStackZ;
sSourceData.strSession = strSession;
sSourceData.vecRecordings = vecRecordings;

%do drift check
sRegZ = doAcrossRecordingDriftCheck(sSourceData);

%plot output
if boolDoPlots
	if ~exist('sRegZ','var')
		%make structure
		sRegZ = struct;
		sRegZ.matRegistrationZ = matRegistrationZ;
		sRegZ.sData = sData;
		sRegZ.strSession = strSession;
		sRegZ.vecRecordings = vecRecordings;
		sRegZ.sRec = sRec;
	end
	doPlotAcrossRecordingDriftCheck(sRegZ);
end