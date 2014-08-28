function vecPopResp = getNeuronFrameResponse(ses,vecNeurons,vecFrames,structParams)
	%getNeuronFrameResponse Retrieves mean neuronal response during specified epoch
	%	Syntax: vecPopResp = getNeuronFrameResponse(ses,vecNeurons,vecFrames)
	%   Input:
	%	- ses, session data
	%	- vecNeurons, vector of which neurons to include
	%	- vecFrames, vector of which frames to include
	%	Output: 
	%	- vecPopResp, vector containing mean dF/F during specified frames
	%
	%Dependencies:
	% - none
	%
	%	Version history:
	%	1.0 - July 22 2013
	%	Created by Jorrit Montijn
	
	%check inputs
	if nargin == 3
		structParams = struct;
	end
	
	%check if vector or scalar
	boolVec = length(vecNeurons) > 1;
	if boolVec, vecPopResp = nan(max(vecNeurons));
	else vecPopResp = nan;end
	
	%go through stims
	if boolVec
		for intNeuron=vecNeurons
			vecPopResp(intNeuron) = mean(ses.neuron(intNeuron).dFoF(vecFrames));
		end;
	else vecPopResp = mean(ses.neuron(vecNeurons).dFoF(vecFrames));
	end
end

