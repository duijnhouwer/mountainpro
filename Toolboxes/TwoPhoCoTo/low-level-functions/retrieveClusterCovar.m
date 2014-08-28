function [nVec,vecDist,vecDistWeight] = retrieveClusterCovar(xVec,xVecDist,matRawCovar,matDistances,intClusterSize)
	%retrieveClusterCovar Retrieves the mean corriance per cluster for
	%					  every possible cluster in matRawCovar of size
	%					  intClusterSize and bins the results as specified
	%					  by the binning vector xVec (using hist())
	%	syntax: [nVec,vecDist,vecDistWeight] = retrieveClusterCovar(...
	%				xVec,xVecDist,matRawCovar,matDistances,intClusterSize)
	%	input: 
	%	- xVec: binning vector used by Matlab's function hist()
	%	- xVecDist: distance binning vector
	%	- matRawCovar: corriance matrix in the format as outputted by
	%	  processActivityMatrix()
	%	- matDistances: distance matrix in the format as outputted by
	%	  processActivityMatrix()
	%	- intClusterSize: size of cluster to be used for calculation
	%   output:
	%	- nVec: vector same size as xVec containing the number of clusters
	%	  that have a mean corriance that lies within that bin
	%	- vecDist: vector same size as xVecDist the mean corriance per
	%	  mean cluster distance over clusters
	%	- vecDistWeight: vector same size as vecDist containing the number
	%	  of clusters in that distance bin
	%
	%Dependencies:
	% - retrieveDoublePerms() :: subfunction included in this file
	%
	%	Version history:
	%	0.9 - April 17 2011
	%	Created by Jorrit Montijn
	%	0.9.1 - April 18 2011
	%	Removed raw output, added continuous binning to avoid out-of-memory
	%	errors (but it is significantly slower) [by JM]
	%	0.9.2 - April 19 2011
	%	Added comments and explanation how the looping through all 
	%	combinations actually works [by JM]
	%	0.9.3 - April 21 2011
	%	Added distance tracking [by JM]
	%	2.0 - September 14 2012
	%	Works perfectly; compatible with TwoPhoCoTo 2.0 [by JM]
	
	%% Define initial variables
	intCells = size(matRawCovar,1);

	vec = 1:intClusterSize; %permutation position vector; it is used for looping through permutations
	vec = uint8(vec);
	maxCount = factorial(intClusterSize)/(factorial(2)*factorial(intClusterSize-2)); %approximate number of combinations
	
	
	%% Starting message
	dblStart = tic;
	intCombinations = round(factorial(intCells)/(factorial(intClusterSize)*factorial(intCells-intClusterSize)));
	fprintf('Starting calculation of cluster size %u with %u cells... Total number of combinations is %u\n',intClusterSize,intCells,intCombinations)
	if intCombinations > 100000
		fprintf('Take a seat, this might take a while...\n');
	end
	
	nVec = zeros(size(xVec));
	vecDist = nan(size(xVecDist));
	vecDistWeight = zeros(size(xVecDist));
	if intmax('uint64') < intCombinations
		warning('RetrieveClusterCovar:TooManyCombinations','Number of combinations is extremely large. The results will probably be unreliable, and it will take extremely long to complete\n')
	end
	
	%% Begin calculations
	endpos = intClusterSize; %last position of permutation vector
	boolDontStop = true;
	counter = 0; %just a counter to display messages
	while boolDontStop
		
		%display a message for the impatient user
		counter = counter + 1;
		if mod(counter,100000) == 0 %every 100 000 combinations
			dblDur = toc(dblStart);
			fracDone = counter / intCombinations;
			dblEta = (dblDur / fracDone) - dblDur;
			fprintf('Cluster size %d with %d cells; Now at %u of %u... Running for %.0fs; ETA is %.0fs; tot dur is %.0fs\n',intClusterSize,intCells,counter,intCombinations,dblDur,dblEta,dblDur+dblEta);
		end
		
		%retrieve all possible combinations of two from permutation vector
		matDoubleCombs = retrieveDoublePerms(vec);
		
		%retrieve corrs for the different combinations
		vecVals = zeros(1,maxCount);
		vecDists = zeros(1,maxCount);
		for intThisCombo=1:maxCount
			intCell1 = matDoubleCombs(intThisCombo,1);
			intCell2 = matDoubleCombs(intThisCombo,2);
			dblDist = matDistances(intCell1,intCell2);
			dblVal = matRawCovar(intCell1,intCell2);
			
			%add the correlation of this combination to the temporary vector
			vecVals(intThisCombo) = dblVal;
			vecDists(intThisCombo) = dblDist;
		end
		%add the mean of all combinations of two from this cluster to the 
		%binned output vector in order to avoid	out-of-memory errors
		mCovar = mean(vecVals);
		vecTemp = hist(mCovar,xVec);
		nVec = nVec + vecTemp;
		
		%compute the mean distance between all cells in this cluster and
		%add the mean correlation to that distance bin
		mDist = mean(vecDists);
		intIndDist = hist(mDist,xVecDist);
		intDist = find(intIndDist == 1,1);
		if vecDistWeight(intDist) == 0
			vecDistWeight(intDist) = 1;
			vecDist(intDist) = mCovar;
		else
			vecDist(intDist) = double((vecDist(intDist)*vecDistWeight(intDist) + mCovar) / (vecDistWeight(intDist) + 1));
			vecDistWeight(intDist) = vecDistWeight(intDist) + 1;
		end
		
		%DO THE ACTUAL LOOPING THROUGH ALL PERMUTATIONS
		%This took me quite a while to come up with, so i'll try to explain:
		%we can't just do an ordinary nested loop as in retrieveDoublePerms(), 
		%because this needs to work with any cluster size. In essence, this
		%while loop is a dynamic version of nested for loops that creates 
		%any number of for loops based on the number of positions (aka
		%cluster size) in the permutation vector. Just imagine we have a
		%permutation vector [1 3 82 83 84] (so a cluster size of 5) and we
		%have 84 cells. Then go through the following statements and
		%imagine what they would do:
		pos = endpos; %set position index at the last position number :: [1 3 82 83 <84>]
		vec(pos) = vec(pos) + 1; %increase that position :: [1 3 82 83 <84+1=85>]
		while max(vec) > intCells %if the last increase has caused a cell-index to exceed the number of cells (85>84), then...
			pos = pos - 1; %switch the position on the permutation vector 1 to the left... loop1: [1 3 82 <83> 85]; loop2: [1 3 <82> 84 85]; loop3: [1 <3> 83 84 85]
			if pos == 0 %if that position is 0, we are done and we can stop looping [but it's not]
				boolDontStop = false;
				break
			end
			vec(pos) = vec(pos) + 1; %otherwise, increase that position's value... loop1: [1 3 82 <83+1=84> 85]; loop2: [1 3 <82+1=83> 84 85]; loop3: [1 <3+1=4> 83 84 85]
			for tpos=pos:endpos-1 
				vec(tpos+1) = vec(tpos) + 1; %and reset the trailing positions to their starting values... loop1: [1 3 82 <84> <84+1=85>]; loop2: [1 3 <83> <83+1=84> <84+1=85>]; loop3: [1 <4> <4+1=5> <5+1=6> <6+1=7>]
			end
		end %after the 2nd position is set to 4, the vector reads  [1 4 5 6 7]; the values are not greater than 84, so the while is no longer true
	end
	%when finished, display the time it took
	dblDur = toc(dblStart);
	fprintf('Done! It took only %.2f seconds for %.0f combinations. That''s pretty fast right? Only %f seconds per cluster!\n',dblDur,counter,dblDur/counter);
end
function [matList] = retrieveDoublePerms(vecIn)
	%returns an n-by-2 matrix of all possible combinations of 2 from the
	%vector vecIn
	%example: vecIn containing [1 2 3] will return [1 2; 1 3; 2 3]
	
	intL = length(vecIn);
	intNumComb = factorial(intL)/(factorial(2)*factorial(intL-2));
	matList = zeros(intNumComb,2,'uint8');
	intIndex = 0;
	for pos1=1:intL
		for pos2=pos1+1:intL
			int1 = vecIn(pos1);
			int2 = vecIn(pos2);
			intIndex = intIndex + 1;
			matList(intIndex,[1 2]) = [int1 int2];
		end
	end
end