function [vecData] = makeDFOFData(intLength,dblNoise)
%makeDFOFData Makes dummy data for testing, similar to fluorescence changes
%	syntax: vecData = makeDFOFData(intLength,dblNoise)
%	input:
%	- intLength: integer specifying length of data vector
%	- dblNoise: amount of noise in signal; range [0 1]
%	output:
%	- vecData: vector containing dummy data
%
%	Version history:
%	1.0 - April 18 2011
%	Created by Jorrit Montijn

vecX = 1:intLength;
vecSinDegX = vecX*180+90;
vecRand = rand(1,intLength);
vecSine = sind(vecSinDegX);
vecData = dblNoise*vecRand+(1-dblNoise)*vecSine;
end

