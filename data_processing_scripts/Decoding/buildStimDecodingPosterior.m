function structPosterior = buildStimDecodingPosterior(sInPost)
	%buildDecodingPosterior Build Bayesian likelihood for supplied session
	%	Syntax: structPosterior = buildDecodingPosterior(sInPost)
	%   Input: sInPost, a structure containing the following fields:
	%	- structLikelihood, structure containing likelihood data
	%	- data
	%	- vecIncludeCells, vector of cells to include in analysis; [Default: all]
	%	Output:
	
	
	%% define input variables
	ses = sInPost.ses;
	intNeurons = numel(ses.neuron);
	matData = sInPost.matData;
	if ~isfield(sInPost,'vecIncludeCells') || isempty(sInPost.vecIncludeCells), vecIncludeCells = 1:intNeurons;else vecIncludeCells = sInPost.vecIncludeCells;end
	sInPost.matData = matData;
	matLikelihood = sInPost.matLikelihood;
	intStimTypes = size(matLikelihood,2);
	matPost = ones(intNeurons,intStimTypes);
	
	%% build posterior probability
	for intNeuron=vecIncludeCells
		thisActivity = sInPost.matData(intNeuron);
		
		for intStimType=1:intStimTypes
			%get mu and sigma
			mu = matLikelihood(intNeuron,intStimType,1);
			sigma = matLikelihood(intNeuron,intStimType,2);
			
			%calc probability
			P_ori_given_dFoF = normpdf(thisActivity,mu,sigma);
			
			
			%put in matrix
			matPost(intNeuron,intStimType) = P_ori_given_dFoF;
		end
	end
	
	%% put into output structure
	structPosterior = struct;
	structPosterior.matPost = matPost;
	structPosterior.vecMeanPost = prod(matPost,1);
	structPosterior.vecMeanPostM = mean(matPost,1);
end

