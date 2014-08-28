function matBinned = compressMatrix(matRaw,intBins,varargin)
	%compressMatrix Compresses a 1D or 2D matrix by its 2nd dimension
	%   syntax: matBinned = ...
	%				compressMatrix(matRaw,intBins,['binsize'/'binnumber']) 
	%	If the third argument is set to binsize, intBins gives the binsize,
	%	otherwise, intBins gives the approximate number of bins requested
	%
	%	Version history:
	%	1.0 - April 15 2011
	%	Created by Jorrit Montijn
	
	classType = class(matRaw);
	[size1,size2] = size(matRaw);
	
	strBinSize = defaultValues(varargin,'binnumber');
	if strcmp(strBinSize,'binsize')
		dblBinSize = intBins;
	else
		dblBinSize = round(size2/intBins);
	end
	
	size2Binned = ceil(size2/dblBinSize);
	matBinned = zeros(size1,size2Binned,classType);
	for offset=1:dblBinSize
		matTemp = matRaw(:,offset:dblBinSize:size2);
		intSizeDiff = size(matBinned,2) - size(matTemp,2);
		if intSizeDiff ~= 0
			matTemp = padarray(matTemp,[0 intSizeDiff],0,'pre');
		end
		matBinned = matBinned + matTemp;
	end
end