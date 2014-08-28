function [ sData, kernel ] = smooth1D( data, kernelSize, kernelMethod )
% function [ sData ] = smooth1D( data, kernelsize, kernelMethod )
% 
% This function smooths a 1d vector using the selected kernel size and
% method
%
% input
% - data:           1D vector containint the data
% - kernelSize:     size of the kernel (int)
% - kernelMethod
%   - 'flat':       kernel contains of even numbers
%   - 'gaussian':   kernel is gaussion distribution of 1 sigma wide
%
% output
% - sData:          smoothed data vector
%
% Written by Pieter Goltstein
% - Version 1.0; December 23rd, 2008
%
error('Use conv instead')

% check and modify data dimensions
[ cols, rows ] = size( data ) ;
if cols > 1 && rows > 1
    error('smooth 1D only works on 1 dimensional data');
elseif cols == 1 && rows > 1
    data = data' ;
    warning( [ 'Smooth1D prefers columnvectors, ' ...
        'data converted to columnvector' ] ) ;
end

% check if the length of the datavector is larger than the kernelSize
if length(data) < kernelSize
    error( [ 'The length of the datavector (=' num2str(length(data)) ...
        ') is not allowed to be smaller than the kernelSize (=' ...
        num2str(kernelSize) ] ) ;
end

% check and modify kernelsize
if mod(kernelSize,2) == 0
    kernelSize = kernelSize + 1;
    warning( [ 'Only odd kernelSizes allowed, ' ...
        'changed kernelSize to ' num2str(kernelSize) ] ) ;
end

% create smoothing kernel
if strcmp( kernelMethod, 'flat' ) == 1
    kernel = ones(kernelSize,1) ;
elseif strcmp( kernelMethod, 'gaussian' ) == 1
    x = linspace( -(kernelSize-1)/2, (kernelSize-1)/2, kernelSize ) ;
    x = x' ;
    kernel = exp( -(x.^2/2)) / sqrt(2*pi) ;
else
    error( [ 'Selected method: ' kernelMethod ' unknown...' ] ) ;
end

% make sure tthat the sum of the kernel equals 1
kernel = kernel / sum(kernel) ;

% add extra values on both sides of the data vector to reduce border
% effects
paddedData = [ ones(kernelSize,1)*mean(data(1:kernelSize)); data; ...
    ones(kernelSize,1)*mean(data(end-(kernelSize-1):end)) ] ;

% smooth data vector
sData = zeros( length(data), 1 );
for i = 1:kernelSize
    start = (kernelSize+1)/2 + i;
    stop  = length(paddedData) - (kernelSize + ((kernelSize+1)/2) ) + i;

%     disp([ num2str(start) '..' num2str(stop) ' * ' num2str(kernel(i)) ]);
    
    sData = sData + paddedData( start:stop ) * kernel(i) ;
end

% % temp disp results
% figure
% subplot(4,1,1)
% plot(data)
% subplot(4,1,2)
% plot(kernel)
% subplot(4,1,3)
% plot(paddedData)
% subplot(4,1,4)
% plot(sData)



