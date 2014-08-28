function dblCorrelation = calcCorr(vecIn1,vecIn2)
	%calcCorr Calculates correlations between the two input vectors after
	%		   z-scoring the data.
	%   syntax: dblCorrelation = calcCorr(vecIn1,vecIn2)
	%	input:
	%	- vecIn1: vector containing data values
	%	- vecIn2: same size as vecIn2, from a different source
	%	output:
	%	- dblCorrelation: single value representing the correlation
	%
	%Dependencies:
	% - zScale.m
	%
	%	Version history:
	%	1.0 - April 18 2011
	%	Created by Jorrit Montijn
	%	2.0 - September 14 2012
	%	Corrected [by Jan Lankelma]
	
	matIn = [vecIn1; vecIn2];
	matZ = zScore(matIn);
	%{
    figure
    subplot(1,4,1) ; plot(matIn')
    subplot(1,4,2) ; plot(matZ')
    subplot(1,4,3) ; hist(matZ(:))
    subplot(1,4,4) ; plot(matZ(1,:),matZ(2,:),'or')
	%}
	
	% calculate covariance
	N = size(matZ,2) ;
	dblCorrelation = mean(matZ(1,:).*matZ(2,:)) ;
	dblCorrelation = dblCorrelation * N/(N-1) ;   % correction factor !!
	
	%
	% compare with Matlab fun
	%dblCheck = corr(matZ')
end

