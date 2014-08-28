function matLikelihood = buildStimDecodingLikelihood(structIn)
	%buildStimDecodingLikelihood Build Bayesian likelihood for supplied session
	%	Syntax: structOut = buildDecodingLikelihood(structIn)
	%   Input: structIn, a structure containing the following fields:
	%	- ses, session data
	%	- sTypes, output of getStimulusTypes()
	%	- cellSelect, output of getSelectionVectors()
	%	Optional fields are:
	%	- vecIncludeCells, vector of cells to include in analysis; [Default: all]
	%	- vecIgnoreTrial, vector trials to ignore; [Default: none]
	%	Output: 
	%	- matLikelihood, 3D matrix containing distribution parameters of likelihood function:
	%		matLikelihood(intNeuron,intStimType,intParameter)
	%		Parameter data for Gaussian is:
	%		- intParameter == 1; mean response
	%		- intParameter == 2; std response
	%
	%Dependencies:
	% - getNeuronResponse.m
	%
	%	Version history:
	%	1.0 - July 22 2013
	%	Created by Jorrit Montijn
	%	2.0 - May 19 2014
	%	Fixed likelihood & added pre-baseline removal [by JM]
	
	%% define input variables
	ses = structIn.ses;
	sTypes = structIn.sTypes;
	matTypes = sTypes.matTypes;
	cellSelect = structIn.cellSelect;
	intNeurons = numel(ses.neuron);
	if ~isfield(structIn,'vecIncludeCells') || isempty(structIn.vecIncludeCells), vecIncludeCells = 1:intNeurons;else vecIncludeCells = structIn.vecIncludeCells;end
	if ~isfield(structIn,'vecLikelihoodTrials') || isempty(structIn.vecLikelihoodTrials), vecLikelihoodTrials = [];else vecLikelihoodTrials = structIn.vecLikelihoodTrials;end
	if ~isfield(structIn,'intPreBaselineRemoval') || isempty(structIn.intPreBaselineRemoval), intPreBaselineRemoval = [];else intPreBaselineRemoval = structIn.intPreBaselineRemoval;end
	
	
	%% pre-allocate variables
	%approximate every stimulus response separately with normal distribution
	intParams = 2;
	intTypes = size(matTypes,2);
	matLikelihood = nan(intNeurons,intTypes,intParams);
	
	%% build likelihood lookup table
	% pre-allocate
	if isempty(vecLikelihoodTrials)
		vecLikelihoodTrials = true(1,length(ses.structStim.FrameOn));
	elseif ~islogical(vecLikelihoodTrials)
		vecTemp = false(1,length(ses.structStim.FrameOn));
		vecTemp(vecLikelihoodTrials) = true;
		vecLikelihoodTrials = vecTemp;
	elseif length(vecLikelihoodTrials) ~= length(ses.structStim.FrameOn)
		error([mfilename ':IncorrectLength'],'Length of vecLikelihoodTrials [%d] is incompatible with number of stimuli [%d]',length(vecLikelihoodTrials),length(ses.structStim.FrameOn));
	end
	vecStimTypeIndex = 1:intTypes;
	
	% loop through stim types
	for intStimType=vecStimTypeIndex
		vecStims = cellSelect{intStimType} & vecLikelihoodTrials;
		matResp = getNeuronResponse(ses,vecIncludeCells,vecStims,intPreBaselineRemoval);
		matLikelihood(vecIncludeCells,intStimType,1) = mean(matResp,2);
		matLikelihood(vecIncludeCells,intStimType,2) = std(matResp,0,2);
	end
end

