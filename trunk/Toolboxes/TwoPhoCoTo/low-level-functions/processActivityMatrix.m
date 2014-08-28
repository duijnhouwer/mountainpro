function structCorrelation = processActivityMatrix(ses,varargin)
	%processActivityMatrix Calculates correlations from the data of a
	%pre-processed session. Outputs correlations and session information.
	%syntax: [structCorrelation] = processActivityMatrix(ses,[structParams/boolUseSpikes=0],[intReqBinDuration=1],[vecEpochStart=10],[intEpochDuration=190],[intIncludeCells=0],[boolDisplayWarnings=0])
	%	input:
	%	- ses: structure containing session information (prepro output)
	%	- [boolUseSpikes: 1; use spiking data, 0; use dFoF data]
	%	- [intReqBinDuration: bin size in frames]
	%	- [vecEpochStart: start frame of epoch]
	%	- [intEpochDuration: epoch duration in frames]
	%	- [intIncludeCells: takes this number of cells that have the lowest
	%		residuals after subtraction of the exponential fits from the raw
	%		data. If the supplied argument is a vector, it is assumed to
	%		contain the cell IDs of the neurons you want to include]
	%	- [boolDisplayWarnings: if 0, don't display warnings; if 1, do]
	%
	%	Alternative input:
	%	- [structParams: the aforementioned variables can be defined as
	%	fields in the structParams structure]
	%
	%	output:
	%	- structCorrelation: a structure containing the following fields:
	%		- matEpoch: matrix containing raw dFoF data on which analysis is performed
	%		- matCovarData: matrix containing information on every neuronal pair
	%			matCovarData(1,pairNumber): correlation
	%			matCovarData(2,pairNumber): index of cell 1
	%			matCovarData(3,pairNumber): index of cell 2
	%			matCovarData(4,pairNumber): X location of cell 1
	%			matCovarData(5,pairNumber): Y location of cell 1
	%			matCovarData(6,pairNumber): X location of cell 2
	%			matCovarData(7,pairNumber): Y location of cell 2
	%			matCovarData(8,pairNumber): distance between cells (sqrt(x^2+y^2))
	%		- intCells: number of cells processed
	%		- matDistances: nCells by nCells matrix containing spatial distances
	%		- matRawCovar: nCells by nCells by nEpochs matrix containing correlations
	%		- dblActEpochDuration: actual duration of epoch
	%		- matEpoch: nCells by nEpochBins by nEpochs matrix containing activity data (not yet z-transformed)
	%		- vecStart: vector containing bin numbers where epochs begin
	%		- vecStop: vector containing bin numbers where epochs end
	%		- intMax: total number of bins in binned activity data matrix
	%		- dblAnesth: anesthesia level
	%		- matRawCovarOverall: mean correlation over whole data set (if nEpochs=1, this is identical to matRawCovar)
	%		- dblActBinDuration: actual duration of one bin
	%
	%Dependencies:
	% - defaultValues.m
	% - zscore.m
	% - findmin.m
	% - calc_dFoF.m
	% - calc_ExpFit.m
	%
	%	Version history:
	%	1.0 - April 15 2011
	%	Created by Jorrit Montijn
	%	1.1 - April 21 2011
	%	Added cell exclusion [by JM]
	%	1.1.1 - May 10 2011
	%	Added some extra output variables [by JM]
	%	1.2 - September 8 2011
	%	Added vector support for multiple epoch starts [by JM]
	%	1.3 - October 18 2011
	%	Added vector support for intIncludeCells [by JM]
	%	Removed need for activity pre-processing [by JM]
	%	1.4 - December 13 2011
	%	Added on-the-fly dFoF calculation if data are missing [by JM]
	%	1.5 - April 12 2012
	%	Added on-the-fly ExpFit calculation if data are missing [by JM]
	%	2.0 - September 13 2012
	%	Redefined output to be in structure-field format; and input to be
	%	pre-loaded session file instead of path-file pair; switched epoch
	%	input definitions to be in frames instead of seconds [by JM]
	%	2.1 - November 27 2012
	%	Added support for structure-based input [by JM]
	%	2.2 - February 19 2013
	%	Added extra optional input parameters [by JM]
	%	2.3 - July 29 2013
	%	Vectorized loop for multi-epoch correlation calculation (now
	%	performs calculation 114.5263 times faster) [by JM] 
	
	%% Tags
	%#ok<*ASGLU>
	
	%% assign default values
	if nargin > 1 && isstruct(varargin{1})
		if isfield(varargin{1},'boolUseSpikes'),boolUseSpikes=varargin{1}.boolUseSpikes;else boolUseSpikes=false;end
		if isfield(varargin{1},'intReqBinDuration'),intReqBinDuration=varargin{1}.intReqBinDuration;else intReqBinDuration=1;end
		if isfield(varargin{1},'vecEpochStart'),vecEpochStart=varargin{1}.vecEpochStart;else vecEpochStart=1;end
		if isfield(varargin{1},'intEpochDuration'),intEpochDuration=varargin{1}.intEpochDuration;else intEpochDuration=inf;end
		if isfield(varargin{1},'intIncludeCells'),intIncludeCells=varargin{1}.intIncludeCells;else intIncludeCells=0;end
		if isfield(varargin{1},'boolDisplayWarnings'),boolDisplayWarnings=varargin{1}.boolDisplayWarnings;else boolDisplayWarnings=false;end
		if isfield(varargin{1},'boolNanDiag'),boolNanDiag=varargin{1}.boolNanDiag;else boolNanDiag=false;end
	else
		[boolUseSpikes,intReqBinDuration,vecEpochStart,intEpochDuration,intIncludeCells,boolDisplayWarnings,boolNanDiag] = defaultValues(varargin,false,1,1,inf,0,0,false);
	end
	
	%% define and load data
	if isfield(ses,'info') && isfield(ses,'anesth') && isfield(ses,'nObj')
		intFileFormat = 1;
	elseif isfield(ses,'neuron')
		intFileFormat = 2;
	end
		
	%% retrieve information
	if intFileFormat == 1
		%file has old formatting scheme
		intFrames = length(ses.Fch1);
		intNeurons = ses.nNeuron;
		
		matActivity = zeros(intNeurons,intFrames);
		dblSampleRate = ses.info.samplingRate; %Hz
		dblAnesth = ses.anesth; %anesthesia level (% isoflurane)
		dblFrameDuration = 1/dblSampleRate; %seconds
		matCellExpFit = zeros(size(matActivity));
		
		intObjNum = ses.nObj;
		vecCellLocX = zeros(1,intNeurons);
		vecCellLocY = zeros(1,intNeurons);
		intNeuron = 0;
		for i=1:intObjNum
			if ses.cells(i).type == 1
				%is a neuron
				intNeuron = intNeuron + 1;
				if boolUseSpikes
					vecActionPotentialFrames = ses.cells(i).apFrames;
					vecActionPotentialNumbers = ses.cells(i).apSpikes;
					if ~isempty(vecActionPotentialFrames)
						matActivity(intNeuron,vecActionPotentialFrames) = vecActionPotentialNumbers;
					end
				else
					matActivity(intNeuron,:) = ses.cells(i).dFoF;
				end
				matCellExpFit(intNeuron,:) = ses.cells(i).expFit;
				vecCellLocX(intNeuron) = ses.cells(i).centroids.X;
				vecCellLocY(intNeuron) = ses.cells(i).centroids.Y;
			end
		end
	elseif intFileFormat == 2
		%file has new formatting scheme
		intFrames = length(ses.neuron(1).dFoF);
		intNeurons = numel(ses.neuron);
		
		matActivity = zeros(intNeurons,intFrames);
		dblSampleRate = ses.samplingFreq; %Hz
		dblAnesth = ses.anesthesia; %anesthesia level (% isoflurane)
		dblFrameDuration = 1/dblSampleRate; %seconds
		
		%check if exp fits has been done
		boolUseExp = false;%~isempty(ses.neuron(end).expFit);
		
		vecCellLocX = zeros(1,intNeurons);
		vecCellLocY = zeros(1,intNeurons);
		for intNeuron=1:intNeurons
			if boolUseSpikes
				vecActionPotentialFrames = ses.neuron(intNeuron).apFrames;
				vecActionPotentialNumbers = ses.neuron(intNeuron).apSpikes;
				if ~isempty(vecActionPotentialFrames)
					matActivity(intNeuron,vecActionPotentialFrames) = vecActionPotentialNumbers;
				end
			else
				matActivity(intNeuron,:) = ses.neuron(intNeuron).dFoF;
			end
			if boolUseExp
				ses.neuron(intNeuron).expFit
				
				matCellExpFit(intNeuron,:)
				
				matCellExpFit(intNeuron,:) = ses.neuron(intNeuron).expFit
			end
			vecCellLocX(intNeuron) = ses.neuron(intNeuron).x;
			vecCellLocY(intNeuron) = ses.neuron(intNeuron).y;
		end
	else
		error('processActivityMatrix:RetrieveInformation','Unknown file format for file %s in %s',strSession,strDir);
	end
	if isfield(ses,'xml')
		dblMicronSize = ses.xml.dblActualImageSizeX;
		intPixelSize = ses.xml.intImageSizeX;
		pix2micron = dblMicronSize/intPixelSize;
	else
		pix2micron = 1;
	end
	
	%% apply binning
	if intReqBinDuration > 0
		intActBinSize = intReqBinDuration;
		dblActBinDurationSecs = dblFrameDuration*intActBinSize;
		matBinned = compressMatrix(matActivity,intActBinSize,'binsize');
		if boolUseExp
			matExpBinned = compressMatrix(matCellExpFit,intActBinSize,'binsize');
		end
	else
		intActBinSize = 1;
		dblActBinDurationSecs = dblFrameDuration;
		matBinned = matActivity;
		if boolUseExp
			matExpBinned = matCellExpFit;
		end
	end
	vecEpochStartBins = round(vecEpochStart/intActBinSize);
	intEpochDurationBins = round(intEpochDuration/intActBinSize);
	
	%% define usable part of input
	intEpochStart = vecEpochStartBins(1);
	intStart = max(1,intEpochStart);
	intMax = size(matBinned,2);
	intStop = min(intStart + intEpochDurationBins - 1,intMax);
	intActEpochBins = intStop-intStart+1;
	dblActEpochSecs = intActEpochBins*dblActBinDurationSecs;
	if length(vecEpochStartBins) > 1 %take whole data set
		matEpoch = matBinned(:,intStart:intMax);
		if boolUseExp
			matEpochExpFit = matExpBinned(:,intStart:intMax);
		end
	else
		matEpoch = matBinned(:,intStart:intStop);
		if boolUseExp
			matEpochExpFit = matExpBinned(:,intStart:intStop);
		end
	end
	vecStart = intStart;
	vecStop = intStop;
	vecEpochStartBins = vecEpochStartBins(vecEpochStartBins < (size(matEpoch,2)));
	
	%% remove cells with high residuals after spike fitting
	if intIncludeCells(1) > 0
		if length(intIncludeCells) > 1
			%include supplied list; discard rest
			matEpoch = matEpoch(intIncludeCells,:);
		else
			if boolUseExp
				%take best cells
				vecResid = sum(abs(matEpoch-matEpochExpFit),2); %per cell, take the sum of the absolute difference between the fit and actual data
				
				[vecR,vecI] = findmin(vecResid,intIncludeCells); %find the lowest values
				matEpoch = matEpoch(vecI,:); %take only these cells
			else
				error('processActivityMatrix:NoExpFit','No exponential fitting has been performed; impossible to select cells')
			end
		end
	end
	
	if length(vecEpochStartBins) > 1
		%% make z-transformed matrix of whole series
		matZ = zscore(matEpoch);
		N = size(matZ,2) ;
		
		%% calculate correlations per cell of whole series
		dblMaxVal = 1;
		intCells = size(matZ,1);
		if boolNanDiag
			matDistances = nan(intCells,intCells);
			matRawCovarOverall = nan(intCells,intCells);
			matCovarData = nan(8,floor((intCells*intCells)/2)-intCells);
		else
			matDistances = zeros(intCells,intCells);
			matRawCovarOverall = zeros(intCells,intCells);
			matCovarData = zeros(8,floor((intCells*intCells)/2)-intCells);
		end
		intIndex = 0;
		for intCell1=1:intCells
			for intCell2=(intCell1+1):intCells
				dblCorrelation = mean(matZ(intCell1,:).*matZ(intCell2,:));
				dblCorrelation = dblCorrelation * N/(N-1) ;   % correction factor !!
	
				dblCell1LocX = vecCellLocX(intCell1);
				dblCell1LocY = vecCellLocY(intCell1);
				dblCell2LocX = vecCellLocX(intCell2);
				dblCell2LocY = vecCellLocY(intCell2);
				xDist = abs(dblCell1LocX - dblCell2LocX);
				yDist = abs(dblCell1LocY - dblCell2LocY);
				dblCellDist = sqrt(xDist^2+yDist^2)*pix2micron;
				if intCell1 ~= intCell2
					intIndex = intIndex + 1;
					
					matCovarData(1,intIndex) = dblCorrelation;
					matCovarData(2,intIndex) = intCell1;
					matCovarData(3,intIndex) = intCell2;
					matCovarData(4,intIndex) = dblCell1LocX;
					matCovarData(5,intIndex) = dblCell1LocY;
					matCovarData(6,intIndex) = dblCell2LocX;
					matCovarData(7,intIndex) = dblCell2LocY;
					matCovarData(8,intIndex) = dblCellDist;
					
					if dblCorrelation <= 0.001 && dblCorrelation >= -0.001 && boolDisplayWarnings
						fprintf('ZERO: correlation between cell %d and %d is %d\n',intCell1,intCell2,dblCorrelation);
					elseif dblCorrelation >= dblMaxVal && boolDisplayWarnings
						fprintf('MAX: correlation between cell %d and %d is maximum (%d)\n',intCell1,intCell2,dblCorrelation);
					end
				end
				matDistances(intCell1,intCell2) = dblCellDist;
				matDistances(intCell2,intCell1) = dblCellDist;
				
				matRawCovarOverall(intCell1,intCell2) = dblCorrelation;
				matRawCovarOverall(intCell2,intCell1) = dblCorrelation;
			end
		end
		
		%% make multidimensional correlation matrix with 2D matrix per epoch
		intIncrement = intActEpochBins;
		matRawCovar = zeros(intCells,intCells,length(vecEpochStartBins));
		matEpochOut = zeros(intCells,intIncrement,length(vecEpochStartBins));
		
		intEpochs = length(vecEpochStartBins);
		vecStart = nan(1,intEpochs);
		vecStop = nan(1,intEpochs);
		for intNumEpoch=1:length(vecEpochStartBins)
			%% retrieve epoch
			intEpochStart = vecEpochStartBins(intNumEpoch);
			intStart = max(1,intEpochStart);
			intStop = intStart + intIncrement - 1;
			intMax = size(matEpoch,2);
			if intStop > intMax
				break;
			end
			vecStart(intNumEpoch) = intStart;
			vecStop(intNumEpoch) = intStop;
			
			matEpochC = matEpoch(:,intStart:intStop);
			matEpochOut(:,:,intNumEpoch) = matEpochC;
			
			%% calculate correlations per cell
			matEpochC = shiftdim(matEpochC,1);
			matRawCovar(:,:,intNumEpoch) = corr(matEpochC);
			if boolNanDiag
				matRawCovar(diag(diag(true(intNeurons,intNeurons),0))) = nan;
			else
				matRawCovar(diag(diag(true(intNeurons,intNeurons),0))) = 0;
			end
		end
	else
		%% make z-transformed matrix
		matZ = zscore(matEpoch);
		N = size(matZ,2) ;
		
		%% make output
		matEpochOut = matEpoch;
		
		%% calculate correlations per cell
		dblMaxVal = 1;
		intCells = size(matZ,1);
		if boolNanDiag
			matRawCovar = nan(intCells,intCells);
			matDistances = nan(intCells,intCells);
			matCovarData = nan(8,floor((intCells*intCells)/2)-intCells);
		else
			matRawCovar = zeros(intCells,intCells);
			matDistances = zeros(intCells,intCells);
			matCovarData = zeros(8,floor((intCells*intCells)/2)-intCells);
		end
		
		intIndex = 0;
		for intCell1=1:intCells
			for intCell2=(intCell1+1):intCells
				dblCorrelation = mean(matZ(intCell1,:).*matZ(intCell2,:));
				dblCorrelation = dblCorrelation * N/(N-1) ;   % correction factor !!
				
				dblCell1LocX = vecCellLocX(intCell1);
				dblCell1LocY = vecCellLocY(intCell1);
				dblCell2LocX = vecCellLocX(intCell2);
				dblCell2LocY = vecCellLocY(intCell2);
				xDist = abs(dblCell1LocX - dblCell2LocX);
				yDist = abs(dblCell1LocY - dblCell2LocY);
				dblCellDist = sqrt(xDist^2+yDist^2)*pix2micron;
				if intCell1 ~= intCell2
					intIndex = intIndex + 1;
					
					matCovarData(1,intIndex) = dblCorrelation;
					matCovarData(2,intIndex) = intCell1;
					matCovarData(3,intIndex) = intCell2;
					matCovarData(4,intIndex) = dblCell1LocX;
					matCovarData(5,intIndex) = dblCell1LocY;
					matCovarData(6,intIndex) = dblCell2LocX;
					matCovarData(7,intIndex) = dblCell2LocY;
					matCovarData(8,intIndex) = dblCellDist;
					
					if dblCorrelation <= 0.001 && dblCorrelation >= -0.001 && boolDisplayWarnings
						fprintf('ZERO: correlation between cell %d and %d is %d\n',intCell1,intCell2,dblCorrelation);
					elseif dblCorrelation >= dblMaxVal && boolDisplayWarnings
						fprintf('MAX: correlation between cell %d and %d is maximum (%d)\n',intCell1,intCell2,dblCorrelation);
					end
				end
				matDistances(intCell1,intCell2) = dblCellDist;
				matDistances(intCell2,intCell1) = dblCellDist;
				
				matRawCovar(intCell1,intCell2) = dblCorrelation;
				matRawCovar(intCell2,intCell1) = dblCorrelation;
			end
		end
		matRawCovarOverall = matRawCovar;
	end
	%% put all required variables in output structure
	structCorrelation = struct;
	structCorrelation.matEpoch = matEpoch;
	structCorrelation.matCovarData = matCovarData;
	structCorrelation.intCells = intCells;
	structCorrelation.matDistances = matDistances;
	structCorrelation.matRawCovar = matRawCovar;
	structCorrelation.dblActEpochSecs = dblActEpochSecs;
	structCorrelation.matEpochOut = matEpochOut;
	structCorrelation.vecStart = vecStart(~isnan(vecStart));
	structCorrelation.vecStop = vecStop(~isnan(vecStop));
	structCorrelation.intMax = intMax;
	structCorrelation.dblAnesth = dblAnesth;
	structCorrelation.matRawCovarOverall = matRawCovarOverall;
	structCorrelation.dblActBinDurationSecs = dblActBinDurationSecs;
	structCorrelation.vecEpochStartBins = vecEpochStartBins;
	structCorrelation.intEpochDuration = intEpochDuration;
end