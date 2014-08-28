function [strInfoFile,intFileFormat] = doCheckInputType(strDir,strSes)
	%	2.0 - September 14 2012
	%	Works perfectly; compatible with TwoPhoCoTo 2.0 [by JM]
	
	%check if session includes .mat extension
	if strcmp(strSes(end-3:end),'.mat')
		strInfoFile = strSes;
	else
		strInfoFile = [strSes '.mat'];
	end
	%check if strDir terminates in filesep
	if ~strcmp(strDir(end),filesep)
		strDir = [strDir filesep];
	end
	
	%load structure
	structInfo = load([strDir strInfoFile]);
	
	%define starting variables
	boolCalc_dFoF = false;
	boolCalc_ExpFit = false;
	intFileFormat = 0;
	
	%check formatting version
	if isfield(structInfo,'ses')
		if isfield(structInfo.ses,'info') && isfield(structInfo.ses,'anesth') && isfield(structInfo.ses,'nObj')
			intFileFormat = 1;
			
			%check if dFoF has been calculated
			if ~isfield(structInfo.ses.cells(end),'dFoF')
				boolCalc_dFoF = true;
			elseif isempty(structInfo.ses.cells(end).dFoF)
				boolCalc_dFoF = true;
			end
			
			%check if exponential fitting has been done
			if ~isfield(structInfo.ses.cells(end),'expFit')
				boolCalc_ExpFit = true;
			elseif isempty(structInfo.ses.cells(end).expFit)
				boolCalc_ExpFit = true;
			end
		elseif isfield(structInfo.ses,'neuron') && isfield(structInfo.ses,'anesthesia') && isfield(structInfo.ses,'nObjects')
			intFileFormat = 2;
			
			%check if dFoF has been calculated
			if ~isfield(structInfo.ses.neuron(end),'dFoF')
				boolCalc_dFoF = true;
			elseif isempty(structInfo.ses.neuron(end).dFoF)
				boolCalc_dFoF = true;
			end
			
			%check if exponential fitting has been done
			if ~isfield(structInfo.ses.neuron(end),'expFit')
				boolCalc_ExpFit = true;
				warning('processActivityMatrix:Calc_ExpFit','No ExpFit; however, calculation of exponential fits is not yet calibrated');
			elseif isempty(structInfo.ses.neuron(end).expFit)
				boolCalc_ExpFit = true;
				warning('processActivityMatrix:Calc_ExpFit','No ExpFit; however, calculation of exponential fits is not yet calibrated');
			end
		end
	end
	if intFileFormat == 0
		error('processActivityMatrix:CheckInputType','Unknown file format for file %s in %s',strSes,strDir);
	end
	if boolCalc_dFoF
		if intFileFormat == 1
			error('processActivityMatrix:Calc_dFoF','No dFoF; calculation not supported of dFoF in old format file [%s in %s]',strSes,strDir);
		elseif intFileFormat == 2
			warning('processActivityMatrix:Calc_dFoF','No dFoF; starting calculation of dFoF for file %s in %s',strSes,strDir);
			
			
			%retrieve parameters and loop through cells
			dblBaselineWindowSize = 20;
			intNeurons = structInfo.ses.nNeurons;
			samplingFreq = structInfo.ses.samplingFreq;
			fprintf('\nCalculating dFoF; now at neuron %03d of %03d\n',0,intNeurons);
			for intNeuron=3:intNeurons
				fprintf('\b\b\b\b\b\b\b\b\b\b\b%03.0f of %03.0f\n',intNeuron,intNeurons);
				F = structInfo.ses.neuron(intNeuron).Fch2;
				[dFoF] = calc_dFoF( F, samplingFreq, dblBaselineWindowSize );
				structInfo.ses.neuron(intNeuron).dFoF = dFoF;
			end
			
			%save to file
			ses = structInfo.ses; %#ok<NASGU>
			save([strDir strInfoFile],'ses');
			fprintf('Calculation of dFoF completed\n\n')
		end
	end
	if boolCalc_ExpFit
		if intFileFormat == 1
			error('processActivityMatrix:Calc_ExpFit','No ExpFit; calculation not supported of ExpFit in old format file [%s in %s]',strSes,strDir);
		elseif intFileFormat == 2
			warning('processActivityMatrix:Calc_ExpFit','No ExpFit; starting calculation of ExpFit for file %s in %s',strSes,strDir);
			
			%retrieve parameters and loop through cells
			tau = 0.500 ; % s
			intNeurons = structInfo.ses.nNeurons;
			samplingFreq = structInfo.ses.samplingFreq;
			fprintf('\nCalculating ExpFit; now at neuron %03d of %03d\n',0,intNeurons);
			for intNeuron=1:intNeurons
				fprintf('\b\b\b\b\b\b\b\b\b\b\b%03.0f of %03.0f\n',intNeuron,intNeurons);
				
				F = structInfo.ses.neuron(intNeuron).Fch2;
				[vecExpFit vecSpikeFrames vecSpikeAmount] = calc_ExpFit(F,samplingFreq,tau);
				%{
				vecdFoF = structInfo.ses.neuron(intNeuron).dFoF;
				
				[vecExpFit vecSpikeFrames vecSpikeAmount] = calc_ExpFit(vecdFoF,samplingFreq,tau);
				%}
				structInfo.ses.neuron(intNeuron).apFrames = vecSpikeFrames;
				structInfo.ses.neuron(intNeuron).apSpikes = vecSpikeAmount;
				structInfo.ses.neuron(intNeuron).expFit = vecExpFit;
			end
			
			%save to file
			ses = structInfo.ses; %#ok<NASGU>
			save([strDir strInfoFile],'ses');
			fprintf('Calculation of ExpFit completed\n\n')
		end
	end
end
