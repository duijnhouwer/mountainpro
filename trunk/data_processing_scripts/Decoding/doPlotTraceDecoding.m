function doPlotTraceDecoding(sTD,sTC,sBR)
	%doPlotTraceDecoding Plots continuous decoding trace
	%   Syntax: doPlotTraceDecoding(sTD,sTC,sBR)
	%	Inputs:
	%	- sTD: structure Trace Decoding
	%	- sTC: structure Trace Correlation [optional]
	%	- sBR: structure Behavioral Response [optional]
	
	%close all
	%colormap
	intTypes = numel(sTD.cellSelect);
	cmap = colormap(jet(intTypes));
	colormap('default');
	
	%set distance vector
	dblI = 0.25;
	vD =[dblI*8 dblI dblI*2 dblI dblI*3 dblI dblI*4 dblI dblI*4 dblI dblI*4];
	vH = cumsum(vD);
	
	%check for correlation data
	if nargin > 1 && isstruct(sTC) && isfield(sTC,'matRawCovar')
		boolDoCorrelations = true;
		%get dF/F trace
		vecMeanAct=mean(sTC.matEpoch,1);
		vecSdAct=std(sTC.matEpoch,[],1);
		intWindowLength = sTC.intEpochDuration;
		
		%get correlation trace
		intNeurons = size(sTC.matEpoch,1);
		intFrames = length(vecMeanAct);
		matSelect = tril(true(intNeurons,intNeurons),-1);
		vecCorrMean = nan(1,intFrames);
		vecCorrSD = nan(1,intFrames);
		for intFrame=1:size(sTC.matRawCovar,3)
			matCorr = sTC.matRawCovar(:,:,intFrame);
			vecCorrMean(intFrame+floor(intWindowLength/2)) = mean(matCorr(matSelect));
			vecCorrSD(intFrame+floor(intWindowLength/2)) = std(matCorr(matSelect));
		end
	else
		boolDoCorrelations = false;
	end
	
	%check for behavior data
	if nargin == 3 && isstruct(sBR) && isfield(sBR,'vecRespFrames')
		boolDoBehavior = true;
		
		intRespTypes = getUniqueVals(sBR.vecRespTypes);
		cmapResp = colormap(jet(intRespTypes));
		colormap('default');
		
		vecRespFrames = sBR.vecRespFrames;
		vecRespTypes = sBR.vecRespTypes;
		
		intPlotRespOffset = round(sTD.intWindowLength/2);
	else
		boolDoBehavior = false;
	end
	
	%normalize probabilities
	dblFrameRate = sTD.ses.samplingFreq;
	matDecoding = sTD.matDecoding;
	vecNorm = sum(matDecoding,1);
	matNorm = repmat(vecNorm,[size(matDecoding,1) 1]);
	
	matDecoding = matDecoding./matNorm;
	cellStart = cell(1,intTypes);
	cellStop = cell(1,intTypes);
	
	%get stimulus times
	for intType=1:intTypes
		cellStart{intType} = sTD.ses.structStim.FrameOn(sTD.cellSelect{intType});
		cellStop{intType} = sTD.ses.structStim.FrameOff(sTD.cellSelect{intType});
	end
	
	%plot
	intStep = 10^10; %5000
	for intStart=1:intStep:size(matDecoding,2)
		%make figure
		ptrFig = figure;
		set(ptrFig,'Color',[1 1 1]);
		grid on;
		hold on;
		
		%plot decoding
		intStop = min((intStart+intStep-1),size(matDecoding,2));
		vecX = intStart:intStop;
		harea = area(vecX/dblFrameRate,vH(1)*matDecoding(:,vecX)');
		set(harea(end),'FaceColor',[1 1 1],'EdgeColor',[1 1 1])
		for intType=1:intTypes
			set(harea(intType),'FaceColor',cmap(intType,:),'EdgeColor',cmap(intType,:))
			
			%plot stimuli
			vecPlotStimsIndices = cellStart{intType} < intStop & cellStop{intType} > intStart;
			for intPlotStimIndex=find(vecPlotStimsIndices)
				vecPlotStim = find(sTD.cellSelect{intType}==1);
				intPlotStim = vecPlotStim(intPlotStimIndex);
				intStartStim = max(sTD.ses.structStim.FrameOn(intPlotStim),intStart);
				intStopStim = min(sTD.ses.structStim.FrameOff(intPlotStim),intStop);
				
				fill([intStartStim-floor(sTD.intWindowLength/2) intStopStim-floor(sTD.intWindowLength/2) intStopStim+floor(sTD.intWindowLength/2) intStartStim+floor(sTD.intWindowLength/2)]/dblFrameRate,[vH(4) vH(4) vH(5) vH(5)],cmap(intType,:),'EdgeColor',cmap(intType,:))
			end
		end
		
		%plot behavioral responses
		if boolDoBehavior
			for intRespType=1:intRespTypes
				vecSelect = vecRespTypes == intRespType;
				vecPlotRespIndices = vecRespFrames < intStop & vecRespFrames > intStart & vecSelect;
				for intPlotRespIndex=find(vecPlotRespIndices)
					intRespFrame = vecRespFrames(intPlotRespIndex);
					
					fill([intRespFrame-intPlotRespOffset intRespFrame+intPlotRespOffset intRespFrame]/dblFrameRate,[vH(3) vH(3) vH(2)],cmapResp(intRespType,:),'EdgeColor',cmap(intRespType,:))
				end
			end
		end
		
		%plot movement
		if boolDoBehavior && isfield(sBR,'vecMovement') && ~isempty(sBR.vecMovement)
			
			vecMT = sBR.vecMovement; %baseline trace
			vecMT = vecMT-min(vecMT);
			vecMT = vecMT/max(vecMT(:));
			
			dblTraceWidth = vH(7) - vH(6);
			dblTraceHeight = vH(6);
			vecMovementTrace = (vecMT*dblTraceWidth) + dblTraceHeight;
			plot((intStart:intStop)/dblFrameRate,vecMovementTrace(intStart:intStop),'k')
		end
		
		%plot activity traces
		if boolDoCorrelations
			%plot dF/F
			vecMeanAct=mean(sTC.matEpoch,1);
			vecSdAct=std(sTC.matEpoch,[],1);
			dblMin = min(vecMeanAct-vecSdAct);
			dblMax = max(vecMeanAct+vecSdAct-dblMin);
			vecNormMA = (vecMeanAct-dblMin)/dblMax;
			vecNormSA = (vecSdAct-dblMin)/dblMax;
			
			dblTraceWidth = vH(9) - vH(8);
			dblTraceHeight = vH(8);
			
			vecMinTrace = (vecNormMA-vecNormSA)*dblTraceWidth+dblTraceHeight;
			vecMeanTrace = (vecNormMA)*dblTraceWidth+dblTraceHeight;
			vecMaxTrace = (vecNormMA+vecNormSA)*dblTraceWidth+dblTraceHeight;
			
			vecX = intStart:intStop;
			vecXInv = intStop:-1:intStart;
			fill([vecX vecXInv]/dblFrameRate,[vecMinTrace(vecX) vecMaxTrace(vecXInv)],[0.75 0.75 1],'EdgeColor',[0.75 0.75 1])
			plot(vecX/dblFrameRate,vecMeanTrace(vecX),'b-','LineWidth',2);
			
			%plot correlations
			%{
			dblMin = min(vecCorrMean-vecCorrSD);
			dblMax = max(vecCorrMean+vecCorrSD-dblMin);
			vecNormMC = (vecCorrMean-dblMin)/dblMax;
			vecNormSC = (vecCorrSD-dblMin)/dblMax;
			
			dblTraceWidth = vH(11) - vH(10);
			dblTraceHeight = vH(10);
			
			vecMinTraceCorr = (vecNormMC-vecNormSC)*dblTraceWidth+dblTraceHeight;
			vecMeanTraceCorr = (vecNormMC)*dblTraceWidth+dblTraceHeight;
			vecMaxTraceCorr = (vecNormMC+vecNormSC)*dblTraceWidth+dblTraceHeight;
			
			fill([vecX vecXInv],[vecMinTraceCorr(vecX) vecMaxTraceCorr(vecXInv)],[1 0.75 0.75],'EdgeColor',[1 0.75 0.75])
			plot(vecX,vecMeanTraceCorr(vecX),'r-','LineWidth',2);
			%}
			vecCorrMean = vecCorrMean-min(vecCorrMean);
			vecCorrMean = vecCorrMean/max(vecCorrMean(:));
			
			dblTraceWidth = vH(11) - vH(10);
			dblTraceHeight = vH(10);
			vecCorrTrace = (vecCorrMean*dblTraceWidth) + dblTraceHeight;
			plot(vecX/dblFrameRate,vecCorrTrace(vecX),'r-','LineWidth',2)
		end
		
		%end commands
		hold off
		xlim([intStart intStop]/dblFrameRate);
		xlabel('Time (s)');
		ylabel('Continuous recording properties')
	end
end

