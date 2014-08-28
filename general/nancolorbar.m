function hcb = nancolorbar(varargin)
	%UNTITLED2 Summary of this function goes here
	%   Detailed explanation goes here
	matIn = varargin{1};
	if nargin > 1
		cMin = varargin{2}(1);
		cMax = varargin{end}(end);
	else
		cMin = min(matIn(:));
		cMax = max(matIn(:));
	end
	cm = colormap('jet');
	cL = length(cm);
	cStep = (cMax - cMin) / cL;
	caxis([cMin-cStep cMax])
	colormap([1 1 1; cm]);
	
	
	
	
	%# place a colorbar
	hcb = colorbar;
	%# change Y limit for colorbar to avoid showing NaN color
	ylim(hcb,[cMin cMax])
	
end

