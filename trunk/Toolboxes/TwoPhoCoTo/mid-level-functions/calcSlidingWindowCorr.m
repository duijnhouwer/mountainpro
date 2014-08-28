function structOut = calcSlidingWindowCorr(ses,structParams)
	%calcSlidingWindowCorr Makes a sliding window
%   syntax: structOut = calcSlidingWindowCorr(ses,structParams)
%		structOut fields:
%		- matCorr [one vector containing corr vals for all pairs per window]
%		- vecMeanCorr
%		- vecStdCorr
%		- matDistributionCorr
%		- hmRawCorr [only assigned if intWindows < 100]
%
%		structParams fields:
%		- intStartFrame [first frame of first window]
%		- intWindowSize [nr of frames/window]
%		- intWindows [nr of windows]
%		(- vecDistribution [vector containing edges for binning])
%		(- structParamsProcessActivityMatrix [optional: contains fields
%			that set parameters of the processActivityMatrix subfunction])
%
%	Version history:
%	2.0 - Nov 27 2012
%	Created by Jorrit Montijn

	%% assign variables
	%data
	intNeurons = numel(ses.neuron);
	intFrames = ses.size.t;
	
	%in
	intStartFrame = structParams.intStartFrame;
	intWindowSize = structParams.intWindowSize;
	intWindows = structParams.intWindows;
	if isfield(structParams,'vecDistribution'), vecDistribution = structParams.vecDistribution;else vecDistribution=-1:0.01:1;end
	if isfield(structParams,'structParamsProcessActivityMatrix'), structSubParams = structParams.structParamsProcessActivityMatrix;else structSubParams=struct;end
	if intWindows == 0
		maxStart = intFrames - intWindowSize - 1;
	else
		maxStart = intStartFrame + intWindows - 1;
	end
	structSubParams.vecEpochStart = intStartFrame:maxStart;
	structSubParams.intEpochDuration = intWindowSize;
	
	%out
	structOut = struct;
	structOut.vecMeanCorr = nan(1,intWindows);
	structOut.vecStdCorr = nan(1,intWindows);
	matDistributionCorr = nan(length(vecDistribution),intWindows);
	structOut.hmRawCorr = nan(intNeurons,intNeurons,intWindows);
	
	%% perform calculation
	structCorrOut = processActivityMatrix(ses,structSubParams);
	
	%rename matrix
	hmRawCorr=structCorrOut.matRawCovar;

	if size(hmRawCorr,3) ~= intWindows
		if intWindows ~= 0
			warning([mfilename ':WindowNumber'],'Number of windows should be %d, but it''s actually %d',intWindows,size(hmRawCorr,3))
		end
		intWindows = size(hmRawCorr,3);
	end
	
	%put 2d pairwise correlation matrix in a single vector to allow efficient targeting of single windows
	matCorr=squeeze(reshape(hmRawCorr,1,intNeurons*intNeurons,intWindows));
	structOut.matCorr = matCorr;
	structOut.vecStdCorr = std(matCorr,[],2);
	structOut.vecMeanCorr = mean(matCorr,2);
	structOut.hmRawCorr = hmRawCorr;
	
	%loop through windows for distributions
	for intWindow=1:intWindows
		matDistributionCorr(:,intWindow) = histc(matCorr(:,intWindow),vecDistribution);
	end
	
	%assign to structOut
	structOut.matDistributionCorr = matDistributionCorr;
end