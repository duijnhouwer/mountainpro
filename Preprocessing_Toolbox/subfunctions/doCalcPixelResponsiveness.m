function sRec = doCalcPixelResponsiveness(sRec)
	%UNTITLED Summary of this function goes here
	%   Detailed explanation goes here
	
	%define image variables
	if isfield(sRec.sProcLib,'CaCh')%which channel has calcium data?
		intCaCh = sRec.sProcLib.CaCh;
	else
		intCaCh = 1;
	end
	if isfield(sRec.sMD,'strMasterDir')
		strImPath = [sRec.sMD.strMasterDir sRec.sMD.strImgTarget sRec.strSession filesep sRec.sProcLib.strRecording filesep];
	else
		strImPath = [sRec.sMD.strImgTarget sRec.strSession filesep sRec.sProcLib.strRecording filesep];
	end
	intLengthT = length(num2str(sRec.sProcLib.t-1));
	strTargetIm = ['t%0' num2str(intLengthT) 'd_ch%02d.tif'];
	
	% calculate cell-timelines
	fprintf('Extracting timeseries for pixel responsiveness, please wait...\n');
	
	%get stimulus timing
	structStim = getStimFramesPrePro(sRec);
	
	%pre-allocate look-up table and other variables
	vecOriLookup = getOriListFromTrials(structStim.Orientation);
	intStimTypes = length(vecOriLookup);
	intStimNumber = length(structStim.FrameOn);
	intReps = intStimNumber/intStimTypes;
	
	intBaselineIndex = intStimTypes + 1;
	intLastType = nan;
	intTraceLength = max(max(abs(structStim.FrameOn-structStim.FrameOff)),structStim.FrameOn(1));
	matTrace = nan(sRec.sProcLib.y,sRec.sProcLib.x,intTraceLength);
	intTraceCounter = 0;
	vecRepCounter = zeros(1,intBaselineIndex);
	
	%pre-allocate response matrix
	matPixelStimResp = nan(sRec.sProcLib.y,sRec.sProcLib.x,intStimTypes,intReps);
	matPixelNormResp = nan(sRec.sProcLib.y,sRec.sProcLib.x,intStimTypes,intReps);
	matPixelBaseResp = nan(sRec.sProcLib.y,sRec.sProcLib.x,1,intStimNumber);
	
	%% perform stim-resp extraction
	fracPrev = -1;
	for intT=1:sRec.sProcLib.t
		%read image
		strIm = [strImPath 'images' filesep sprintf(strTargetIm,intT-1,intCaCh-1)];
		image = imread(strIm);
		matIm = im2double(image);
		
		%get stimulus at this frame
		dblOriAtFrame = getStimAtFrame(structStim,intT);
		if dblOriAtFrame == 999 %baseline
			intStimIndex = intBaselineIndex;
		else
			intStimIndex = find(vecOriLookup==dblOriAtFrame);
		end
		
		%check for change
		if intStimIndex ~= intLastType
			%change
			if ~isnan(intLastType)
				%if it's not very first frame
				
				%get repetition and increment for this type
				vecRepCounter(intLastType) = vecRepCounter(intLastType) + 1;
				intRep = vecRepCounter(intLastType);
				
				%check if stim or baseline
				if intBaselineIndex ~= intLastType
					%get mean response during this trace and put into output
					matThisResp = nanmean(matTrace,3);
					matPixelStimResp(:,:,intLastType,intRep) = matThisResp;
					
					matLastBase = matPixelBaseResp(:,:,1,vecRepCounter(intBaselineIndex));
					matPixelNormResp(:,:,intLastType,intRep) = matThisResp - matLastBase;
					
					%check if it's last to switch to baseline
					if intBaselineIndex == intStimIndex && vecRepCounter(intBaselineIndex) == intStimNumber
						break;
					end
				else
					%put in matrix
					matThisResp = nanmean(matTrace,3);
					matPixelBaseResp(:,:,1,intRep) = matThisResp;
				end
			end
			%clear trace buffer
			matTrace = nan(size(matTrace));
			intTraceCounter = 0;
			intLastType = intStimIndex;
		end
		
		%add current frame to trace buffer
		intTraceCounter = intTraceCounter + 1;
		matTrace(:,:,intTraceCounter) = matIm;

		
		%send msg
		intFrac = intT/sRec.sProcLib.t;
		fracNow = round(intFrac * 100);
		if fracPrev ~= fracNow
			tStamp = fix(clock);
			strPlace = sprintf('Processing %s%s... Now at %d%% [%02d:%02d:%02d]', sRec.strSession, sRec.sProcLib.strRecording, fracNow, tStamp(4),tStamp(5),tStamp(6));
			disp(strPlace);
			fracPrev = fracNow;
		end
	end
	%msg
	fprintf('Finished data collection... Calulating pixel responsiveness\n');
	
	%z-score responses
	matPixelMeanNormResp = mean(matPixelNormResp,4);
	matPixelZScoreStimResp = nan(sRec.sProcLib.y,sRec.sProcLib.x,intStimTypes);
	
	[matBaseZ,matBaseMu,matBaseSigma] = zscore(squeeze(matPixelBaseResp),[],3); %#ok<ASGLU>
	for intStim=1:intStimTypes
		%get stim resp
		matThisResp = mean(squeeze(matPixelStimResp(:,:,intStim,:)),3);
		
		%z-score normalized to baseline
		matRespZ = (matThisResp-matBaseMu)./matBaseSigma;
		
		%put into matrix
		matPixelZScoreStimResp(:,:,intStim) = matRespZ;
	end
	
	%calculate maximum visual responsiveness
	%max stim response in sd's above baseline
	matPixelMaxResponsiveness = max(matPixelZScoreStimResp,[],3);
	
	%calculate orientation selectivity
	%[(max mean normalized stim resp) - (min mean normalized stim resp)]/ [(max mean normalized stim resp) + (min mean normalized stim resp)]
	matMaxResp = max(matPixelMeanNormResp,[],3);
	matMinResp = min(matPixelMeanNormResp,[],3);
	matPixelSelectivity = (matMaxResp - matMinResp);% .* mean(cat(3,abs(matMaxResp),abs(matMinResp)),3);
	[indexList,indexLow,indexHigh] = getOutliers(matPixelSelectivity,10);
	matPixelSelectivity(indexList) = 0;
	
	%smooth
	ptrSmoothFilter = fspecial('disk', 2);
	matPixelMaxResponsiveness = imfilter(matPixelMaxResponsiveness,ptrSmoothFilter,'replicate');
	matPixelSelectivity = imfilter(matPixelSelectivity,ptrSmoothFilter,'replicate');
	
	% save data into sRec
	sPixResp = struct;
	%sPixResp.matPixelStimResp = matPixelStimResp;
	%sPixResp.matPixelBaseResp = matPixelBaseResp;
	%sPixResp.matPixelNormResp = matPixelNormResp;
	sPixResp.strInfo1 = 'matPixelSelectivity is orientation selectivity defined as: [(max z-scored normalized stim resp) - (min z-scored normalized stim resp)]/ [(max z-scored normalized stim resp) + (min z-scored normalized stim resp)]';
	sPixResp.matPixelSelectivity = matPixelSelectivity;
	sPixResp.strInfo2 = 'matPixelMaxResponsiveness is visual responsivess defined as: number of sd''s that mean response is above baseline response (in baseline sd''s) [for stim type with highest value]';
	sPixResp.matPixelMaxResponsiveness = matPixelMaxResponsiveness;
	
	sRec.sPixResp = sPixResp;
	
	%save file
	strNewDir = [sRec.sMD.strMasterDir sRec.sMD.strImgTarget sRec.strSession filesep sRec.sProcLib.strRecording filesep];
	strFile = [strNewDir sRec.strSession sRec.sProcLib.strRecording '_prepro.mat'];
	save([strFile '1'],'sRec') %save temp
	movefile(strFile,[strFile '.backup'],'f');
	movefile([strFile '1'],strFile,'f');
	fprintf('Saved recording structure to %s\n',strFile)
end

