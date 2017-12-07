function varargout = gui(varargin)
% GUI MATLAB code for gui.fig
%      GUI, by itself, creates a new GUI or raises the existing
%      singleton*.
%
%      H = GUI returns the handle to a new GUI or the handle to
%      the existing singleton*.
%
%      GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GUI.M with the given input arguments.
%
%      GUI('Property','Value',...) creates a new GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gui

% Last Modified by GUIDE v2.5 07-Dec-2017 14:25:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gui (see VARARGIN)

% Choose default command line output for gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gui wait for user response (see UIRESUME)
% uiwait(handles.figure);
setappdata(handles.figure,'img_src',0);

% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function plate_recogination_Callback(hObject, eventdata, handles)
% hObject    handle to plate_recogination (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in open_image.
function open_image_Callback(hObject, eventdata, handles)
% hObject    handle to open_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename,pathname]=uigetfile(... 
    {'*.bmp;*.jpg;*.png;*.jpeg','ImageFiles(*.bmp,*.jpg,*.png,*.jpeg)';... 
    '*.*','AllFiles(*.*)'},...
    'Pickanimage'); 
    if isequal(filename,0)||isequal(pathname,0)
        return;
    end
    clc
    fpath=[pathname filename];
    img=imread(fpath);
    
    width = 900;  col = 675;
    %统一大小
    img = imresize(img,[col,width]);
    %保存原始图片
    original = img;
    axes(handles.locate);
    imshow(original);
    
    %转灰度图像
    img = rgb2gray(img);
    %剪裁水印等等
    %调节亮度
    img = imadjust(img);
    %【参数1】:第一次开操作力度
    se = strel('disk',5);      
    %形态学开操作，把车牌的字符抹掉
    img2 = imopen(img,se);
    %图像差分，使得车牌的字符更加鲜明
    img = imsubtract(img,img2);
    %imshow(img)
    preprocessed = img;
    
    %考虑到车牌上的字符有很多纵向的边缘，可以利用这点筛选
    %用sobel算子取边缘
    img = edge(img,'sobel','vertical');
    
    %形态学处理，将车牌连起来；副作用：同时也会产生很多其他的块
    %【参数2】：第一次闭操作的力度
    se = strel('rectangle',[10,20]);
    %形态学闭操作
    img = imclose(img,se);
    %【参数3】：形态学操作力度
    se = strel('disk',5);
    %img = imclose(img,se);
    img = imdilate(img,se);
    se = ones(1,30);
    img = imopen(img,se);
    %【参数4】：形态学操作力度
    se = ones(4,1);
    img = imopen(img,se);
    
    %利用面积和边界进行筛选
    %清除和边界相连的块，车牌一般不会在边界
    img = imclearborder(img,4);
    %【参数5】：阈值，删除面积小于3000的；（一般都有7k+的面积）
    img = bwareaopen(img, 3000);
    %subplot(211)
    %imshow(original);
    %subplot(212)
    %imshow(img)
    %DEBUG:如果到了这里，出现车牌区域和其他区域相连的情况，那就GG了
    %目前到这一步的成功率为95%，暂时找不到更好的办法
    
    %利用长度和宽度进行筛选
    %标准车牌：宽44cm，高14cm
    %考虑到照片的角度和旋转度，宽高比要大于2.2（实际验证可以满足要求）
    [L,num] = bwlabel(img);
    STATS = regionprops(L,'BoundingBox');
    std_ratio = 2.2;
    Box = [];
    cnt = 0;
    for i = 1:num
        box = STATS(i).BoundingBox;
        x = box(1);
        y = box(2);
        w = box(3);
        h = box(4);
        if w/h > std_ratio
            Box = [Box;box];
            cnt = cnt + 1;
        end
    end
    
    Bg = zeros(col,width);
    %只有一个可能区域，那就不需要筛选了，直接送去OCR
    if cnt == 1
        Bg(floor(Box(1,2)):floor(Box(1,2)+Box(1,4)),floor(Box(1,1)):floor(Box(1,1)+Box(1,3))) = 255;
        cut = preprocessed(floor(Box(1,2)):floor(Box(1,2)+Box(1,4)),floor(Box(1,1)):floor(Box(1,1)+Box(1,3))); 
    else
    %有多个可能区域，先筛选，选取其中最可能的送去OCR
    %最后通过直方图进行最后一次筛选
    %因为车牌字符间有间隙，二值化后的直方图必然会出现很多波谷,波谷最低甚至会降为0（如果照片比较正的话） 
    %波谷（低于平均值的）数量高于8个的符合要求
    %多余一个符合要求的
        candidate = zeros(1,cnt);
        cx = 0;
        
        for i = 1 : cnt
            cut = preprocessed(floor(Box(i,2)):floor(Box(i,2)+Box(i,4)),floor(Box(i,1)):floor(Box(i,1)+Box(i,3)));
            
            bi = imbinarize(cut);
            hist = sum(bi);
            
            %滤波，使得直方图平滑，不然会出现太多波峰波谷
            %【参数6】：滤几次波合适？强度又如何？
            hist = smooth(hist);
            hist = smooth(hist);
            %求平均值，一般来讲，车牌字符的间隙产生的波谷的值很低很低
            average = mean(hist);
            %找所有极小值点
            posMin = find(diff(sign(diff(hist)))>0)+1;
            posMax = find(diff(sign(diff(hist)))<0)+1;
            len = length(posMin);
            count_min = 0;
            count_max = length(posMax);
            stds = std(hist);
            %筛选
            for j = 1:len
                if hist(posMin(j)) < average
                    count_min = count_min + 1;
                end
            end
            %imshow(cut)
            %fprintf('波峰数目：%d\n合法波谷数目：%d\n标准差为:%f',count_max,count_min,stds)
            %pause()
            %close all
            if count_min >= 9 && count_min <= 17 &&...
               count_max >= 10 && count_max <= 20 &&...
               stds >= 4
               cx = cx + 1;
               candidate(i) = abs(Box(i,3)/Box(i,4)-44/14);
            end
        end  
        
        if cx == 0
            result = "无法识别";
            set(handles.result,'String',result);
            return       
        else
            [ma,pos] = max(candidate);
            Bg(floor(Box(pos,2)):floor(Box(pos,2)+Box(pos,4)),floor(Box(pos,1)):floor(Box(pos,1)+Box(pos,3))) = 255;
            cut = preprocessed(floor(Box(pos,2)):floor(Box(pos,2)+Box(pos,4)),floor(Box(pos,1)):floor(Box(pos,1)+Box(pos,3)));
        end
    
    end
    
    Bg = imbinarize(Bg);
    B = bwboundaries(Bg);
    hold on
    for k = 1 : length(B)
        boundary = B{k};
        plot(boundary(:,2),boundary(:,1),'g','LineWidth',2)
    end
    
    axes(handles.cut);
    %初步确定边界
    [row col] = size(cut);
    tmp = medfilt2(cut);
    tmp = medfilt2(tmp);
    tmp = imbinarize(tmp);
    %imshow(tmp)
    left = 1;right = col;
    up = 1; bottom = row;
    row_sum = sum(tmp);
    %确定左边界
    for i = 1:col-2
        if row_sum(i) > 0 && row_sum(i+1) > 0 && ...
                row_sum(i+2) > 0
            left = i;
            break;
        end
    end
    %确定右边界
    for i = col:-1:3
        if row_sum(i) > 0 && row_sum(i-1) > 0 && ...
                row_sum(i-2) > 0
            right = i;
            break;
        end
    end
    
    col_sum = sum(tmp,2);
    %确定上边界
    for i = 1:row
        if col_sum(i) > 10 && col_sum(i+1) > 10 &&...
                col_sum(i+2) > 10
            up = i;
            break;
        end
    end
    %确定下边界
    for i = row:-1:1
        if col_sum(i) > 0 && col_sum(i-1) > 0 &&...
                col_sum(i-2) > 0
            bottom = i;
            break;
        end
    end
    image_correct = cut(up:bottom,left:right);
    
    %去除上下边框
    max_num=max(max(image_correct));
    min_num=min(min(image_correct));
    thresh=(max_num-min_num)/15;%15
    image_correct_row=edge(image_correct,'sobel',thresh,'vertical');%根据所指定的敏感度阈值thresh，在所指定的方向direction上，
    histrow=sum(image_correct_row');  %计算水平投影
    histrow_mean=mean(histrow)/1.2;
    histcol=sum(image_correct_row);  %计算竖直投影
    histcol_mean=mean(histcol);
    [width hight]=size(image_correct_row);
    rowtop=0;
    for i=1:width/2
        if histrow(i)>=1/3*histrow_mean & histrow(i+1)>1/2*histrow_mean & histrow(i+2)>1/2*histrow_mean & histrow(i+3)>1/2*histrow_mean  %连续有值判断为上边界
            rowtop=i; %上边切割
            break;
        end
    end
    rowbot=0;
    histrow_mean = histrow_mean/1.2;
    for i=width:-1:width/2
        if histrow(i)>=1/4*histrow_mean & histrow(i-1)>histrow_mean & histrow(i-2)>histrow_mean  & histrow(i-3)>histrow_mean & histrow(i-4)>histrow_mean 
            rowbot=i; %下边切割
            break;
        end
    end

    cut = image_correct(rowtop:rowbot,:);
    imshow(cut);
    
    %找到车牌中间的圆点的水平位置
    %大致应该在水平1/5 - 1/2的位置，在竖直1/3-2/3的位置,像素点<40,不会出现在边界
    [row, col] = size(cut);
    tmp = cut(floor(row/3):floor(row*2/3),floor(col/5):floor(col/2));
    tmp = imclearborder(tmp);
    tmp = imbinarize(tmp);
    %subplot(211)
    %imshow(tmp);
    %subplot(212)
    %imshow(cut);
    %close all
    [L,num] = bwlabel(tmp,4);
    if num == 0
        %如果没出现，可能是上下边界的问题，稍微松弛一下
        tmp = cut(floor(row/4):floor(row*3/4),floor(col/5):floor(col/2));
        tmp = imclearborder(tmp);
        tmp = imbinarize(tmp);
        [L,num] = bwlabel(tmp,4);
        %依然无法出现，基本考虑是错误切割的图像
        if num == 0
            result = "无法识别";
            set(handles.result,'String',result);
            return      
        end
    elseif num > 3
        %出现大量点，也基本是错误切割的图像
        result = "无法识别";
        set(handles.result,'String',result);
        return      
    end
    
    STATS = regionprops(L,'Centroid');
    %找到那个点
    point_pos = STATS(1).Centroid(1) + floor(col/5);
    cut = imbinarize(cut);
    [row, col] = size(cut);
    hist = sum(cut);
    %字符分割，在点的左边取两个字符，右边取五个字符
    left = 0; right = 0;
    threshold = min(hist) + 3;
    Char = cell(1,7);
    last = int32(point_pos)-2;
    
    %只要向左找到第一个就行了，得到字符长度和间距，剩下的直接根据字符长度和间距切割
    %考虑到左边第一个一定是字母（且无I,O），所以得到的字符宽度够大
    while 1
        ok = 1;
        for pos = last: -1 : 2
            if ok & hist(pos) > threshold & hist(pos+1) < threshold
                right = pos+1;
                ok = 0;
            end
            if ~ok & hist(pos) > threshold & hist(pos-1) < threshold
                left = pos-1;
                Char{2} = cut(:,left:right);
                break;
            end
        end
        if pos > 2
        break
        else
            threshold = threshold + 1;
            if threshold > 10
                break;
            end
        end
    end
    char_width = right - left;
    interval = last - right;
    tr = left - interval;
    tl = max(tr-char_width,1);
    Char{1} = cut(:,tl:tr);
    tl = int32(point_pos) + interval;
    tr = tl + char_width;
    %切割的时候需要微调
    for i = 3:7
        Char{i} = cut(:,tl:tr);
        if i < 7
            tl = tr + interval - 1;
            cnt = 0;
            while tl < length(hist) & hist(tl) > threshold & cnt < 3
                tl = tl - 1;
                cnt = cnt + 1;
            end
            tr = tl+char_width;
            tr = min(tr,col-1);
        end
    end
    
    ok = 1;
    for i = 1:7
        if isempty(Char{i})
            result = "字符切割出现错误";
            set(handles.result,'String',result);
            return      
        end
    end
    
    load('net.mat');   %纯汉字
    load('net1.mat');  %字母&数字
    load('net2.mat');  %纯字母
    chinese = ['京','沪','浙','苏'];
    char = ['0','1','2','3','4','5','6','7','8','9',...
    'A','B','C','D','E','F','G','H','J','K',...
    'L','M','N','P','Q','R','S','T','U','V',...
    'W','X','Y','Z'];
    char2 = ['A','B','C','D','E','F','G','H','J','K',...
    'L','M','N','P','Q','R','S','T','U','V',...
    'W','X','Y','Z'];
    res = [];
    for p = 1:7
        %统一格式
        cut = imresize(Char{p},[32,32]);
        cut = uint8(cut);
        cut = imbinarize(cut);  
        tmp = zeros(1024,1);
        for i = 1:32
            for j = 1:32
                if mod(i,2) == 1
                    tmp((i-1)*32+j) = cut(i,j);
                else
                    tmp((i-1)*32+j) = cut(i,32-j+1);
                end
            end
        end
        if p == 1
            result = net(tmp);
            [ma,pos] = max(result);
            res = [res;chinese(pos)];
        elseif p == 2
            result = net2(tmp);
            [ma,pos] = max(result);
            res = [res;char2(pos)];
        else
            result = net1(tmp);
            [ma,pos] = max(result);
            res = [res;char(pos)];
        end 
    end
    display(res)
    set(handles.result,'String',res');

    


% --------------------------------------------------------------------
function exit_Callback(hObject, eventdata, handles)
% hObject    handle to exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    close(handles.figure);



function result_Callback(hObject, eventdata, handles)
% hObject    handle to result (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of result as text
%        str2double(get(hObject,'String')) returns contents of result as a double


% --- Executes during object creation, after setting all properties.
function result_CreateFcn(hObject, eventdata, handles)
% hObject    handle to result (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
