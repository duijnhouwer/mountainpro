function sOut = doTraceDecoding(ses,sParams)
	%UNTITLED4 Summary of this function goes here
	%   Detailed explanation goes here
	%dependencies:
	%getStimulusTypes.m
	%getSelectionVectors.m
	
	%pre-alloc
	sOut = struct;
	if nargin == 1, sParams = struct;end
	
	% get stim list
	if ~isfield(sParams,'sTypes'),sTypes = getStimulusTypes(ses);else sTypes = sParams.sTypes;end
	matTypes = sTypes.matTypes;
	vecNumTypes = sTypes.vecNumTypes;
	cellNames = sTypes.cellNames;
	
	% get indexing vectors for unique stimulus combinations
	if ~isfield(sParams,'cellSelect'),cellSelect = getSelectionVectors(ses.structStim,sTypes);else cellSelect = sParams.cellSelect;end
	
	%get required window length
	if ~isfield(sParams,'intWindowLength'),intWindowLength = round(ses.samplingFreq);else intWindowLength = sParams.intWindowLength;end
	
	%get which trials to sue for likelihood
	if ~isfield(sParams,'vecLikelihoodTrials'),vecLikelihoodTrials = [];else vecLikelihoodTrials = sParams.vecLikelihoodTrials;end
	
	%get boolean switch for using baseline as additional type
	if ~isfield(sParams,'boolUseBaseline'),boolUseBaseline = true;else boolUseBaseline = sParams.boolUseBaseline;end
	
	%build likelihood
	structIn.ses = ses;
	structIn.sTypes = sTypes;
	structIn.cellSelect = cellSelect;
	structIn.vecLikelihoodTrials = vecLikelihoodTrials;
	structIn.boolUseBaseline = boolUseBaseline;
	matLikelihood = buildTraceLikelihood(structIn);
	
	%get additional data
	vecNeurons = 1:numel(ses.neuron);
	intStimTypes = length(cellSelect);
	intFrames = length(ses.neuron(1).dFoF);
	intStopFrame = intFrames - intWindowLength + 1;
	matOut = nan(intStimTypes+boolUseBaseline,intFrames);
	
	%msg
	fprintf('\nStarting trace decoding of session %s%s\n',ses.session,ses.recording)
	ptrTime = tic;
	%loop through stimuli
	for intFrame=1:intStopFrame
		%get pop resp for this stimulus
		vecFrames = intFrame:(intFrame+intWindowLength-1);
		vecPopResp = getNeuronFrameResponse(ses,vecNeurons,vecFrames);
		
		%posterior vars
		sInPost.matLikelihood = matLikelihood;
		sInPost.vecIncludeCells = vecNeurons;
		sInPost.matData = vecPopResp;
		sInPost.ses = ses;
		
		%get posterior
		structPosterior = buildStimDecodingPosterior(sInPost);
		vecMeanPost = structPosterior.vecMeanPost;
		
		% output
		matOut(:,intFrame+floor(intWindowLength/2)) = vecMeanPost';
		
		% message
		if mod(intFrame,1000) == 0
			fprintf('Now at frame %d of %d\n',intFrame,intStopFrame)
		end
	end
	
	%remove nans
	vecNan = find(isnan(sum(matOut,1)));
	matOut(:,vecNan) = zeros(size(matOut,1),length(vecNan));
	matOut(end,vecNan) = eps;
	
	%msg
	fprintf('Trace decoding completed. Calculation took %.1f seconds\n',toc(ptrTime));
	
	% output
	[dummy,sOut.vecDecodedType] = max(matOut,[],1); %#ok<ASGLU>
	sOut.vecStimType = getStimTrace(ses);
	sOut.matDecoding = matOut;
	sOut.intWindowLength = intWindowLength;
	sOut.sTypes = sTypes;
	sOut.cellSelect = cellSelect;
	sOut.ses = ses;
end



