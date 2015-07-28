function runPreProMaster
    %runPrePro Runs data pre-preprocessing
    %
    %This preprocessing toolbox was created to minimize the effort of
    %preprocessing two-photon calcium data and was created by Jorrit Montijn at
    %the University of Amsterdam
    %
    %To finish all pre-processing steps, you should run the following scripts
    %in order:
    %
    %(1) runPreProMaster
    %	Use this function to pre-preprocess data; this includes meta data
    %	retrieval (doPrePro), image processing (doImagePrePro) and pixel-based
    %	stimulus response maps (doCalcPixelResponsiveness)
    %(2) runDetectCells
    %	This function is used to select regions of interest based on the
    %	average images generated by the previous step; it includes broad
    %	functionality including neuronal subtype differentation based on 960nm
    %	reference images, pixel-based responsiveness maps,
    %	retrieval (doPrePro), image processing (doImagePrePro) and pixel-based
    %	stimulus response maps (doCalcPixelResponsiveness), automatic border
    %	detection for OGB and GCaMP, and across-recording alignment functions,
    %	such as the custom-built automatic recursive locally affine subfield
    %	reregistration algorithm (by JM), ROI shift detection, etc.
    %(3) runPostDetectionMaster
    %	This function runs all post-preprocessing steps consecutively for the
    %	defined session/recordings; this includes the following steps:
    %	runImageToTimeseries to extract fluorescence time traces from the image
    %	data for all ROIs defined in the previous step;
    %	runDetectCalciumTransients to calculate dF/F0 values from these traces
    %	and detect spikes from the calcium transient data; and
    %	runBuildSesFromPrePro to transform the preprocessing data format to a
    %	more useable "ses" data format on which all data processing functions
    %	are based
    %(4) Optional: eye-tracking video analysis and Z-drift checking
    %	(runDriftChecker/runAcrossRecordingDriftChecker) to confirm z-stability
    %	of your recordings
    %
    %	Version history:
    %	1.0 - September 14 2012
    %	Created by Jorrit Montijn
    %	2.0 - May 16 2014
    %	Updated help & comments [by JM]
    
    
    % the input data structure should be as follows:
    %[Session] ('YYYYMMDD')
    %	[Recording] ('xyt01')
    %		[t] ('163')
    %			[z] ('1')
    %				[ch] ('2')
    %					FrameXY ('[session]\[recording]\[recording]_t0001_ch00.tif')
    % the XML file should be named [recording]_Properties.xml and should be
    % present in either \[session]\[recording]\ or
    % [session]\[recording]\MetaData\
    
    %{
data structure PER RECORDING:
sRec = struct;

sRec.sPS = sPS;

sRec.sMD = sMD;

sRec.strSession = 'YYYYMMDD';
sRec.vecRecordings = [1 2 3 4 5];
sRec.intRecording = 4;

sRec.xml = struct;

sRec.sRawLog = struct;

sRec.sRawLib = struct;
sRec.sRawLib.strRecording = 'xyt01';
sRec.sRawLib.strName = 'VisualStimulation_JOB010';
sRec.sRawLib.strStimLog
sRec.sRawLib.t = 2376;
sRec.sRawLib.z = 1;
sRec.sRawLib.x = 512;
sRec.sRawLib.y = 512;

sRec.sProcLib = struct;
sRec.sProcLib.strRecording = sRec.sPS.strRecording{sRec.intRecording};
sRec.sProcLib.strName = sRec.sProcLib.strRecording;
sRec.sProcLib.t = 2376;
sRec.sProcLib.z = 1;
sRec.sProcLib.x = 512;
sRec.sProcLib.y = 512;

sRec.sProcLog = struct; %processing log
sRec.sProcLog.boolTempPresent = false;
sRec.sProcLog.boolDefaultFound = false;
sRec.sProcLog.boolXMLFound = false;
sRec.sProcLog.boolStimLogFound = false;
sRec.sProcLog.boolTestLoaded = false;
sRec.sProcLog.boolRawLibPresent = false;
sRec.sProcLog.boolProcLibPresent = false;
sRec.sProcLog.boolPhaseCorrected = false;
sRec.sProcLog.boolSmoothed = false;
sRec.sProcLog.boolRegistered = false;
sRec.sProcLog.boolAverageSaved = false;
    %}
    
    %% load default settings
    sPS = loadDefaultSettingsPrePro();%structProcessingSettings
    sPS.boolSupervised = false; %is there anyone overseeing the process? or should it just run without asking input?
    
    %% define general metadata
    sMD = struct; %structMetaData
    sMD.strMasterDir = 'F:\Data';
    sMD.strSourceDir = 'F:\Data';
    sMD.strImgSource = '\Raw\imagingdata\';
    sMD.strLogSource = '\Raw\imaginglogs\';
    sMD.strImgTarget = '\Processed\imagingdata\';
    sMD.strLogTarget = '\Processed\imaginglogs\';
    sMD.strTemp = '\Temp\';
    
    %% define specific recording
    cellSes={};
    cellRec={};
    cellStimLog={};
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt01';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620130041_xyt01_Montijn.mat'; %name of the stimulation log
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt02';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620143222_xyt02_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt03';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620153329_xyt03_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt04';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620161431_xyt04_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt05';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620173308_xyt05_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt06';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620183728_xyt06_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt07';
    cellStimLog{end+1} = 'lkDpxGratingAdaptExp-M019-20150620185803_xyt07_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt08';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620203004_xyt08_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt09';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620212202_xyt09_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt10';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620220836_xyt10_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt11';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620224618_xyt11_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt12';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150620232257_xyt12_Montijn.mat';
    %
    cellSes{end+1}= '20150620';
    cellRec{end+1}= 'xyt13';
    cellStimLog{end+1} = 'lkDpxGratingExp-M019-20150621003630_xyt13_Montijn.mat';
    %
%     cellSes{end+1}= '20150401';
%     cellRec{end+1}= 'xyt14';
%     cellStimLog{end+1} = 'lkDpxGratingAdaptExp-M015-20150401233534_xyt14_Montijn.mat';
%     %
%     cellSes{end+1}= '20150401';
%     cellRec{end+1}= 'xyt15';
%     cellStimLog{end+1} = 'lkDpxGratingAdaptExp-M015-20150402000312_xyt15_Montijn.mat';
    vecRecordings=4:5;
    %assign filenames
    for intRec=vecRecordings(:)'
        cellName{intRec} = cellRec{intRec};
        cellRefPaths{intRec} =[sMD.strSourceDir sMD.strImgSource cellSes{intRec} filesep cellName{intRec} filesep];
    end

    
    %% collect metadata for recordings
    multiStruct = struct;
    for intRecording=vecRecordings(:)'
        %define variables for every recording
        sRec = struct;
        sRec.sPS = sPS;
        sRec.sMD = sMD;
        sRec.strSession = cellSes{intRecording};
        sRec.vecRecordings = vecRecordings;
        sRec.intRecording = intRecording;
        sRec.sRawLib = struct;
        sRec.sRawLib.strRecording = cellName{intRecording}; %directory
        sRec.sRawLib.strName = cellName{intRecording}; %file name header
        sRec.sRawLib.strStimLog = cellStimLog{intRecording}; %name of the stimulation log
        %sRec.sRawLib.strRefIm = cellRefIms{intRecording}; %name of reference registration image (if different from the data set itself)
        sRec.sRawLib.strRefPath = cellRefPaths{intRecording}; %name of reference registration image path
        sRec = doPrePro(sRec);
        multiStruct.sRec(intRecording) = sRec;
        clear sRec;
    end
    
    %% do actual image processing & perform pixel responsiveness analysis
    for intRecording=vecRecordings
        fprintf('\nProceeding with image processing of recording %d... Please be patient, this could take a while.\n',intRecording)
        sRec = multiStruct.sRec(intRecording);
        sRec = doImagePrePro(sRec);
%         sRec = doCalcPixelResponsiveness(sRec);
        multiStructOut.sRec(intRecording) = sRec;
    end
    
end