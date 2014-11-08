function secs=lkConvertTimeStrToSeconds(strT)
    
    % Convert a string like '1h10m4.13s' into a number of seconds
    % Example: 
    %   lkConvertTimeStrToSeconds('1h10m4.13s')
    
    % Get the hours, if any
    hIdx=find(strT=='h');
    if ~isempty(hIdx)
        nHours=str2double(strT(1:hIdx-1));
    else
        nHours=0;
        hIdx=1;
    end
    % Get the minutes, if any
    mIdx=find(strT=='m');
    if ~isempty(mIdx)
        nMins=str2double(strT(hIdx+1:mIdx-1));
    else
        nMins=0;
        mIdx=1;
    end
    % Get the seconds, if any
    sIdx=find(strT=='s');
    if ~isempty(sIdx)
        nSecs=str2double(strT(mIdx+1:sIdx-1));
    else
        nSecs=0;
    end
    secs=nHours*3600+nMins*60+nSecs;
    
end