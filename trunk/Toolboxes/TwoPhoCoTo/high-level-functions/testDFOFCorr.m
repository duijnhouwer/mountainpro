function [vecCorr vecStd] = testDFOFCorr(vecNoise,intReps,intLength)
	%testDFOFCorr Makes a vector of correlations per noise fraction, using
	%			   dummy dFoF data.
	%   syntax: [vecCorr vecStd] = ...
	%				testDFOFCorr(vecNoise,intReps,intLength)
	%	input:
	%	- vecNoise: vector containing requested noise fraction; range [0 1]
	%	- intReps: number of repetitions per noise fraction
	%	- intLength: length of dummy signal
	%	output:
	%	- vecCorr: list of correlations corresponding to the noise
	%	  fractions in vecNoise
	%	- vecStd: list of STDs you get from noise
	%
	%Dependencies:
	% - makeDFOFData.m
	% - zScale.m
	%
	%	Version history:
	%	1.0 - April 18 2011
	%	Created by Jorrit Montijn

	%calculate correlations per cell
	vecCorr = nan(1,length(vecNoise));
	vecStd =  nan(1,length(vecNoise));
	for intNoise=1:length(vecNoise)
		thisNoise = vecNoise(intNoise);
		parfor i=1:intReps
			vecData1 = makeDFOFData(intLength,thisNoise);
			vecData2 = makeDFOFData(intLength,thisNoise);
			vecCorr(i) = calcCorr(vecData1,vecData2);
		end
		vecCorr(intNoise) = mean(vecCorr);
		vecStd(intNoise) = std(vecCorr);
	end
end

