function mov = playMovie(strMovie,handle)
	movObj = VideoReader(strMovie);
	
	nFrames = movObj.NumberOfFrames;
	vidHeight = movObj.Height;
	vidWidth = movObj.Width;
	
	% Preallocate movie structure.
	mov(1:nFrames) = ...
		struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
		'colormap', []);
	
	% Read one frame at a time.
	for k = 1 : nFrames
		mov(k).cdata = read(movObj, k);
	end
	
	% Size a figure based on the video's width and height.
	if exist('handle','var')
		hf = handle;
	else
		hf = figure;
	end
	
	% Play back the movie once at the video's frame rate.
	movie(hf, mov, 1, movObj.FrameRate);
end