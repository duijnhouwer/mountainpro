function plotClusterDistance(matClusterDistances,varargin)
	%plotClusterDistance Makes an activity map and surface plot of input data.
	%					 It also automatically removes unprocessed cluster
	%					 sizes so intermediate output from clusterCalcSession()
	%					 can also be used as input.
	%syntax: plotClusterDistance(matClusterDistances)
	%	input:
	%	- matClusterDistances: matrix containing binned clustering data (output
	%	  of clusterCalcSession)
	%	output:
	%	- Two graphs
	%
	%	Version history:
	%	1.0 - April 21 2011
	%	Created by Jorrit Montijn
	%	2.0 - September 14 2012
	%	Changed to work with new clusterCalcSession() function [by JM]
	
	%% Define and/or transform initial variables
	msg = defaultValues(varargin,'');
	binVecOrig = 0:1:300;
	binVec = 0:10:300;
	
	intFirstClusterSize = 2;
	intUndone = 0;
	intClusters = size(matClusterDistances,2);
	for intClust=1:intClusters
		vecClust = matClusterDistances(:,intClust);
		boolDone = max(~isnan(vecClust));
		if ~boolDone
			intUndone = intClust;
			intDone = intUndone - 1;
			vecClusterSize = intFirstClusterSize:intFirstClusterSize+intDone-1;
			matOut = matClusterDistances(:,1:intDone);
			break;
		end
	end
	if boolDone
		matOut = matClusterDistances;
		vecClusterSize = intFirstClusterSize:intFirstClusterSize+size(matClusterDistances,2)-1;
	end
	
	%% Plot activity map
	xV = [1 length(vecClusterSize)];
	yV = [1 length(binVec)];
	figure
	imagesc(xV,yV,matOut,[0 max(max(matOut(:)),0.1)])
	set(gca,'XTick',1:length(vecClusterSize),'XTickLabel',vecClusterSize)
	set(gca,'YTick',1:5:length(binVec),'YTickLabel',binVec(1:5:end))
	colorbar
	title(['Input: ' inputname(1) ', ' msg '  Mean covariance (Z) per mean distance of cells in one cluster (Y) per cluster size (X)'])
	
	ylabel('Mean distance per cluster')
	xlabel('Cluster size')
	
	
	%% Make surface plot
	%{
	figure
	surf(vecClusterSize,binVecOrig,matOut);
	title(msg)
	zlabel(['Input: ' inputname(1) ', Mean covariance per distance per cluster'])
	ylabel(['Mean distance between cells in one cluster'])
	xlabel('Cluster size')
	set(gca,'XTick',vecClusterSize)
	%}
	%% Aaaand... We're done!
	fprintf('Done with distance plotting\n')
	
end

