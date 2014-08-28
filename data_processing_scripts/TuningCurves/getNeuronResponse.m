function matResp = getNeuronResponse(ses,vecNeurons,vecStims,structParams)
	%getNeuronResponse Retrieves neuronal response for certain stimuli
	%	Syntax: matResp = getNeuronResponse(ses,vecNeurons,vecStims)
	%   Input:
	%	- ses, session data
	%	- vecNeurons, vector of which neurons to include
	%	- vecStims, vector of which stimuli to include [-1 returns response
	%		outside stimulus presentations]; works well with cellSelect{}
	%		output vector (output from getSelectionVectors)
	%	Output: 
	%	- matResp, 2D matrix containing neuronal response per stimulus per neuron:
	%		matResp(intNeuron,intStimPres)
	%
	%	Version history:
	%	1.0 - July 22 2013
	%	Created by Jorrit Montijn
	%	2.0 - May 19 2014
	%	Added support for preceding baseline subtraction [by JM]
	
	%check inputs
	if nargin < 4
		structParams = struct;
	end
	
	%select frames
	if vecStims == -1
		%baseline
		vecStartFrames = ses.structStim.FrameOff;
		vecStopFrames = [ses.structStim.FrameOn(2:end) length(ses.neuron(1).dFoF)];
	else
		%stimuli
		vecStartFrames = ses.structStim.FrameOn(vecStims);
		vecStopFrames = ses.structStim.FrameOff(vecStims);
	end
	
	%check if frame subset selection is requested
	if isfield(structParams,'intStopOffset')
		vecStopFrames = vecStartFrames + structParams.intStopOffset;
	end
	if isfield(structParams,'intStartOffset')
		vecStartFrames = vecStartFrames + structParams.intStartOffset;
	end
	if isfield(structParams,'intPreBaselineRemoval')
		intPreBaselineRemoval = structParams.intPreBaselineRemoval;%dblBaselineSecs
	else
		intPreBaselineRemoval = [];
	end
	
	%retrieve data
	if islogical(vecStims)
		intRepetitions = sum(vecStims);
	else
		intRepetitions = numel(vecStims);
	end
	%check if vector or scalar
	boolVec = length(vecNeurons) > 1;
	if boolVec, matResp = nan(max(vecNeurons),intRepetitions);
	else matResp = nan(1,intRepetitions);end
	
	%go through stims
	for intStimPres=1:length(vecStartFrames)
		intStartFrame = vecStartFrames(intStimPres);
		intStopFrame = vecStopFrames(intStimPres);
		if boolVec
			for intNeuron=vecNeurons
				if ~isempty(intPreBaselineRemoval),dblBaseline = mean(ses.neuron(intNeuron).dFoF((intStartFrame-intPreBaselineRemoval):(intStartFrame-1)));
				else dblBaseline = 0;end
				matResp(intNeuron,intStimPres) = mean(ses.neuron(intNeuron).dFoF(intStartFrame:intStopFrame))-dblBaseline;
			end; 
		else
			if ~isempty(intPreBaselineRemoval),dblBaseline = mean(ses.neuron(vecNeurons).dFoF((intStartFrame-intPreBaselineRemoval):(intStartFrame-1)));
			else dblBaseline = 0;end
			matResp(1,intStimPres) = mean(ses.neuron(vecNeurons).dFoF(intStartFrame:intStopFrame)) - dblBaseline;
		end
	end
end

