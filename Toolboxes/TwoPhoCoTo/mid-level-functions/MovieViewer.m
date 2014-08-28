% MOVIEVIEWER	Program for creating movies from pictures and
%				viewing/editing them. It can load and/or edit red, green
%				and blue channels separately. Uses automatic channel and
%				frame index detection of picture files with the following
%				syntax:
%					*[0-inf]_ch[00-02].ext
%				The last 4 characters can be anything (i.e., the extension).
%				Numerical characters 5 and 6 from the end counting
%				backwards indicate the channel; 00=R;01=G;02=B.
%				Numerical characters 10+ from the end counting backwards
%				indicate the framenumber, starting at 0. However, all
%				framenumbers must contain the same amount of characters, so
%				if you use 1000 frames, you must use 000-999 (or 0000-0999);
%				but if you use 1001 frames, you must use at least 4
%				characters for frame indexing (0000-1000).
%				Example filename with correct syntax:
%					pxyt06_t0009_ch01.tif
%				This file will be read as frame 10 (0009) containing the
%				green channel (01).
%
%	Version history:
%	1.0 - September 16 2011
%	Created by Jorrit Montijn
%	1.1 - December 13 2011
%	Added support for mpeg files with mmread()

%#ok<*DEFNU>
%#ok<*INUSL>
%#ok<*VANUS>
%#ok<*INUSD>
%#ok<*NASGU>
%#ok<*CTPCT>
%#ok<*ASGLU>
%#ok<*FORPF>

%% CORE FUNCTION
function varargout = MovieViewer(varargin)
	% MOVIEVIEWER Program for playback of avifiles
	
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @MovieViewer_OpeningFcn, ...
		'gui_OutputFcn',  @MovieViewer_OutputFcn, ...
		'gui_LayoutFcn',  [] , ...
		'gui_Callback',   []);
	if nargin && ischar(varargin{1})
		gui_State.gui_Callback = str2func(varargin{1});
	end
	
	if nargout
		[varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
	else
		gui_mainfcn(gui_State, varargin{:});
	end
	
	%% INITIALIZATION SEQUENCE
function MovieViewer_OpeningFcn(hObject, eventdata, handles, varargin)
	% This function has no output args, see OutputFcn.
	% hObject    handle to figure
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	% varargin   command line arguments to MovieViewer (see VARARGIN)
	
	%{
	%Put image at button location
	[a,map]=imread('buttonNext.jpg');
	[r,c,d]=size(a);
	x=ceil(r/10);
	y=ceil(c/10);
	g=a(1:x:end,1:y:end,:);
	g(g==255)=5.5*255;
	set(handles.buttonNext,'CData',g);
	%}
	
	% Choose default command line output for MovieViewer
	handles.output = hObject;
	
	%set initial values
	setappdata(gcf,'intChannel',4);
	setappdata(gcf,'loadingType','overwrite');
	set(handles.selectGroup,'SelectionChangeFcn',@loadingType_SelectionChangeFcn);
	
	% Update handles structure
	guidata(hObject, handles);
	
	
	%% OUTPUT FUNCTION
function varargout = MovieViewer_OutputFcn(hObject, eventdata, handles)
	% varargout  cell array for returning output args (see VARARGOUT);
	% hObject    handle to figure
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Get default command line output from handles structure
	varargout{1} = handles.output;
	
	%% STOP PLAY LOOP
function buttonStill_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonStill (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	if getappdata(gcf,'nowPlaying') || getappdata(gcf,'nowForward') || getappdata(gcf,'nowRewind')
		setappdata(gcf,'nowPlaying',false);
		setappdata(gcf,'nowForward',false);
		setappdata(gcf,'nowRewind',false);
		strMessage = sprintf('Movie set to still');
		setMessage(hObject,eventdata,handles,strMessage);
	end
	
	%% START PLAY LOOP
function buttonPlay_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonPlay (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	%get/set data
	boolCheck = true;
	intMaxFrame = getappdata(gcf,'maxFrame');
	intFrameRate = double(getappdata(gcf,'framerate'));
	if isempty(intFrameRate) || intFrameRate == 0
		return;
	end
	FrameDuration = 1/intFrameRate;
	intFrame = getappdata(gcf,'framenumber');
	if intFrame == intMaxFrame
		intFrame = 1;
	end
	setappdata(gcf,'nowPlaying',true);
	setappdata(gcf,'nowForward',false);
	setappdata(gcf,'nowRewind',false);
	
	strMessage = sprintf('Playing with framerate of %dHz',intFrameRate);
	setMessage(hObject,eventdata,handles,strMessage);
	
	%retrieve data
	movStruct = getappdata(gcf,'movStruct');
	movObj = getappdata(gcf,'movObj');
	
	%do looping
	tStart = tic;
	while getappdata(gcf,'nowPlaying')
		intFrame = intFrame + 1;

		%draw
		imshow(movStruct(intFrame).cdata);
		drawnow;
		
		%check if done
		if intFrame >= intMaxFrame
			setappdata(gcf,'nowPlaying',false);
			strMessage = sprintf('Movie finished playing');
			setMessage(hObject,eventdata,handles,strMessage);
		end
		if boolCheck
			drawingTime = toc(tStart);
			timeToNextFrame = FrameDuration - drawingTime;
			if timeToNextFrame < 0
				if intFrame > 5 %there's always an initial delay
					boolCheck = false;
					strMessage = sprintf('Warning: unable to play at required speed',intFrame,intMaxFrame);
					setMessage(hObject,eventdata,handles,strMessage);
				end
			else
				pause(timeToNextFrame);
			end
			tStart = tic;
		end
	end
	setFrameTo(hObject,eventdata,handles,intFrame);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% FRAMENUMBER BUTTON
function windowFramenumber_Callback(hObject, eventdata, handles)
	% hObject    handle to windowFramenumber (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hints: get(hObject,'String') returns contents of windowFramenumber as text
	%        str2double(get(hObject,'String')) returns contents of windowFramenumber as a double
	
	%store the contents of windowFramenumber as a string. if the string
	%is not a number then input will be empty
	
	%get frame
	intFramenumber = uint64(str2double(get(hObject,'String')));
	
	%set frame
	setFrameTo(hObject, eventdata, handles,intFramenumber)
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% SET-TO FUNCTIONS
	%% SET FRAME AND SHOW IT
function setFrameTo(hObject, eventdata, handles,intFramenumber)
	%retrieve data
	movStruct = getappdata(gcf,'movStruct');
	movObj = getappdata(gcf,'movObj');
	
	%check data
	if ischar(intFramenumber)
		intFramenumber = round(str2double(intFramenumber));
	end
	if isempty(intFramenumber)
		error('setFrameTo','Attempt to set frame to non-integer');
	elseif isempty(movObj)
		%set data
		intFramenumber = 0;
		setappdata(gcf,'framenumber',intFramenumber);
		set(handles.windowFramenumber,'String',intFramenumber);
		cla
	else
		maxFrame = getappdata(gcf,'maxFrame');
		if intFramenumber < 1
			intFramenumber = 1;
		elseif intFramenumber > maxFrame
			intFramenumber = maxFrame;
		end
		%set data
		setappdata(gcf,'framenumber',intFramenumber);
		set(handles.windowFramenumber,'String',intFramenumber);
		
		%show frame
		if intFramenumber == 0
			cla
		else
			imshow(movStruct(intFramenumber).cdata);
			drawnow;
		end
	end
	% Update handles structure
	guidata(hObject, handles);
	
	%% SET FRAMERATE
function setFrameRateTo(hObject, eventdata, handles,intFrameRate)
	%retrieve data
	movObj = getappdata(gcf,'movObj');
	if isempty(movObj)
		curFR = 0;
	else
		%checks to see if input is wrong. if so, default
		if ischar(intFrameRate)
			intFrameRate = round(str2double(intFrameRate));
		end
		if (isempty(intFrameRate))
			curFR = movObj.FrameRate;
		elseif intFrameRate < 1 || intFrameRate > 60
			curFR = movObj.FrameRate;
		else
			curFR = intFrameRate;
		end
	end
	setappdata(gcf,'framerate',curFR);
	set(handles.FRText,'String',num2str(curFR)); %display framerate
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% SET FILENAME
function setFilenameTo(hObject, eventdata, handles,strMovie)
	
	%set data
	setappdata(gcf,'filename',strMovie);
	set(handles.fileText,'String',strMovie); %display filename
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% SET MESSAGE TO
function setMessage(hObject,eventdata,handles,strMessage)
	%append timestamp
	strMessage = ['Last Message: [' strMessage '] at ' datestr(now,'HH:MM:SS')];
	
	%set message
	set(handles.messageBlock,'String',strMessage);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% SET MARKER IN TO
function setMarkerInTo(hObject, eventdata, handles,intFrameIn)
	
	intFrameOut = getappdata(gcf,'intFrameOut');
	intMaxFrame = getappdata(gcf,'maxFrame');
	if isempty(intMaxFrame) || intMaxFrame == 0
		intFrameIn = 0;
	elseif intFrameIn > intFrameOut
		intFrameIn = intFrameOut;
	elseif intMaxFrame < intFrameIn
		intFrameIn = intMaxFrame;
	elseif intFrameIn < 1
		intFrameIn = 1;
	end
	%set data
	setappdata(gcf,'intFrameIn',intFrameIn);
	set(handles.windowFrameIn,'String',intFrameIn);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% SET MARKER OUT TO
function setMarkerOutTo(hObject, eventdata, handles,intFrameOut)
	intFrameIn = getappdata(gcf,'intFrameIn');
	intMaxFrame = getappdata(gcf,'maxFrame');
	if isempty(intMaxFrame) || intMaxFrame == 0
		intFrameOut = 0;
	elseif intFrameOut < 1
		intFrameOut = 1;
	elseif intFrameIn > intFrameOut
		intFrameOut = intFramein;
	elseif intMaxFrame < intFrameOut
		intFrameOut = intMaxFrame;
	end
	%set data
	setappdata(gcf,'intFrameOut',intFrameOut);
	set(handles.windowFrameOut,'String',intFrameOut);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% SET MAXFRAME
function setMaxFrameTo(hObject, eventdata, handles,intMaxFrame)
	setappdata(gcf,'maxFrame',intMaxFrame)
	set(handles.maxFrameText,'String',num2str(intMaxFrame)) %set max frame number
	movObj = getappdata(gcf,'mobObj');
	movObj.NumberOfFrames = intMaxFrame;
	setappdata(gcf,'movObj',movObj);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% INITIALIZE FRAMENUMBER
function windowFramenumber_CreateFcn(hObject, eventdata, handles)
	% hObject    handle to windowFramenumber (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    empty - handles not created until after all CreateFcns called
	
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	%% OPEN FILES AS MOVIE
function [movStruct,frameCounter] = assignFrames(hObject, eventdata, handles,pathvar,cellFiles,movObj,intChannel,movStruct)
	frameCounter = 1;
	if exist('intChannel','var')
		%determine properties
		Im = imread([pathvar cellFiles{1}]);
		[vidHeight,vidWidth,z]=size(Im);
		
		if exist('movStruct','var')
			boolFuse = true;
			oldMov = movStruct;
			clear movStruct;
		else
			boolFuse = false;
		end
		%pre-allocate
		movStruct(1:movObj.NumberOfFrames) = ...
			struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
			'colormap', []);
		
		if intChannel == 4
			frameCounter = 1;
			startCounter = inf;
			structSize = length(movStruct);
			
			%determine frame location
			strFile = cellFiles{1};
			intLength = length(strFile);
			thisPos = intLength-1;
			boolKeepLooking = true;
			while boolKeepLooking
				thisPos = thisPos - 1;
				thisString = strFile(end-thisPos:end-9);
				thisVal = str2double(thisString);
				if ~isempty(thisVal) && ~isnan(thisVal)
					boolKeepLooking = false;
					boolFound = true;
				elseif thisPos == 9
					boolKeepLooking = false;
					boolFound = false;
					cla
					text(0.1,0.5,sprintf('Error: Unable to detect frame index; trying supplied ordering'),'FontSize',24,'Units','normalized')
					drawnow
				end
			end
			if ~boolFound
				boolKeepLooking = true;
				while boolKeepLooking
					boolKeepLooking = false;
				end
			end
			%loop
			for i=1:movObj.NumberOfFrames
				strFile = cellFiles{i};
				
				if boolFound
					%retrieve channel and frame number
					strCh = strFile(end-4);
					intCh = str2double(strCh)+1;
					strFrame = strFile(end-thisPos:end-9);
					retrieveCh = 1;
					
					%calculate correct frame
					intFrame = str2double(strFrame)+1;
					frameCounter = max(frameCounter,intFrame);
					startCounter = min(startCounter,intFrame);
				else
					%assume RGB input
					strCh = '1:3';
					intCh = 1:3;
					strFrame = 'i';
					retrieveCh = 1:3;
					
					%set correct frame
					intFrame = i;
					frameCounter = i;
					startCounter = 1;
				end
				
				%read image and put into structure
				Im = imread([pathvar cellFiles{i}]);
				if intFrame > structSize
					%allocate additional frames if necessary
					movStruct((structSize+1):intFrame) = ...
						struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
						'colormap', []);
					
					structSize = intFrame;
				end
				movStruct(intFrame).cdata(:,:,intCh) = Im(:,:,retrieveCh);
			end
			%crop
			movStruct = movStruct(startCounter:frameCounter);
			
			if boolFuse
				%determine frames
				startFrame = getappdata(gcf,'intFrameIn');
				stopFrame = getappdata(gcf,'intFrameOut');
				vecFrames = startFrame:stopFrame;
				if length(vecFrames) > frameCounter
					vecFrames = vecFrames(1:frameCounter);
				end
				%retrieve loading type
				strType = getappdata(gcf,'loadingType');
				
				%fuse sequences
				[movOut,movObj] = editSequence(hObject, eventdata, handles,1:3,oldMov,movStruct,vecFrames,strType);
				clear movStruct;
				movStruct = movOut;
			end
			
			
		else
			%assign frames
			for i=1:movObj.NumberOfFrames
				Im = imread([pathvar cellFiles{i}]);
				movStruct(i).cdata(1:vidHeight,1:vidWidth,intChannel) = Im(:,:,1);
			end
			if boolFuse
				%determine frames
				startFrame = getappdata(gcf,'intFrameIn');
				stopFrame = getappdata(gcf,'intFrameOut');
				vecFrames = startFrame:stopFrame;
				frameCounter = movObj.NumberOfFrames;
				if length(vecFrames) > frameCounter
					vecFrames = vecFrames(1:frameCounter);
				end
				%retrieve loading type
				strType = getappdata(gcf,'loadingType');
				
				%fuse sequences
				[movOut,movObj] = editSequence(hObject, eventdata, handles,intChannel,oldMov,movStruct,vecFrames,strType);
				clear movStruct;
				movStruct = movOut;
			end
			setappdata(gcf,'movObj',movObj);
		end
	else
		%determine properties
		Im = imread([pathvar cellFiles{1}]);
		[vidHeight,vidWidth,z]=size(Im);
		
		%pre-allocate
		movStruct(1:movObj.NumberOfFrames) = ...
			struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
			'colormap', []);
		
		%assign frames
		for i=1:movObj.NumberOfFrames
			Im = imread([pathvar cellFiles{i}]);
			movStruct(i).cdata = Im;
		end
	end
	
	% Update handles structure
	guidata(hObject, handles);
	
	
	%% GO BACK ONE FRAME
function buttonPrev_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonPrev (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	%retrieve data
	strFrame = get(handles.windowFramenumber,'String');
	intFrame = str2double(strFrame)-1;
	
	%set data
	setFrameTo(hObject, eventdata, handles,intFrame);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% GO FORWARD ONE FRAME
function buttonNext_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonNext (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	%retrieve data
	strFrame = get(handles.windowFramenumber,'String');
	intFrame = str2double(strFrame)+1;
	
	%set data
	setFrameTo(hObject, eventdata, handles,intFrame);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% CHANGE FRAMERATE
function FRText_Callback(hObject, eventdata, handles)
	% hObject    handle to FRText (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hints: get(hObject,'String') returns contents of FRText as text
	%        str2double(get(hObject,'String')) returns contents of FRText as a double
	
	%get data
	intFR = uint64(str2double(get(hObject,'String')));
	
	%set data
	setFrameRateTo(hObject, eventdata, handles,intFR)
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% CREATE BUTTON
function FRText_CreateFcn(hObject, eventdata, handles)
	% hObject    handle to FRText (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    empty - handles not created until after all CreateFcns called
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	%% LOAD MOVIE
function [movStruct,movObj] = loadMovie(hObject, eventdata, handles,strMovie,intChannel,movStructIn)
	movObj = VideoReader(strMovie);
	nFrames = movObj.NumberOfFrames;
	
	if isempty(nFrames)
		movStruct = [];
	else
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
	end
	
	if isempty(movStruct)
		clear movObj;
		disableVideo = false;
		disableAudio = true;
		trySeeking = false;
		useFFGRAB = true;
		vecFrames = 1:100;
		[video, audio] = mmread(strMovie, vecFrames, [], disableVideo, disableAudio, '', trySeeking, useFFGRAB);
		movObj.Width = video.width;
		movObj.Height = video.width;
		movObj.NumberOfFrames = length(vecFrames);
		movStruct=video.frames;
		movObj.FrameRate=video.rate;
		clear video
		clear audio
	end
	if isempty(movStruct)
		strMessage = sprintf('Unable to open movie file');
		cla
		text(0.1,0.5,strMessage,'FontSize',24,'Units','normalized','Interpreter','none')
		drawnow
	end
	
	%fuse
	if exist('movStructIn','var')
		%determine frames
		startFrame = getappdata(gcf,'intFrameIn');
		stopFrame = getappdata(gcf,'intFrameOut');
		vecFrames = startFrame:stopFrame;
		frameCounter = movObj.NumberOfFrames;
		if length(vecFrames) > frameCounter
			vecFrames = vecFrames(1:frameCounter);
		end
		%retrieve loading type
		strType = getappdata(gcf,'loadingType');
		
		%fuse sequences
		movOut = editSequence(hObject, eventdata, handles,intChannel,movStructIn,movStruct,vecFrames,strType);
		clear movStruct;
		movStruct = movOut;
	end
	
	
	%% LOAD BUTTON
function buttonOpenChannel_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonOpenChannel (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	%avoid unnecessary tex interpreting
	set(0, 'defaultTextInterpreter', get(0, 'factoryTextInterpreter'));
	
	% Get the supported file formats.
	formats = VideoReader.getFileFormats();
	filterSpecM = getFilterSpec(formats);
	filterSpecP = {'*.jpg;*.jpeg;*.tif','All Picture Files (*.jpg;*.tif)'};
	filterSpec = [filterSpecP; filterSpecM];
	
	%open file
	[cellFiles,pathvar] = native_uigetfile(...
		filterSpec,...
		'Pick a file','MultiSelect','on');
	%pathvar = '';
	%[cellFiles] = uipickfiles(...
	%'Type',filterSpec);
	%'Pick a file',...
	%'MultiSelect','on'...
	
	
	if ~iscell(cellFiles)
		if cellFiles == 0
			return
		end
	end
	%retrieve data
	intChannel = getappdata(gcf,'intChannel');
	movStruct = getappdata(gcf,'movStruct');
	
	%define channel names
	cellChannelName{1} = 'Red';
	cellChannelName{2} = 'Green';
	cellChannelName{3} = 'Blue';
	cellChannelName{4} = 'RGB';
	
	listPictsExt = {'jpg';'jpeg';'tif'};
	listMovieExt = filterSpecM{1,1};
	if ischar(cellFiles) == 1
		strMovie = cellFiles;
		strExt = cellFiles(end-2:end);
		if ismember(strExt,listMovieExt)
			%clear figure and print text
			cla
			text(0.1,0.5,[sprintf('Loading: \n<') strMovie sprintf('>\non channel ') cellChannelName{intChannel}],'FontSize',24,'Units','normalized','Interpreter','none')
			drawnow
			
			%load movie
			if isempty(movStruct)
				[movStruct,movObj] = loadMovie(hObject, eventdata, handles,[pathvar strMovie],intChannel);
			else
				[movStruct,movObj] = loadMovie(hObject, eventdata, handles,[pathvar strMovie],intChannel,movStruct);
			end
		else
			cla
			text(0.1,0.5,[sprintf('Failure to load movie file:\n') strMovie sprintf('\nis not a supported movie\n')],'FontSize',24,'Units','normalized','Interpreter','none');
			drawnow;
			return;
		end
		
	else
		%assign default values
		movObj.FrameRate = 15;
		movObj.NumberOfFrames = length(cellFiles);
		strMovie = pathvar;
		strFile = cellFiles{1};
		strExt = strFile(end-2:end);
		if ismember(strExt,listPictsExt)
			%clear figure and print text
			cla
			text(0.1,0.5,[sprintf('Loading: \n') strMovie],'FontSize',24,'Units','normalized','Interpreter','none')
			drawnow
			
			%create movie from files
			if isempty(movStruct)
				[movStruct,movObj.NumberOfFrames] = assignFrames(hObject, eventdata, handles,pathvar,cellFiles,movObj,intChannel);
			else
				[movStruct,movObj.NumberOfFrames] = assignFrames(hObject, eventdata, handles,pathvar,cellFiles,movObj,intChannel,movStruct);
			end
		else
			cla
			text(0.1,0.5,[sprintf('Failure to load picture files:\n') strFile sprintf('\nis not a supported movie\n')],'FontSize',24,'Units','normalized','Interpreter','none');
			drawnow;
			return;
		end
	end
	if isempty(movStruct)
		return;
	end
	
	%set vars
	setappdata(gcf,'movStruct',movStruct);
	setappdata(gcf,'movObj',movObj);
	setappdata(gcf,'nowPlaying',false);
	setappdata(gcf,'nowForward',false);
	setappdata(gcf,'nowRewind',false);
	intFrameRate = movObj.FrameRate;
	intMaxFrames = length(movStruct);
	strMessage = ['<' strMovie '> loaded'];
	
	%set data
	setFilenameTo(hObject, eventdata, handles,strMovie);
	setMaxFrameTo(hObject, eventdata, handles,intMaxFrames);
	setFrameRateTo(hObject, eventdata, handles,intFrameRate);
	setFrameTo(hObject, eventdata, handles,1);
	setMarkerOutTo(hObject, eventdata, handles,intMaxFrames);
	setMarkerInTo(hObject, eventdata, handles,1);
	setMessage(hObject,eventdata,handles,strMessage);
	
	% Update handles structure
	guidata(hObject, handles);
	
	
	%% SELECT CHANNEL
function selectChannel_Callback(hObject, eventdata, handles)
	% hObject    handle to selectChannel (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hints: contents = cellstr(get(hObject,'String')) returns selectChannel contents as cell array
	%        contents{get(hObject,'Value')} returns selected item from selectChannel
	setappdata(gcf,'intChannel',get(hObject,'Value'));
	
	%% CREATE BUTTON
function selectChannel_CreateFcn(hObject, eventdata, handles)
	% hObject    handle to selectChannel (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    empty - handles not created until after all CreateFcns called
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	
	%% CLEAR ALL DATA
function buttonClear_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonClear (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	strMessage = 'All data cleared';
	setappdata(gcf,'nowPlaying',false)
	setappdata(gcf,'nowForward',false);
	setappdata(gcf,'nowRewind',false);
	setappdata(gcf,'movStruct',[])
	setappdata(gcf,'movObj',[])
	setFrameTo(hObject, eventdata, handles,0);
	setFrameRateTo(hObject, eventdata, handles,15);
	setFilenameTo(hObject, eventdata, handles,'No File Loaded');
	setMaxFrameTo(hObject, eventdata, handles,0);
	setMarkerInTo(hObject, eventdata, handles,0);
	setMarkerOutTo(hObject, eventdata, handles,0);
	setMessage(hObject,eventdata,handles,strMessage)
	
	%% RESCALE CUBE
function newCube = rescaleCube(oldCube,scaleFactor,padSize)
	%rescaleCube: rescales a 2D or 3D matrix by a certain scale. It can
	%optionally create zero-padded edges to increase the result to a
	%certain size.
	%
	%syntax: newCube = rescaleCube(I, scale factor[, padding size]).
	%Arguments within [] are optional.
	%	I: input image. Must be 2D or 3D matrix with identical x-y size,
	%		but z-size may vary (for rescaling); can be any size if only
	%		padded and scaleFactor == 1
	%	scale factor: scaling factor relative to original. 0.5 will make the
	%		output twice as small.
	%	padding size: applies zero-padding around the edges to increase the
	%		size of the scaled matrix. Must be an integer. It is an
	%		optional parameter and if not supplied no padding is performed.
	
	usePadding = 1;
	if ~exist('padSize','var')
		usePadding = 2;
		padSize = max(size(oldCube))*scaleFactor;
	elseif isempty(padSize)
		usePadding = 2;
		padSize = max(size(oldCube))*scaleFactor;
	end
	padSize = round(padSize);
	
	%%% Rescale xy
	if scalefactor > 0 && scalefactor ~= 1
		stack3D = imresize(oldCube,scaleFactor);
	else
		stack3D = oldCube;
	end
	if usePadding == 1
		padNum = (padSize - size(stack3D,1))/2;
		stack3D = padarray(stack3D,[floor(padNum) floor(padNum)],0,'pre');
		stack3D = padarray(stack3D,[ceil(padNum) ceil(padNum)],0,'post');
	end
	
	%%% Rescale z
	maxZ = size(oldCube,3);
	newMaxZ = round(scaleFactor * maxZ);
	zSize = [padSize newMaxZ];
	newCube = zeros([padSize padSize zSize(usePadding)],class(oldCube));
	for sliceNum=1:padSize
		thisSlice(:,:,1) = stack3D(sliceNum,:,:);
		if scalefactor > 0 && scalefactor ~= 1
			scaledSlice = imresize(thisSlice,[padSize newMaxZ]);
		else
			scaledSlice = thisSlice;
		end
		if usePadding == 1
			padNum = (padSize - size(scaledSlice,2))/2;
			scaledSlice = padarray(scaledSlice,[0 floor(padNum)],0,'pre');
			scaledSlice = padarray(scaledSlice,[0 ceil(padNum)],0,'post');
		end
		newCube(sliceNum,:,:) = scaledSlice;
	end
	
	
	%% LOADING TYPE IS CHANGED
function loadingType_SelectionChangeFcn(hObject, eventdata)
	
	%retrieve GUI data, i.e. the handles structure
	handles = guidata(hObject);
	
	switch get(eventdata.NewValue,'Tag')   % Get Tag of selected object
		case 'buttonOverwrite'
			%if overwrite is selected
			setappdata(gcf,'loadingType','overwrite');
		case 'buttonInsert'
			%if insert is selected
			setappdata(gcf,'loadingType','insert');
		case 'buttonAppend'
			%if append is selected
			setappdata(gcf,'loadingType','append');
		otherwise
			% Code for when there is no match.
			fprintf('ErrorSC!\n')
	end
	
	% Update handles structure
	guidata(hObject, handles);
	
	
	%% SAVE AS BUTTON
function buttonSave_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonSave (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	%get vars
	intFrameRate = double(getappdata(gcf,'framerate'));
	movStruct = getappdata(gcf,'movStruct');

	%get output location
	[FileName,PathName,FilterIndex] = uiputfile('outputMovie.mpg','Select File for Save As','outputMovie.mpg');
	if FileName == 0
		return
	end
		%display message
	strMessage = ['Saving movie... Please wait'];
	setMessage(hObject,eventdata,handles,strMessage);
	
	type = 'mpg';
	if strcmp(type,'avi')
		%make writer object
		writerObj = VideoWriter([PathName FileName]);

		%set properties
		writerObj.FrameRate = intFrameRate;
		intQuality = 100;
		writerObj.Quality = intQuality;

		%write movie
		open(writerObj);
		writeVideo(writerObj,movStruct);

		% Close the file.
		close(writerObj);
	else
		%low quality
		%options = [1 0 1 0 10 8 10 25];
		
		%high quality
		options = [1 2 2 1 10 8 10 25];
		
		MPGWRITE(movStruct, movStruct(1).colormap, [PathName FileName], options)
	end
	%display message
	strMessage = ['Movie saved as <' FileName '>'];
	setMessage(hObject,eventdata,handles,strMessage);
	
	%{
	 	MPGWRITE(M, map, 'filename', options) Encodes M in MPEG
 	format using the specified colormap and writes the result to the
 	specified file.  The options argument is an optional vector of
 	8 or fewer options where each value has the following meaning:
 	1. REPEAT:
 		An integer number of times to repeat the movie
 		(default is 1).
 	2. P-SEARCH ALGORITHM:
 		0 = logarithmic	(fastest, default value)
 		1 = subsample
 		2 = exhaustive	(better, but slow)
 	3. B-SEARCH ALGORITHM:
 		0 = simple	(fastest)
 		1 = cross2	(slightly slower, default value)
 		2 = exhaustive	(very slow)
 	4. REFERENCE FRAME:
 		0 = original	(faster, default)
 		1 = decoded	(slower, but results in better quality)
 	5. RANGE IN PIXELS:
 		An integer search radius.  Default is 10.
 	6. I-FRAME Q-SCALE:
 		An integer between 1 and 31.  Default is 8.
 	7. P-FRAME Q-SCALE:
 		An integer between 1 and 31.  Default is 10.
 	8. B-FRAME Q-SCALE:
 		An integer between 1 and 31.  Default is 25.
	%}
	
	%% FRAME-IN BUTTON
function windowFrameIn_Callback(hObject, eventdata, handles)
	% hObject    handle to windowFrameIn (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hints: get(hObject,'String') returns contents of windowFrameIn as text
	%        str2double(get(hObject,'String')) returns contents of windowFrameIn as a double
	
	intFrameIn = uint64(str2double(get(hObject,'String')));
	setMarkerInTo(hObject, eventdata, handles,intFrameIn);
	
	
	%% CREATE FRAME-IN BUTTON
function windowFrameIn_CreateFcn(hObject, eventdata, handles)
	% hObject    handle to windowFrameIn (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    empty - handles not created until after all CreateFcns called
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	
	%% FRAME-OUT BUTTON
function windowFrameOut_Callback(hObject, eventdata, handles)
	% hObject    handle to windowFrameOut (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hints: get(hObject,'String') returns contents of windowFrameOut as text
	%        str2double(get(hObject,'String')) returns contents of windowFrameOut as a double
	
	intFrameOut = uint64(str2double(get(hObject,'String')));
	setMarkerOutTo(hObject, eventdata, handles,intFrameOut)
	
	%% CREATE FRAME-OUT BUTTON
function windowFrameOut_CreateFcn(hObject, eventdata, handles)
	% hObject    handle to windowFrameOut (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    empty - handles not created until after all CreateFcns called
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	
	%% CUTTER BUTTONS
function buttonDelIn_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonDelIn (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	intChannel = getappdata(gcf,'intChannel');
	if intChannel == 4
		vecChannels = 1:3;
	else
		vecChannels = intChannel;
	end
	movStruct = getappdata(gcf,'movStruct');
	inF = getappdata(gcf,'intFrameIn');
	outF = getappdata(gcf,'intFrameOut');
	vecFrames = inF:outF;
	movStruct = editSequence(hObject, eventdata, handles,vecChannels,movStruct,[],vecFrames,'delin');
	
	%set vars
	setappdata(gcf,'movStruct',movStruct);
	setappdata(gcf,'nowPlaying',false);
	setappdata(gcf,'nowForward',false);
	setappdata(gcf,'nowRewind',false);
	intMaxFrames = length(movStruct);
	strMessage = ['sequence deleted'];
	
	%set data
	setMaxFrameTo(hObject, eventdata, handles,intMaxFrames);
	setFrameTo(hObject, eventdata, handles,1);
	setMarkerOutTo(hObject, eventdata, handles,intMaxFrames);
	setMarkerInTo(hObject, eventdata, handles,1);
	setMessage(hObject,eventdata,handles,strMessage);
	
	% Update handles structure
	guidata(hObject, handles);
	
	
function buttonDelOut_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonDelOut (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	intChannel = getappdata(gcf,'intChannel');
	if intChannel == 4
		vecChannels = 1:3;
	else
		vecChannels = intChannel;
	end
	movStruct = getappdata(gcf,'movStruct');
	inF = getappdata(gcf,'intFrameIn');
	outF = getappdata(gcf,'intFrameOut');
	vecFrames = inF:outF;
	movStruct = editSequence(hObject, eventdata, handles,vecChannels,movStruct,[],vecFrames,'delout');
	
	%set vars
	setappdata(gcf,'movStruct',movStruct);
	setappdata(gcf,'nowPlaying',false);
	setappdata(gcf,'nowForward',false);
	setappdata(gcf,'nowRewind',false);
	intMaxFrames = length(movStruct);
	strMessage = ['sequence deleted'];
	
	%set data
	setMaxFrameTo(hObject, eventdata, handles,intMaxFrames);
	setFrameTo(hObject, eventdata, handles,1);
	setMarkerOutTo(hObject, eventdata, handles,intMaxFrames);
	setMarkerInTo(hObject, eventdata, handles,1);
	setMessage(hObject,eventdata,handles,strMessage);
	
	% Update handles structure
	guidata(hObject, handles);
	
	%% REWIND BUTTON
function buttonRewind_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonRewind (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	if getappdata(gcf,'nowRewind')
		setappdata(gcf,'nowRewind',false);
	else
		setappdata(gcf,'nowPlaying',false);
		setappdata(gcf,'nowForward',false);
		
		%get/set data
		intMaxFrame = getappdata(gcf,'maxFrame');
		intFrame = getappdata(gcf,'framenumber');
		if isempty(intMaxFrame) || intMaxFrame < 2
			return;
		end
		if intFrame < 2
			intFrame = intMaxFrame;
		end
		setappdata(gcf,'nowRewind',true);
		
		strMessage = sprintf('Reverse scanning at maximum speed');
		setMessage(hObject,eventdata,handles,strMessage);
		
		%do looping
		while getappdata(gcf,'nowRewind')
			
			intFrame = intFrame - 1;
			setFrameTo(hObject, eventdata, handles,intFrame);
			
			if intFrame < 2
				intFrame = intMaxFrame;
			end
		end
	end
	% Update handles structure
	guidata(hObject, handles);
	
	%% FASTFORWARD BUTTON
function buttonForward_Callback(hObject, eventdata, handles)
	% hObject    handle to buttonFastForward (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	% Hint: get(hObject,'Value') returns toggle state of buttonFastForward
	
	if getappdata(gcf,'nowForward')
		setappdata(gcf,'nowForward',false);
	else
		setappdata(gcf,'nowPlaying',false);
		setappdata(gcf,'nowRewind',false);
		
		%get/set data
		intMaxFrame = getappdata(gcf,'maxFrame');
		intFrame = getappdata(gcf,'framenumber');
		if isempty(intMaxFrame) || intMaxFrame < 2
			return;
		end
		if intFrame == intMaxFrame
			intFrame = 1;
		end
		setappdata(gcf,'nowForward',true);
		
		strMessage = sprintf('Forward scanning at maximum speed');
		setMessage(hObject,eventdata,handles,strMessage);
		
		%do looping
		while getappdata(gcf,'nowForward')
			intFrame = intFrame + 1;
			setFrameTo(hObject, eventdata, handles,intFrame);
			
			if intFrame >= intMaxFrame
				intFrame = 1;
			end
		end
	end
	% Update handles structure
	guidata(hObject, handles);
	
function [movStruct,movObj] = editSequence(hObject, eventdata, handles,vecChannels,movStruct,movSequenceIn,vecFrames,strType)
	
	movLength = length(movStruct);
	seqLength = length(movSequenceIn);
	frameLength = length(vecFrames);
	corLength = min(seqLength,frameLength);
	movObj = getappdata(gcf,'movObj');
	
	[movHeight,movWidth,z]=size(movStruct(1).cdata);
	if ~isempty(movSequenceIn)
		[seqHeight,seqWidth,z]=size(movSequenceIn(1).cdata);
		newHeight = max(movHeight,seqHeight);
		newWidth = max(movWidth,seqWidth);
	else
		newHeight = movHeight;
		newWidth = movWidth;
	end
	switch strType
		case 'overwrite'
			%vecFrames gives frames of movStructIn to overwrite with movSequenceIn
			
			%crop length
			movSeq = movSequenceIn(1:corLength);
			vecFrames = vecFrames(1:corLength);
			
			%overwrite designated frames/channels
			fC = 0;
			for i=vecFrames
				fC = fC + 1;
				[seqHeight,seqWidth,z]=size(movSeq(fC).cdata(:,:,vecChannels));
				movStruct(i).cdata(1:seqHeight,1:seqWidth,vecChannels) = movSeq(fC).cdata(:,:,vecChannels);
			end
		case 'insert'
			%vecFrames(1) gives frame position before which to insert sequence
			
			%new movie
			newMaxFrame = movLength + seqLength;
			newMov(1:newMaxFrame) = ...
				struct('cdata', zeros(newHeight, newWidth, 3, 'uint8'),...
				'colormap', []);
			
			%create indices
			indFrontNew = 1:(vecFrames(1)-1);
			indMidNew = vecFrames(1):(vecFrames(1)+seqLength-1);
			indBackNew = (vecFrames(1)+seqLength):(seqLength+movLength);
			indBackOld = vecFrames(1):movLength;
			
			%assign frames
			for i=indFrontNew
				[oldHeight,oldWidth,z]=size(movStruct(i).cdata(:,:,1:3));
				newMov(i).cdata(1:oldHeight,1:oldWidth,1:3) = movStruct(i).cdata(:,:,1:3);
			end
			midCounter=0;
			for i2=indMidNew
				midCounter=midCounter+1;
				[oldHeight,oldWidth,z]=size(movSequenceIn(midCounter).cdata(:,:,vecChannels));
				newMov(i2).cdata(1:oldHeight,1:oldWidth,vecChannels) = movSequenceIn(midCounter).cdata(:,:,vecChannels);
			end
			backCounter=0;
			for i3=indBackNew
				backCounter=backCounter+1;
				intFrameOld = indBackOld(backCounter);
				[oldHeight,oldWidth,z]=size(movStruct(intFrameOld).cdata(:,:,1:3));
				newMov(i3).cdata(1:oldHeight,1:oldWidth,1:3) = movStruct(intFrameOld).cdata(:,:,1:3);
			end
			
			clear movStruct;
			movStruct = newMov;
			
		case 'append'
			%vecFrames is []; appends sequence to end of movie
			
			movStruct((movLength+1):(movLength+seqLength)) = movSequenceIn;
		case 'delin'
			%movSequenceIn is []; vecFrames gives frame numbers to delete; all others are kept
			allFrames = 1:movLength;
			keepIndex = ~ismember(allFrames,vecFrames);
			if length(vecChannels) == 3
				%delete all
				movStruct = movStruct(keepIndex);
			else
				%overwrite with zeros
				for i=vecFrames
					[movHeight,movWidth,z]=size(movStruct(i).cdata(:,:,vecChannels));
					movStruct(i).cdata(:,:,vecChannels) = zeros(movHeight,movWidth);
				end
			end
			
			
		case 'delout'
			%movSequenceIn is []; vecFrames gives frame numbers to keep; all others are deleted
			allFrames = 1:movLength;
			discardIndex = ~ismember(allFrames,vecFrames);
			if length(vecChannels) == 3
				%delete all
				movStruct = movStruct(vecFrames);
			else
				%overwrite with zeros
				for i=allFrames
					if discardIndex(i) == 1
						[movHeight,movWidth,z]=size(movStruct(i).cdata(:,:,vecChannels));
						movStruct(i).cdata(:,:,vecChannels) = zeros(movHeight,movWidth);
					end
				end
			end
		otherwise
			% Code for when there is no match.
			fprintf('Error: %s is not a valid edit type!\n',strType)
	end
	
	%set max frame
	movObj.NumberOfFrames = length(movStruct);
	
	%save info
	setMaxFrameTo(hObject, eventdata, handles,movObj.NumberOfFrames);
	
	% Update handles structure
	guidata(hObject, handles);
