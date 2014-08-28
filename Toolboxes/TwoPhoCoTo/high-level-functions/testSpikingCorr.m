function [vecCorr vecStd] = testSpikingCorr(vecMeanRates,intReps,intLength)
	%testSpikingCovar Makes a vector of correlation per noise fraction,
	%				  using dummy spiking data.
	%   syntax: [vecCorr vecStd] = ...
	%				testSpikingCovar(vecMeanRates,intReps,intLength)
	%	input:
	%	- vecMeanRates: vector containing mean spiking rates (lambda)
	%	- intReps: number of repetitions per noise fraction
	%	- intLength: length of dummy signal
	%	output:
	%	- vecCorr: list of correlations corresponding to the spiking rates
	%	  in vecMeanRates 
	%	- vecStd: list of STDs you get from spiking
	%
	%Dependencies:
	% - makeSpikingData.m
	% - zScale.m
	%
	%	Version history:
	%	1.0 - April 18 2011
	%	Created by Jorrit Montijn

	%calculate covariances per cell
	vecCorr = nan(1,length(vecMeanRates));
	vecStd =  nan(1,length(vecMeanRates));
	for intRate=1:length(vecMeanRates)
		thisRate = vecMeanRates(intRate);
		for i=1:intReps
			vecData1 = makeSpikingData(intLength,5);
			vecData2 = makeSpikingData(intLength,thisRate);
			matIn = [vecData1;vecData2];
			matZ = zScale(matIn); % comment out this line to suppress z-transformed data
			%matZ = matIn; %comment out this line to suppress non-z-transformed data
			dblCorrelation = mean(matZ(1,:).*matZ(2,:));
			vecCorr(i) = dblCorrelation;
		end
		vecCorr(intRate) = mean(vecCorr);
		vecStd(intRate) = std(vecCorr);
	end
end

