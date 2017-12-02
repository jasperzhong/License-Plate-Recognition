clc,clear
path = 'D:\\Program\\Automatic number-plate recognition\\raw\\';
file = dir(path);
file_length = length(file);
for k = 3:file_length
    name = file(k).name;
    %��ȡͼƬ
    img = imread([path,'\\',name]);
    %ת�Ҷ�ͼ��
    img = rgb2gray(img);
    %��ʽ��900x675
    width = 900;  height = 675;
    %ͳһ��С
    img = imresize(img,[height,width]);
    %����ˮӡ�ȵ�
    %��������
    img = imadjust(img);
    %�洢�Ҷ�ͼ�����������ͼ��
    
    
    %������1��:��һ�ο���������
    se = strel('disk',5);      
    %��̬ѧ���������ѳ��Ƶ��ַ�Ĩ��
    img2 = imopen(img,se);
    %ͼ���֣�ʹ�ó��Ƶ��ַ���������
    img = imsubtract(img,img2);
    %imshow(img)
    original = img;
    
    %���ǵ������ϵ��ַ��кܶ�����ı�Ե�������������ɸѡ
    %��sobel����ȡ��Ե
    img = edge(img,'sobel','vertical');
    %figure,imshow(img)
    
    %��̬ѧ�����������������������ã�ͬʱҲ������ܶ������Ŀ�
    %������2������һ�αղ���������
    se = strel('rectangle',[10,20]);
    %��̬ѧ�ղ���
    img = imclose(img,se);
    %������3������̬ѧ��������
    se = strel('disk',5);
    %img = imclose(img,se);
    img = imdilate(img,se);
    se = ones(1,30);
    img = imopen(img,se);
    %������4������̬ѧ��������
    se = ones(4,1);
    img = imopen(img,se);
    
    %��������ͱ߽����ɸѡ
    %����ͱ߽������Ŀ飬����һ�㲻���ڱ߽�
    img = imclearborder(img,4);
    %������5������ֵ��ɾ�����С��3000�ģ���һ�㶼��7k+�������
    img = bwareaopen(img, 3000);
    %subplot(211)
    %imshow(original);
    %subplot(212)
    %imshow(img)
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
    
    
    %ֻ��һ�����������ǾͲ���Ҫɸѡ�ˣ�ֱ����ȥOCR
    if cnt == 1
        cut = original(Box(1,2):Box(1,2)+Box(1,4),Box(1,1):Box(1,1)+Box(1,3)); 
    else
    %�ж������������ɸѡ��ѡȡ��������ܵ���ȥOCR
    %���ͨ��ֱ��ͼ�������һ��ɸѡ
    %��Ϊ�����ַ����м�϶����ֵ�����ֱ��ͼ��Ȼ����ֺܶನ��,������������ήΪ0�������Ƭ�Ƚ����Ļ��� 
    %���ȣ�����ƽ��ֵ�ģ���������8���ķ���Ҫ��
    %����һ������Ҫ���
        candidate = zeros(1,cnt);
        cx = 0;
        
        for i = 1 : cnt
            cut = original(Box(i,2):Box(i,2)+Box(i,4),Box(i,1):Box(i,1)+Box(i,3));
            
            bi = imbinarize(cut);
            hist = sum(bi);
            
            %�˲���ʹ��ֱ��ͼƽ������Ȼ�����̫�ನ�岨��
            %������6�����˼��β����ʣ�ǿ������Σ�
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
            %imshow(cut)
            %fprintf('������Ŀ��%d\n�Ϸ�������Ŀ��%d\n��׼��Ϊ:%f',count_max,count_min,stds)
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
    
    %Ŀǰ�ﵽ��84%��׼ȷʶ���Ƶĸ��ʣ�����Ҫ���ϵ��Σ���
    imwrite(cut,['D:\\Program\\Automatic number-plate recognition\\tmp3\\',int2str(k),'.jpg']);
    %TODO:���Կ����������ӻ������GUI�����ϳ���ʶ��Ŀ�ͽ�ȡ�����ĳ��ƺ�ʶ������������
    
    %TODO:result = OCR(cut);
    
    %fprintf("����ʶ�����ǣ�%s",result);
    
end