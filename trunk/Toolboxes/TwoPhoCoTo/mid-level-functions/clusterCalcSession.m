%function structOut = clusterCalcSession(strDir,strSession,vecClusterSize,varargin)
	%clusterCalcSession Calculates the mean covariances for all possible
	%clusters of a certain size for the cluster sizes listed in vecClusterSize
	%for a certain session
	%syntax: structOut = clusterCalcSession(strDir,strSession,vecClusterSize,[boolUseSpikes=0],[intIncludeCells=0],[boolDoPlotting=1])
	%	input:
	%	- strDir: string containing the target path
	%	- strSession: string containing the target session
	%	- vecClusterSize: a vector containing the cluster sizes to be used for
	%	  calculation
	%	- [boolUseSpikes: if 1, will use spiking data; if 0, will use dFoF data]
	%	- [intIncludeCells: if >0, will use a maximum of cells equal to this number]
	%	- [boolDoPlotting: if 1, plots graphs, otherwise doesn't]
	%	output:
	%	- structOut: structure with fields containing output information
	%	- Automatically calls plotClusters() and plotClusterDistance to make two graphs
	%
	%
	%Dependencies:
	% - defaultValues.m
	% - processActivityMatrix.m
	% - retrieveClusterCovar.m
	% - plotClusters.m
	%
	%	Version history:
	%	1.0 - April 18 2011
	%	Created by Jorrit Montijn
	%	1.0.1 - April 20 2011
	%	Put plotting in separate function [by JM]
	%	1.1 - April 21 2011
	%	Added cell exclusion [by JM]
	%	2.0 - September 13 2012
	%	Changed to compare difference during stimulus/baseline; adapted to work
	%	with new processActivityMatrix() function; included cell selection
	%	based on tuning parameters [by JM]
	
	%% Tags
	%#ok<*ASGLU>
	%#ok<*NASGU>
	
	%% Set default values
	if exist('stepsize','var')
		clear all
	end
	varargin=[];
	%[boolUseSpikes,intIncludeCells,boolDoPlotting] = defaultValues(varargin,false,0,true);
	if ~exist('boolUseSpikes','var') || isempty(boolUseSpikes)
		boolUseSpikes = false;
	end
	if ~exist('intIncludeCells','var') || isempty(intIncludeCells)
		intIncludeCells = 30;
	end
	if ~exist('boolDoPlotting','var') || isempty(boolDoPlotting)
		boolDoPlotting = true;
	end
	
	stepsize = 1/100;
	xVec = -1:stepsize:1;
	
	stepsizeDist = 1;
	xVecDist = 0:stepsizeDist:300;
	
	%% load session
	if ~exist('vecClusterSize','var') || isempty(vecClusterSize)
		vecClusterSize=2:6;
	end
	if ~exist('strDir','var') || isempty(strDir)
		strDir = 'F:\Processed\imagingdata\20120718\xyt01\';
	end
	if ~exist('strSession','var') || isempty(strSession)
		strSession = '20120718xyt01_ses.mat';
	end
	load([strDir strSession]);
	
	%% define output directory
	strOutDir=res2proc(ses.strImPath);
	oldDir = pwd;
	try
		cd(strOutDir);
	catch
		mkdir(strOutDir);
	end
	cd(oldDir);
	
	%% calc tuning
	verbose = true;
	doPlot = false;
	structOutput = calcTuningSession(ses,verbose,doPlot);
	
	%% select cells
	if intIncludeCells == 0
		vecCells = 0;
	else
		matTuningParams = structOutput.matTuningParams;
		vecTuned = 	structOutput.vecDirTuned |	structOutput.vecOriTuned;
		vecMSE = matTuningParams(5,:);
		[vecVals,vecCells] = findmin(vecMSE,intIncludeCells);
	end
	
	%% retrieve stimulus frames + baseline frames
	intStimDur = ses.structStim.FrameOff(1) - ses.structStim.FrameOn(1);
	intBaseDur = ses.structStim.FrameOn(2) - ses.structStim.FrameOff(1);
	vecStimStart = ses.structStim.FrameOn;
	vecBaseStart = ses.structStim.FrameOff;
	
	%% Retrieve correlation matrix for stimulus frames
	structCorrStim = processActivityMatrix(ses,boolUseSpikes,[],vecStimStart,intStimDur,vecCells);
	matEpochStim = structCorrStim.matEpoch;
	matCovarDataStim = structCorrStim.matCovarData;
	intCellsStim = structCorrStim.intCells;
	matDistances = structCorrStim.matDistances;
	matRawCovar = structCorrStim.matRawCovar;
	matRawCovarStim = mean(matRawCovar,3);
	
	%% retrieve correlation matrix for baseline frames
	structCorrBase = processActivityMatrix(ses,boolUseSpikes,[],vecBaseStart,intBaseDur,vecCells);
	matEpochBase = structCorrBase.matEpoch;
	matCovarDataBase = structCorrBase.matCovarData;
	intCellsBase = structCorrBase.intCells;
	matRawCovar = structCorrBase.matRawCovar;
	matRawCovarBase = mean(matRawCovar,3);
	
	
	%% Pre-allocate variables FOR BOTH STIM AND BASE
	matOutStim = nan(length(xVec),length(vecClusterSize));
	matOutStimNorm = nan(length(xVec),length(vecClusterSize));
	matDistStim = nan(length(xVecDist),length(vecClusterSize));
	matDistWeightStim = nan(length(xVecDist),length(vecClusterSize));
	dblMeanStim = mean(matRawCovarStim(:));
	
	matOutBase = nan(length(xVec),length(vecClusterSize));
	matOutBaseNorm = nan(length(xVec),length(vecClusterSize));
	matDistBase = nan(length(xVecDist),length(vecClusterSize));
	matDistWeightBase = nan(length(xVecDist),length(vecClusterSize));
	dblMeanBase = mean(matRawCovarBase(:));
	
	%% Loop through cluster sizes FOR BOTH STIM AND BASE
	for intClustIndex=1:length(vecClusterSize)
		intClusterSize = vecClusterSize(intClustIndex);
		fprintf('Starting with cluster size of %d...\n',intClusterSize);
		%% stim
		%retrieve binned cluster covariances
		[nVec,vecDist,vecDistWeight] = retrieveClusterCovar(xVec,xVecDist,matRawCovarStim,matDistances,intClusterSize);
		nVec = double(nVec);
		vecDist = double(vecDist);
		vecDistWeight = double(vecDistWeight);
		
		%transform to fraction of maximum
		maxCount = max(nVec);
		nVecNorm = nVec / maxCount;
		matOutStimNorm(:,intClustIndex) = nVecNorm;
		matOutStim(:,intClustIndex) = nVec;
		
		%distance
		matDistStim(:,intClustIndex) = vecDist;
		matDistWeightStim(:,intClustIndex) = vecDistWeight;
		
		%% base
		%retrieve binned cluster covariances
		[nVec,vecDist,vecDistWeight] = retrieveClusterCovar(xVec,xVecDist,matRawCovarBase,matDistances,intClusterSize);
		nVec = double(nVec);
		vecDist = double(vecDist);
		vecDistWeight = double(vecDistWeight);
		
		%transform to fraction of maximum
		maxCount = max(nVec);
		nVecNorm = nVec / maxCount;
		matOutBaseNorm(:,intClustIndex) = nVecNorm;
		matOutBase(:,intClustIndex) = nVec;
		
		%distance
		matDistBase(:,intClustIndex) = vecDist;
		matDistWeightBase(:,intClustIndex) = vecDistWeight;
		
		%% save
		%save data after every run
		save([strOutDir  'clusterData' ses.session '_' num2str(intCellsStim) 'cells_' num2str(vecClusterSize(1)) '-' num2str(intClusterSize) '.mat'],'matOutStim','matOutStimNorm','dblMeanStim','matDistStim','matDistWeightStim','matOutBase','matOutBaseNorm','dblMeanBase','matDistBase','matDistWeightBase')
	end
	matOutBaseLogNorm = log(matOutBaseNorm);
	matOutStimLogNorm = log(matOutStimNorm);
	
	%% output
	structOut = struct;
	structOut.matOutStim = matOutStim;
	structOut.matOutStimNorm = matOutStimNorm;
	structOut.dblMeanStim = dblMeanStim;
	structOut.matDistStim = matDistStim;
	structOut.matDistWeightStim = matDistWeightStim;
	structOut.matOutBase = matOutBase;
	structOut.matOutBaseNorm = matOutBaseNorm;
	structOut.dblMeanBase = dblMeanBase;
	structOut.matDistBase = matDistBase;
	structOut.matDistWeightBase = matDistWeightBase;
	structOut.matOutBaseLogNorm = matOutBaseLogNorm;
	structOut.matOutStimLogNorm = matOutStimLogNorm;
	
	%% Plot output
	if boolDoPlotting && intClustIndex > 1
		matOutDiff = ((matOutStim - matOutBase) ./ (matOutStim + matOutBase)) * 100;
		matDistDiff = ((matDistStim - matDistBase) ./ (matDistStim + matDistBase)) * 100;
		
		close all
		%baseline
		plotClusters(matOutBaseLogNorm,'Normalized amount of clusters during no stimulus');
		plotClusterDistance(matDistBase,'correlation during no stimulus');
		
		%stimulus
		plotClusters(matOutStimLogNorm,'Normalized amount of clusters during stimulus');
		plotClusterDistance(matDistStim,'correlation during stimulus');
		
		%diff
		plotClusters(matOutDiff,'% increase in number of clusters per bin (Z) from baseline to stimulus presentation (high is more during stim)');
		plotClusterDistance(matDistDiff,'% increase in correlation during stimulus presentation compared to no stimulus');
	end
%end

