function imOut = imnorm(imIn)
	%UNTITLED2 Summary of this function goes here
	%   Detailed explanation goes here
	imIn = double(imIn);
	if ndims(imIn) == 3
		imOut = zeros(size(imIn));
		for intCh=1:size(imIn,3)
			imInThis = imIn(:,:,intCh);
			imMin = min(imInThis(:));
			imMax = max(imInThis(:));
			
			if imMin == imMax
				imOutThis = zeros(size(imInThis));
			else
				imOutThis = imInThis - imMin;
				imOutThis = imOutThis / max(imOutThis(:));
			end
			imOut(:,:,intCh) = imOutThis;
		end
	else
		imMin = min(imIn(:));
		imMax = max(imIn(:));
		if imMin == imMax
			imOut = ones(size(imIn));
		else
			imOut = imIn - imMin;
			imOut = imOut / max(imOut(:));
		end
	end
end

