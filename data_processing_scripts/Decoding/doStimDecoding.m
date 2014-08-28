function sOut = doStimDecoding(ses,sParams)
	%doStimDecoding Performs stimulus decoding of arbitrary stimulus types
	%				using getStimulusTypes.m
	%   Syntax: sOut = doStimDecoding(ses,sParams)
	%	Input:
	%	- ses; session structure (prepro output)
	%	- sParams; structure containing additional inputs. Fields are:
	%		- sTypes
	%		- cellSelect
	%		- vecIncludeCells
	%		- verbose
	%	Output:
	%	- sOut; output structure, containing fields:
	%		- cellVecPost; cell for each stimulus containing vector of
	%			stimulus posterior probabilities
	%		- vecDecodedStimType; vector containing decoded stimulus type
	%			for all stimuli (ML)
	%		- vecStimType; vector containing actual stimulus types
	%
	%Dependencies:
	% - getStimulusTypes.m
	% - getSelectionVectors.m
	% - getNeuronResponse.m
	% - buildStimDecodingLikelihood.m
	% - buildStimDecodingPosterior.m
	%
	%	Version history:
	%	1.0 - July 22 2013
	%	Created by Jorrit Montijn
	%	2.0 - May 19 2014
	%	Fixed likelihood & added pre-baseline removal [by JM]
	
	%pre-alloc
	sOut = struct;
	if nargin == 1, sParams = struct;end
	
	% get stim list
	if ~isfield(sParams,'sTypes'),sTypes = getStimulusTypes(ses);else sTypes = sParams.sTypes;end
	
	% get indexing vectors for unique stimulus combinations
	if ~isfield(sParams,'cellSelect'),cellSelect = getSelectionVectors(ses.structStim,sTypes);else cellSelect = sParams.cellSelect;end
	%get other inputs
	if ~isfield(sParams,'vecIncludeCells'),vecNeurons = 1:numel(ses.neuron);else vecNeurons = sParams.vecIncludeCells;end
	if ~isfield(sParams,'vecLikelihoodTrials'),vecLikelihoodTrials = [1:40];else vecLikelihoodTrials = sParams.vecLikelihoodTrials;end
	if ~isfield(sParams,'verbose'),verbose = 1;else verbose = sParams.verbose;end
	if ~isfield(sParams,'intPreBaselineRemoval'),intPreBaselineRemoval = [];else intPreBaselineRemoval = sParams.intPreBaselineRemoval;end
	
	%build likelihood
	structIn.ses = ses;
	structIn.sTypes = sTypes;
	structIn.cellSelect = cellSelect;
	structIn.vecLikelihoodTrials = vecLikelihoodTrials;
	structIn.intPreBaselineRemoval = intPreBaselineRemoval;
	matLikelihood = buildStimDecodingLikelihood(structIn);
	
	%get additional data
	intStims = length(cellSelect{1});
	vecStimTypes = nan(1,intStims);
	for intType=1:numel(cellSelect)
		vecStimTypes(cellSelect{intType}) = intType;
	end
	vecCorrect = nan(1,intStims);
	vecStims = 1:intStims;
	if ~isempty(vecLikelihoodTrials)
		if islogical(vecLikelihoodTrials)
			vecStims = vecStims(~vecLikelihoodTrials);
		else
			vecStims = vecStims(~ismember(vecStims,vecLikelihoodTrials));
		end
	end
	if isfield(sParams,'vecDecodeTrials'),vecStims = sParams.vecDecodeTrials;end
	if islogical(vecStims)
		vecDummy = 1:intStims;
		vecStims = vecDummy(vecStims);
	end
	
	%pre-allocate output
	cellVecPost = cell(1,intStims);
	vecDecodedStimType = nan(1,intStims);
	vecStimType = nan(1,intStims);
	
	%loop through stimuli
	for intStim=vecStims
		%get pop resp for this stimulus
		matResp = getNeuronResponse(ses,vecNeurons,intStim,intPreBaselineRemoval);
		if isempty(matResp),continue;end
		
		%posterior vars
		sInPost.matLikelihood = matLikelihood;
		sInPost.vecIncludeCells = vecNeurons;
		sInPost.matData = matResp;
		sInPost.ses = ses;
		
		%get posterior
		structPosterior = buildStimDecodingPosterior(sInPost);
		matPost = structPosterior.matPost;
		vecMeanPost = structPosterior.vecMeanPost;
		
		
		%% plot
		[dummy,intDecodedStimType] = max(vecMeanPost);
		
		%% output
		intStimType = vecStimTypes(intStim);
		if intStimType == intDecodedStimType
			strErr = '';
			vecCorrect(intStim) = true;
		else
			strErr = '; Incorrect';
			vecCorrect(intStim) = false;
		end
		cellVecPost{intStim} = vecMeanPost;
		vecDecodedStimType(intStim) = intDecodedStimType;
		vecStimType(intStim) = intStimType;
		
		%% message
		if verbose == 1,fprintf('Decoded stimulus %d of %d; decoded type=%d, actual type=%d%s\n',intStim,intStims,intDecodedStimType,intStimType,strErr);end
	end
	
	%put in output
	sOut.cellVecPost = cellVecPost;
	sOut.vecDecodedStimType = vecDecodedStimType;
	sOut.vecStimType = vecStimType;
	if verbose ~= 0,fprintf('\nDecoding performance: %d of %d [%.0f%%] correct\n',nansum(vecCorrect),length(vecStims),(nansum(vecCorrect)/length(vecStims))*100);end
end

