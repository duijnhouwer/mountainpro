function [matParams] = runBootstrap(xList,matData,paramInit,functionHandle,varargin)
	%syntax: [matParams] = runBootstrap(xList,matData,paramInit,functionHandle,[maxIter=1000])
	%dependencies:
	%defaultValues.m
	%MLFit.m
	%	Version history:
	%	1.0 - May 11 2011
	%	Created by Jorrit Montijn
	
	fprintf('\nRunning Bootstrap Procedure. Please wait...\n');
	
	
	%%% BOOTSTRAPPING
	maxIter = defaultValues(varargin,1000);
	matParams = zeros(maxIter,length(paramInit));
	
	for i=1:maxIter
		
		%resample
		vecResampled = Resample(matData);
		
		[p,mse] = MLFit(functionHandle, paramInit, xList, vecResampled);	

		matParams(i,:) = p;
	end
end
function vecResampled = Resample(matData)
	[yNum,xNum] = size(matData);
	vecResampled =  nan(1,xNum);
	while max(isnan(vecResampled)) == 1
		vecIndex = randi(yNum,1,xNum);
		for xInd=1:xNum
			vecResampled(xInd) = matData(vecIndex(xInd),xInd);
		end
	end
end