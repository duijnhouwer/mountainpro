function varargout = defaultValues(suppliedArgs,varargin)
	%defaultValues Returns supplied values if they exist, otherwise returns defaults
	%   syntax: [variables] = defaultValues(varargin,defaultvalues)
	%
	%	This function can be used to get rid of matlab's annoying
	%	check-if-an-argument-is-supplied-and-otherwise-assign-a-default-value
	%	problem. defaultValues will output to your variables the supplied
	%	argument if any and otherwise your default values.
	%	For example, suppose you have a function called arbitraryFunction()
	%	with 2 fixed arguments and 2 optional arguments. At the top of
	%	arbitraryFunction() put this:
	%
	%	arbitraryOutputVariable = arbitraryFunction(fixedInput1,fixedInput2,varargin)
	%
	%	Then define your optional arguments like this:
	%
	%	[optionalArgument1,optionalArgument2] = defaultValues(varargin,'a string',4)
	%
	%	defaultValues will now check if varargin contains the optional
	%	arguments (and if they're not empty). If the user supplied a value,
	%	defaultValues will return that value. Otherwise, optionalArgument1
	%	will receive the value 'a string' and/or optionalArgument2 will
	%	receive the value 4.
	%
	%		Version history:
	%		1.0 - April 6 2011
	%			Created by Jorrit Montijn
	
	numsup = length(suppliedArgs);
	numarg = length(varargin);
	for argNum=1:numarg %#ok<FORPF>
		thisDefault = varargin{argNum};
		if numsup < argNum
			varargout{argNum} = thisDefault;
		else
			thisSup = suppliedArgs{argNum};
			if isempty(thisSup)
				varargout{argNum} = thisDefault;
			else
				varargout{argNum} = thisSup;
			end
		end
	end
end

