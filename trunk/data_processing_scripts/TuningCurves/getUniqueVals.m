function vecUniques = getUniqueVals(vecValsIn)
	%getUniqueVals Retrieves a list of unique values from input vector
	%	Syntax: vecUniques = getUniqueVals(vecValsIn)
	%   Removes all duplicates from input list. If input is matrix, it
	%   automatically transforms the matrix to a 1D vector and performs the
	%   retrieval of unique values on the transformed vector
	%
	%Dependencies:
	% - none
	%
	%	Version history:
	%	1.0 - July 22 2013
	%	Created by Jorrit Montijn
	
	intVal = -inf;
	vecUniques = [];
	intMax = max(vecValsIn);
	vecValsIn = sort(vecValsIn(:),'ascend');
	while intVal < intMax
		[intInd] = find(vecValsIn > intVal,1);
		intVal = vecValsIn(intInd);
		vecValsIn = vecValsIn(vecValsIn > intVal);
		vecUniques(end+1) = intVal;
	end
end