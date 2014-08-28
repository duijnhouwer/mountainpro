function vecStimTrace = getStimTrace(ses,intSwitch)
	%getStimTrace Returns vector for each timepoint what stimulus type was
	%present
	%   Syntax: vecStimTrace = getStimTrace(ses,intSwitch)
	
	if ~exist('intSwitch','var'),intSwitch=1;end
	
	sTypes = getStimulusTypes(ses);
	cellSelect = getSelectionVectors(ses.structStim,sTypes);
	
	intTypes=numel(cellSelect);
	
	vecStimTrace=zeros(1,length(ses.neuron(1).dFoF));
	for intType=1:intTypes
		vecSelect = cellSelect{intType};
		for intTrial=find(vecSelect==1)
			if intSwitch == 1
				vecFrames = ses.structStim.FrameOn(intTrial):ses.structStim.FrameOff(intTrial);
			else
				if intTrial == 1
					intStart = 1;
				else
					intStart = floor(mean([ses.structStim.FrameOn(intTrial) ses.structStim.FrameOff(intTrial-1)]));
				end
				
				if intTrial == length(ses.structStim.FrameOn)
					intStop = length(ses.neuron(1).dFoF);
				else
					intStop = ceil(mean([ses.structStim.FrameOff(intTrial) ses.structStim.FrameOn(intTrial+1)]));
				end
				vecFrames = intStart:intStop;
			end
			vecStimTrace(vecFrames) = intType;
		end
	end
	vecStimTrace(vecStimTrace==0) = intTypes+1;
end

