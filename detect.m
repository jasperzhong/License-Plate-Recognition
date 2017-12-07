clc,clear

path = 'D:\\Program\\Automatic number-plate recognition\\raw\\';
file = dir(path);
file_length = length(file);
mkf = 0;
for k = 3:file_length
    name = file(k).name;
    %��ȡͼƬ
    img = imread([path,'\\',name]);
    %��ʽ��900x675
    width = 900;  col = 675;
    %ͳһ��С
    img = imresize(img,[col,width]);
    %����ԭʼͼƬ
    original = img;
    %ת�Ҷ�ͼ��
    img = rgb2gray(img);
    %����ˮӡ�ȵ�
    %��������
    img = imadjust(img);
  
    se = strel('disk',5);      
    %��̬ѧ���������ѳ��Ƶ��ַ�Ĩ��
    img2 = imopen(img,se);
    %ͼ���֣�ʹ�ó��Ƶ��ַ���������
    img = imsubtract(img,img2);
    %imshow(img)
    preprocessed = img;
    
    %���ǵ������ϵ��ַ��кܶ�����ı�Ե�������������ɸѡ
    %��sobel����ȡ��Ե
    img = edge(img,'sobel','vertical');
    %figure,imshow(img)
    
    %��̬ѧ�����������������������ã�ͬʱҲ������ܶ������Ŀ�
    se = strel('rectangle',[10,20]);
    %��̬ѧ�ղ���
    img = imclose(img,se);
    se = strel('disk',5);
    %img = imclose(img,se);
    img = imdilate(img,se);
    se = ones(1,30);
    img = imopen(img,se);
    se = ones(4,1);
    img = imopen(img,se);
    
    %��������ͱ߽����ɸѡ
    %����ͱ߽������Ŀ飬����һ�㲻���ڱ߽�
    img = imclearborder(img,4);
    %��ֵ��ɾ�����С��3000�ģ���һ�㶼��7k+�������
    img = bwareaopen(img, 3000);
    %DEBUG:�������������ֳ����������������������������Ǿ�GG��
    %Ŀǰ����һ���ĳɹ���Ϊ95%����ʱ�Ҳ������õİ취
    %���ó��ȺͿ�Ƚ���ɸѡ
    %��׼���ƣ���44cm����14cm
    %���ǵ���Ƭ�ĽǶȺ���ת�ȣ���߱�Ҫ����2.2��ʵ����֤��������Ҫ��
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
    %ֻ��һ�����������ǾͲ���Ҫɸѡ�ˣ�ֱ����ȥOCR
    if cnt == 1
        Bg(floor(Box(1,2)):floor(Box(1,2)+Box(1,4)),floor(Box(1,1)):floor(Box(1,1)+Box(1,3))) = 255;
        cut = preprocessed(floor(Box(1,2)):floor(Box(1,2)+Box(1,4)),floor(Box(1,1)):floor(Box(1,1)+Box(1,3))); 
    else
    %�ж������������ɸѡ��ѡȡ��������ܵ���ȥOCR
    %���ͨ��ֱ��ͼ�������һ��ɸѡ
    %��Ϊ�����ַ����м�϶����ֵ�����ֱ��ͼ��Ȼ����ֺܶನ��,������������ήΪ0�������Ƭ�Ƚ����Ļ��� 
    %���ȣ�����ƽ��ֵ�ģ���������8���ķ���Ҫ��
    %����һ������Ҫ���
        candidate = zeros(1,cnt);
        cx = 0;
        
        for i = 1 : cnt
            cut = preprocessed(floor(Box(i,2)):floor(Box(i,2)+Box(i,4)),floor(Box(i,1)):floor(Box(i,1)+Box(i,3)));
            
            bi = imbinarize(cut);
            hist = sum(bi);
            
            %�˲���ʹ��ֱ��ͼƽ������Ȼ�����̫�ನ�岨��
            hist = smooth(hist);
            hist = smooth(hist);
            %��ƽ��ֵ��һ�������������ַ��ļ�϶�����Ĳ��ȵ�ֵ�ܵͺܵ�
            average = mean(hist);
            %�����м�Сֵ��
            posMin = find(diff(sign(diff(hist)))>0)+1;
            posMax = find(diff(sign(diff(hist)))<0)+1;
            len = length(posMin);
            count_min = 0;
            count_max = length(posMax);
            stds = std(hist);
            %ɸѡ
            for j = 1:len
                if hist(posMin(j)) < average
                    count_min = count_min + 1;
                end
            end
            %fprintf('������Ŀ��%d\n�Ϸ�������Ŀ��%d\n��׼��Ϊ:%f',count_max,count_min,stds)
            if count_min >= 9 && count_min <= 17 &&...
               count_max >= 10 && count_max <= 20 &&...
               stds >= 4
               cx = cx + 1;
               candidate(i) = abs(Box(i,3)/Box(i,4)-44/14);
            end
        end  
        
        if cx == 0
            fprintf('�޷�ʶ��\n');
            continue       
        else
            [ma,pos] = max(candidate);
            Bg(floor(Box(pos,2)):floor(Box(pos,2)+Box(pos,4)),floor(Box(pos,1)):floor(Box(pos,1)+Box(pos,3))) = 255;
            cut = preprocessed(floor(Box(pos,2)):floor(Box(pos,2)+Box(pos,4)),floor(Box(pos,1)):floor(Box(pos,1)+Box(pos,3)));
        end
    
    end
    
    %����ȷ���߽�
    [row col] = size(cut);
    tmp = medfilt2(cut);
    tmp = medfilt2(tmp);
    tmp = imbinarize(tmp);
    %imshow(tmp)
    left = 1;right = col;
    up = 1; bottom = row;
    row_sum = sum(tmp);
    %ȷ����߽�
    for i = 1:col-2
        if row_sum(i) > 0 && row_sum(i+1) > 0 && ...
                row_sum(i+2) > 0
            left = i;
            break;
        end
    end
    %ȷ���ұ߽�
    for i = col:-1:3
        if row_sum(i) > 0 && row_sum(i-1) > 0 && ...
                row_sum(i-2) > 0
            right = i;
            break;
        end
    end
    
    col_sum = sum(tmp,2);
    %ȷ���ϱ߽�
    for i = 1:row
        if col_sum(i) > 10 && col_sum(i+1) > 10 &&...
                col_sum(i+2) > 10
            up = i;
            break;
        end
    end
    %ȷ���±߽�
    for i = row:-1:1
        if col_sum(i) > 0 && col_sum(i-1) > 0 &&...
                col_sum(i-2) > 0
            bottom = i;
            break;
        end
    end
    image_correct = cut(up:bottom,left:right);
    
    %ȥ�����±߿�
    max_num=max(max(image_correct));
    min_num=min(min(image_correct));
    thresh=(max_num-min_num)/15;%15
    image_correct_row=edge(image_correct,'sobel',thresh,'vertical');%������ָ�������ж���ֵthresh������ָ���ķ���direction�ϣ�
    histrow=sum(image_correct_row');  %����ˮƽͶӰ
    histrow_mean=mean(histrow)/1.2;
    histcol=sum(image_correct_row);  %������ֱͶӰ
    histcol_mean=mean(histcol);
    [width hight]=size(image_correct_row);
    rowtop=0;
    for i=1:width/2
        if histrow(i)>=1/3*histrow_mean & histrow(i+1)>1/2*histrow_mean & histrow(i+2)>1/2*histrow_mean & histrow(i+3)>1/2*histrow_mean  %������ֵ�ж�Ϊ�ϱ߽�
            rowtop=i; %�ϱ��и�
            break;
        end
    end
    rowbot=0;
    histrow_mean = histrow_mean/1.2;
    for i=width:-1:width/2
        if histrow(i)>=1/4*histrow_mean & histrow(i-1)>histrow_mean & histrow(i-2)>histrow_mean  & histrow(i-3)>histrow_mean & histrow(i-4)>histrow_mean 
            rowbot=i; %�±��и�
            break;
        end
    end

    cut = image_correct(rowtop:rowbot,:);

    %�ҵ������м��Բ���ˮƽλ��
    %����Ӧ����ˮƽ1/5 - 1/2��λ�ã�����ֱ1/3-2/3��λ��,���ص�<40,��������ڱ߽�
    [row, col] = size(cut);
    tmp = cut(floor(row/3):floor(row*2/3),floor(col/5):floor(col/2));
    tmp = imclearborder(tmp);
    tmp = imbinarize(tmp);
    [L,num] = bwlabel(tmp,4);
    if num == 0
        %���û���֣����������±߽�����⣬��΢�ɳ�һ��
        tmp = cut(floor(row/4):floor(row*3/4),floor(col/5):floor(col/2));
        tmp = imclearborder(tmp);
        tmp = imbinarize(tmp);
        [L,num] = bwlabel(tmp,4);
        %��Ȼ�޷����֣����������Ǵ����и��ͼ��
        if num == 0
            fprintf("�޷�ʶ��\n");
        end
    elseif num > 3
        %���ִ����㣬Ҳ�����Ǵ����и��ͼ��
        fprintf("�޷�ʶ��\n");
        continue
    end
    
    STATS = regionprops(L,'Centroid');
    %�ҵ��Ǹ���
    point_pos = STATS(1).Centroid(1) + floor(col/5);
    cut = imbinarize(cut);
    [row, col] = size(cut);
    hist = sum(cut);
    %�ַ��ָ�ڵ�����ȡ�����ַ����ұ�ȡ����ַ�
    left = 0; right = 0;
    threshold = min(hist) + 3;
    Char = cell(1,7);
    last = int32(point_pos)-2;
    %ֻҪ�����ҵ���һ�������ˣ��õ��ַ����Ⱥͼ�࣬ʣ�µ�ֱ�Ӹ����ַ����Ⱥͼ���и�
    %���ǵ���ߵ�һ��һ������ĸ������I,O�������Եõ����ַ���ȹ���
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
    %�и��ʱ����Ҫ΢��
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
            fprintf('�и���ִ���.\n');
            ok = 0;
            break
        end
    end
    if ~ok
        continue
    end
    %���и��ⲽΪֹ�����70%����ȷ��
    
    load('net.mat');   %������
    load('net1.mat');  %��ĸ&����
    load('net2.mat');  %����ĸ
    chinese = ['��','��','��','��'];
    char = ['0','1','2','3','4','5','6','7','8','9',...
    'A','B','C','D','E','F','G','H','J','K',...
    'L','M','N','P','Q','R','S','T','U','V',...
    'W','X','Y','Z'];
    char2 = ['A','B','C','D','E','F','G','H','J','K',...
    'L','M','N','P','Q','R','S','T','U','V',...
    'W','X','Y','Z'];
    for p = 1:7
        %ͳһ��ʽ
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
            fprintf('%s',chinese(pos));
        elseif p == 2
            result = net2(tmp);
            [ma,pos] = max(result);
            fprintf('%s',char2(pos));
        else
            result = net1(tmp);
            [ma,pos] = max(result);
            fprintf('%s',char(pos));
        end  
    end
    figure,imshow(original);
    hold on
    Bg = imbinarize(Bg);
    B = bwboundaries(Bg);
    hold on
    for k = 1 : length(B)
        boundary = B{k};
        plot(boundary(:,2),boundary(:,1),'g','LineWidth',2)
    end
    fprintf('\n');
    fprintf('�밴���������\n');
    pause()
    close all
    clc

end