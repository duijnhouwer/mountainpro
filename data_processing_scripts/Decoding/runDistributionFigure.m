vecMultiOSI = [];
vecMultiNC = [];
vecMultiSC = [];


for intSes=1:6
	if intSes==1
		strSes= '20120718';
		strRec= 'xyt01';
	elseif intSes==2
		strSes= '20120718';
		strRec= 'xyt03';
	elseif intSes==3
		strSes= '20120720';
		strRec= 'xyt01';
	elseif intSes==4
		strSes= '20120720';
		strRec= 'xyt03';
	elseif intSes==5
		strSes= '20121207';
		strRec= 'xyt01';
	elseif intSes==6
		strSes= '20121207';
		strRec= 'xyt02';
	end
	%get ses
	vecTime = fix(clock);
	fprintf('   Now running %s%s; time is [%02.0f:%02.0f:%02.0f]\n',strSes,strRec,vecTime(4),vecTime(5),vecTime(6))
	strDir=['D:\Data\Processed\imagingdata\' strSes filesep strRec filesep];
	strFile=[strSes strRec '_ses.mat'];
	structIn = load([strDir strFile]);
	
	%def vars
	intNeurons = length(structIn.ses.neuron);
	
	intStims = length(structIn.ses.structStim.Orientation);
	structIn.vecIncludeCells = 1:intNeurons;
	structIn.doPlot = false;
	structIn.intApproxFlag = 1;
	structIn.vecStimTypeLookup = 0:45:359;
	
	%get correlations
	fprintf('Retrieving noise and signal correlation matrices...\n');
	sCorrs = calcStimCorrs(structIn.ses);
	matSignalCorrs = sCorrs.matSignalCorrs;
	matNoiseCorrs = sCorrs.matNoiseCorrs;
	intCombs = round((factorial(intNeurons)./factorial(intNeurons)-2)/2);
	intPos = 0;
	vecSC = nan(1,intCombs);
	vecNC = nan(1,intCombs);
	for intNeuron1=1:intNeurons
		for intNeuron2=(intNeuron1+1):intNeurons
			intPos = intPos + 1;
			vecSC(intPos) = matSignalCorrs(intNeuron1,intNeuron2);
			vecNC(intPos) = matNoiseCorrs(intNeuron1,intNeuron2);
		end
	end
	
	%get OSI
	fprintf('Retrieving orientation selectivity indices...\n');
	vecOSI = nan(1,intNeurons);
	for intNeuron=1:intNeurons
		[structActivity,matAct_TypeByRep,vecStimTypeLookup,sOut] = calcTuning(structIn.ses,intNeuron,structIn);
		[pHOTori,pHOTdir,vecTuningParams,structTuningProperties] = testTuning(matAct_TypeByRep,vecStimTypeLookup,structIn.doPlot);
		vecOSI(intNeuron) = structTuningProperties.OSI;
	end
	
	
	vecMultiOSI = [vecMultiOSI vecOSI]; %#ok<*AGROW>
	vecMultiNC = [vecMultiNC vecNC];
	vecMultiSC = [vecMultiSC vecSC];
end

h=figure;
subplot(3,1,1)
intStep = 0.05;
hist(vecMultiOSI,intStep:intStep:(1-intStep))
xlabel('OSI')
ylabel('number of neurons')
subplot(3,1,2)
intStep = 0.05;
hist(vecMultiNC,(-1+intStep):intStep:(1-intStep))
xlabel('Noise Correlation')
ylabel('number of pairs')
subplot(3,1,3)
intStep = 0.05;
hist(vecMultiSC,(-1+intStep):intStep:(1-intStep))
xlabel('Signal Correlation')
ylabel('number of pairs')

set(h,'Color',[1 1 1])

%save figure
strFigEps = ['D:\Data\Results\decoding\DecodingDistribution.eps'];
export_fig(strFigEps)
strFigTif = ['D:\Data\Results\decoding\DecodingDistribution.tiff'];
export_fig(strFigTif)