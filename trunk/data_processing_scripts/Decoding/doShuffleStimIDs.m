function ses = doShuffleStimIDs(ses,vecShuffle)
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	
	%field list
	if ~exist('cellFields','var')
		cellFields{1} = 'Orientation';
		cellFields{2} = 'Contrast';
		cellFields{3} = 'SpatialFrequency';
	end
	
	%get shuffle vector
	if ~exist('vecShuffle','var') || isempty(vecShuffle)
		intStims = length(ses.structStim.FrameOn);
		vecShuffle = randperm(intStims);
	end
	
	%shuffle
	for intField = 1:length(cellFields)
		strField = cellFields{intField};
		if isfield(ses.structStim,strField)
			ses.structStim.(strField) = ses.structStim.(strField)(vecShuffle);
		end
	end
end

