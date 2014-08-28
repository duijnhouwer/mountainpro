function [movStruct,movObj] = loadMovie(strMovie,intChannel,movStruct)
	movObj = VideoReader(strMovie);
	
	nFrames = movObj.NumberOfFrames;
	vidHeight = movObj.Height;
	vidWidth = movObj.Width;
	if ~exist('intChannel','var')
		intChannel = 1:3;
		
		% Preallocate movie structure.
		movStruct(1:nFrames) = ...
			struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
			'colormap', []);
	else
		if intChannel == 4
			intChannel = 1:3;
		end
		if ~exist('movStruct','var')
			% Preallocate movie structure.
			movStruct(1:nFrames) = ...
				struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
				'colormap', []);
		end
	end
	% Read one frame at a time.
	for k = 1 : nFrames
		thisFrame = read(movObj, k);
		movStruct(k).cdata(1:vidHeight,1:vidWidth,intChannel) = thisFrame(:,:,intChannel);
	end
	
	% Play back the movie once at the video's frame rate by using:
	%movie(hf, mov, 1, movObj.FrameRate);
end