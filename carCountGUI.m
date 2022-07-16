function varargout = carCountGUI(varargin)

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @carCountGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @carCountGUI_OutputFcn, ...
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

function carCountGUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
ah = axes('unit','normalized','position',[0 0 1 1])
bg=imread('back.jpg');imagesc(bg);
set(ah,'handlevisibility','off','visible','off')


function varargout = carCountGUI_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function startButton_Callback(hObject, eventdata, handles)

val=handles.im_original;
handles.count=start(val);

set(findall(handles.figure1,'Tag','Output'),'string',handles.count);
drawnow;


function load_button_Callback(hObject, eventdata, handles)
[file_name,path_name]=uigetfile('*');
full_path=[path_name '\' file_name];
handles.path_name=path_name;
handles.file_name=file_name;
handles.im_original=full_path;
guidata(hObject,handles);



function count_Callback(hObject, eventdata, handles)


   
