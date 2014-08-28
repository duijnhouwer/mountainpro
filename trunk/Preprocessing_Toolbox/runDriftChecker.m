%runDriftChecker Runs z-drift checking algorithm
%Use this function to check the stability of your recordings over time. It
%requires a xyz stack as well as a time series recordings; it then
%calculates the similarity for each frame to the different planes in the
%z-stack, allowing you to investigate changes in z-level over time within a
%recording. It uses the subfunction doDriftCheck to perform the
%registration and the subfunction doPlotDriftCheck to show the results.
%doDriftCheck also saves a data file to the hard drive in the recording
%folder for later subsequent analysis 
%
%	Version history:
%	1.0 - May 16 2014
%	Created by Jorrit Montijn

%% input variables
%source data
strMasterPath = 'D:\Data\Processed\imagingdata\';
strDirRawStackZ = 'G:\Data\Raw\imagingdata\20140507\xyz';
strSession = '20140507';
vecRecordings = 2:3;
boolDoPlots = false;

for intRecording=1:length(vecRecordings)
	%generate recording name
	strRecording = sprintf('xyt%02d',intRecording);

	%put data in structure
	sSourceData.strMasterPath = strMasterPath;
	sSourceData.strDirRawStackZ = strDirRawStackZ;
	sSourceData.strSession = strSession;
	sSourceData.strRecording = strRecording;

	%do drift check
	sRegZ = doDriftCheck(sSourceData);

	%plot output
	if boolDoPlots,doPlotDriftCheck(sRegZ);end
end