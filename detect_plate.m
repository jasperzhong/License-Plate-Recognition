clc,clear
path = 'D:\\Program\\Automatic number-plate recognition\\raw\\';
file = dir(path);
file_length = length(file);
for k = 3:file_length
    name = file(k).name;
    %读取图片
    img = imread([path,'\\',name]);
    %转灰度图像
    img = rgb2gray(img);
    %格式：900x675
    width = 900;  height = 675;
    %统一大小
    img = imresize(img,[height,width]);
    %剪裁水印等等
    %调节亮度
    img = imadjust(img);
    %存储灰度图，留到后面截图用
    
    
    %【参数1】:第一次开操作力度
    se = strel('disk',5);      
    %形态学开操作，把车牌的字符抹掉
    img2 = imopen(img,se);
    %图像差分，使得车牌的字符更加鲜明
    img = imsubtract(img,img2);
    %imshow(img)
    original = img;
    
    %考虑到车牌上的字符有很多纵向的边缘，可以利用这点筛选
    %用sobel算子取边缘
    img = edge(img,'sobel','vertical');
    %figure,imshow(img)
    
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
    
    
    %只有一个可能区域，那就不需要筛选了，直接送去OCR
    if cnt == 1
        cut = original(Box(1,2):Box(1,2)+Box(1,4),Box(1,1):Box(1,1)+Box(1,3)); 
    else
    %有多个可能区域，先筛选，选取其中最可能的送去OCR
    %最后通过直方图进行最后一次筛选
    %因为车牌字符间有间隙，二值化后的直方图必然会出现很多波谷,波谷最低甚至会降为0（如果照片比较正的话） 
    %波谷（低于平均值的）数量高于8个的符合要求
    %多余一个符合要求的
        candidate = zeros(1,cnt);
        cx = 0;
        
        for i = 1 : cnt
            cut = original(Box(i,2):Box(i,2)+Box(i,4),Box(i,1):Box(i,1)+Box(i,3));
            
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
            fprintf('emmmmmmm,bad luck\n');
            continue       
        else
            [ma,pos] = max(candidate);
            cut = original(Box(pos,2):Box(pos,2)+Box(pos,4),Box(pos,1):Box(pos,1)+Box(pos,3));
        end
    
    end
    
    %目前达到了84%的准确识别车牌的概率，还需要不断调参（逃
    imwrite(cut,['D:\\Program\\Automatic number-plate recognition\\tmp3\\',int2str(k),'.jpg']);
    %TODO:可以考虑做个可视化，搞个GUI，放上车牌识别的框和截取下来的车牌和识别结果，美滋滋
    
    %TODO:result = OCR(cut);
    
    %fprintf("最终识别结果是：%s",result);
    
end