function matLikelihood = buildTraceLikelihood(structIn)
	%buildTraceLikelihood Build Bayesian likelihood for supplied session
	%	Syntax: matLikelihood = buildTraceLikelihood(structIn)
	%   Input: structIn, a structure containing the following fields:
	%	- ses, session data
	%	- sTypes, output of getStimulusTypes()
	%	- cellSelect, output of getSelectionVectors()
	%	Optional fields are:
	%	- vecIncludeCells, vector of cells to include in analysis; [Default: all]
	%	- doPlot, boolean indicating whether to plot or not; [Default: false]
	%	Output: 
	%	- matLikelihood, 3D matrix containing distribution parameters of likelihood function:
	%		matLikelihood(intNeuron,intStimType,intParameter)
	%		Parameter data for Gaussian is:
	%		- intParameter == 1; mean response
	%		- intParameter == 2; std response
	%		Note:
	%		Last intStimType contains response distribution for baseline
	%		(no stimulus) frames
	
	
	%% define input variables
	ses = structIn.ses;
	sTypes = structIn.sTypes;
	matTypes = sTypes.matTypes;
	cellSelect = structIn.cellSelect;
	intNeurons = numel(ses.neuron);
	if ~isfield(structIn,'vecIncludeCells') || isempty(structIn.vecIncludeCells), vecIncludeCells = 1:intNeurons;else vecIncludeCells = structIn.vecIncludeCells;end
	if ~isfield(structIn,'vecLikelihoodTrials') || isempty(structIn.vecLikelihoodTrials), vecLikelihoodTrials = [];else vecLikelihoodTrials = structIn.vecLikelihoodTrials;end
	if ~isfield(structIn,'boolUseBaseline') || isempty(structIn.boolUseBaseline), boolUseBaseline = true;else boolUseBaseline = structIn.boolUseBaseline;end

	%% pre-allocate variables
	%approximate every stimulus response separately with normal distribution
	intParams = 2;
	intTypes = size(matTypes,2);
	matLikelihood = nan(intNeurons,intTypes+boolUseBaseline,intParams);
	
	%% build likelihood lookup table
	% pre-allocate
	if isempty(vecLikelihoodTrials)
		vecLikelihoodTrials = 1:length(ses.structStim.FrameOn);
	end
	vecStimTypeIndex = 1:intTypes;
	
	% loop through stimulus types
	for intStimType=vecStimTypeIndex
		vecStims = cellSelect{intStimType}(vecLikelihoodTrials);
		matResp = getNeuronResponse(ses,vecIncludeCells,vecStims);
		matLikelihood(vecIncludeCells,intStimType,1) = mean(matResp,2);
		matLikelihood(vecIncludeCells,intStimType,2) = std(matResp,0,2);
	end
	
	%add baseline response
	if boolUseBaseline
		matResp = getNeuronResponse(ses,vecIncludeCells,-1);
		matLikelihood(vecIncludeCells,intTypes+1,1) = mean(matResp,2);
		matLikelihood(vecIncludeCells,intTypes+1,2) = std(matResp,0,2);
	end
end

