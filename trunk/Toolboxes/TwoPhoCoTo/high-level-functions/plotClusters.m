function plotClusters(matClusterData,varargin)
	%plotClusters Makes an activity map and surface plot of input data. It also
	%			  automatically removes unprocessed cluster sizes so
	%			  intermediate output from clusterCalcSession() can also be
	%			  used as input.
	%syntax: plotClusters(matClusterData)
	%	input:
	%	- matClusterData: matrix containing binned clustering data (output of
	%	  clusterCalcSession)
	%	output:
	%	- Two graphs
	%
	%	Version history:
	%	1.0 - April 20 2011
	%	Created by Jorrit Montijn
	%	2.0 - September 14 2012
	%	Changed to work with new clusterCalcSession() function [by JM]
	
	%% Define and/or transform initial variables
	msg = defaultValues(varargin,'');
	stepsize = 1/100;
	binVec = -1:stepsize:1;
	
	intFirstClusterSize = 3;
	intUndone = 0;
	intClusters = size(matClusterData,2);
	for intClust=1:intClusters
		vecClust = matClusterData(:,intClust);
		boolDone = max(~isnan(vecClust));
		if ~boolDone
			intUndone = intClust;
			intDone = intUndone - 1;
			vecClusterSize = intFirstClusterSize:intFirstClusterSize+intDone-1;
			matOut = matClusterData(:,1:intDone);
			break;
		end
	end
	if boolDone
		matOut = matClusterData;
		vecClusterSize = intFirstClusterSize:intFirstClusterSize+size(matClusterData,2)-1;
	end
	
	%% Plot activity map
	xV = [1 length(vecClusterSize)];
	yV = [length(binVec) 1];
	figure
	imagesc(xV,yV,matOut)
	
	cm = colormap('jet');
	if strcmp(inputname(1),'matOutDiff')
		%insert nans
		
		cL = length(cm);
		cMin = -100;
		cMax = 100;
		cStep = (cMax - cMin) / cL;
		caxis([cMin-cStep cMax])
		colormap([1 1 1; cm]);
		
		mMin = min(matOut(:));
		mMax = max(matOut(:));
		
		
		%# place a colorbar
		hcb = colorbar;
		%# change Y limit for colorbar to avoid showing NaN color
		ylim(hcb,[cMin cMax])
	else
		colorbar
	end
	
	set(gca,'XTick',1:2:length(vecClusterSize),'XTickLabel',vecClusterSize(1:2:end))
	set(gca,'YTick',1:25:201,'YTickLabel',binVec(end:-25:1))
	%colorbar
	if isempty(msg)
		title(['Input' inputname(1) ', Binned mean correlation per cluster for different cluster sizes']);
	else
		title(['Input: ' inputname(1) ', ' msg])
	end
	
	ylabel('Mean correlation')
	xlabel('Cluster size')
	
	%% Make surface plot
	%{
	figure
	surf(vecClusterSize,binVec,matOut);
	title(msg)
	zlabel(['Input: ' inputname(1) ', Fraction of maximum cluster count'])
	ylabel(['Mean covariance per cluster'])
	xlabel('Cluster size')
	set(gca,'XTick',vecClusterSize)
	%}
	%% Aaaand... We're done!
	fprintf('Done with correlation plotting\n')
	drawnow;
end

