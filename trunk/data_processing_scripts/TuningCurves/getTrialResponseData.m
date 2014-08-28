function [matTrialResponse,cellSelectContrasts] = getTrialResponseData(ses,sStimAggregate)
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	
	%transform structure-based data to raw dFoF matrix
	intNumContrasts = length(unique(ses.structStim.Contrast));
	intTrials = length(ses.structStim.FrameOn);
	intFrames = length(ses.neuron(1).dFoF);
	intNeurons = numel(ses.neuron);
	matActivity = zeros(intNeurons,intFrames);
	for intNeuron=1:intNeurons
		matActivity(intNeuron,:) = ses.neuron(intNeuron).dFoF;
	end
	
	%check for stim aggregate; if present, then calculate mean number of
	%frames for detected stimuli
	vecTrialDur = ses.structStim.FrameOff - ses.structStim.FrameOn;
	if exist('sStimAggregate','var') && isstruct(sStimAggregate)
		cellFieldsC_SA{1} = 'Contrast';
		sTypesC_SA = getStimulusTypes(ses,cellFieldsC_SA);
		cellSelectContrasts = getSelectionVectors(sStimAggregate,sTypesC_SA);
		
		%get responded trials
		vecResponded = logical(sStimAggregate.vecTrialResponse);
		for intContrastIndex=1:intNumContrasts
			%get target trials
			vecContrastTrials = cellSelectContrasts{intContrastIndex};
			vecRespTrials = vecResponded & vecContrastTrials;
			vecNoRespTrials = ~vecResponded & vecContrastTrials;
			
			%assign mean duration to no-response trials
			vecTrialDur(vecNoRespTrials) = round(mean(sStimAggregate.FrameOff(vecRespTrials)-sStimAggregate.FrameOn(vecRespTrials)));
		end
	end
	
	%calculate mean per trial
	matTrialResponse = zeros(intNeurons,intTrials);
	for intTrial = 1:intTrials
		intFrameOn = ses.structStim.FrameOn(intTrial);
		intDur = vecTrialDur(intTrial);
		intFrameOff = intDur + intFrameOn;
		matTrialResponse(:,intTrial) = mean(matActivity(:,intFrameOn:intFrameOff),2);
	end
end

