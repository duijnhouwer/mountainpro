function dblOri =getStimAtFrame(sIn,intFrame)
	%UNTITLED5 Summary of this function goes here
	%   Detailed explanation goes here
	
	%check input type (ses or structStim)
	if isfield(sIn,'structStim')
		structStim = sIn.structStim;
	elseif isfield(sIn,'FrameOn')
		structStim = sIn;
	else
		error([mfilename ':StructureFormatNotDetected'],'Unknown structure format');
	end
	
	%get orientation at frame
	lastStart = find(structStim.FrameOn < intFrame,1,'last');
	lastStop = find(structStim.FrameOff < intFrame,1,'last');
	if isempty(lastStart)
		dblOri = 999;
	elseif isempty(lastStop)
		dblOri = structStim.Orientation(1);
	else
		if lastStart > lastStop
			dblOri = structStim.Orientation(lastStart);
		else
			dblOri = 999;
		end
	end
end

