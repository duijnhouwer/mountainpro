function [vecData] = makeSpikingData(intLength,dblMeanSpikingRate)
%makeSpikingData Makes dummy data for testing, similar to spiking data
%	syntax: vecData = makeDFOFData(intLength,dblMeanSpikingRate)
%	input:
%	- intLength: integer specifying length of data vector
%	- dblMeanSpikingRate: mean spiking rate (poission lambda)
%	output:
%	- vecData: vector containing dummy data
%
%	Version history:
%	1.0 - April 18 2011
%	Created by Jorrit Montijn

lambda = dblMeanSpikingRate;

vecData = poissrnd(lambda,1,intLength);
end

