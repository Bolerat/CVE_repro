function finalUI
    % 创建主窗口
    f = figure('Name', '变换域水印嵌入与检测系统', 'Position', [200 200 1000 600],...
        'NumberTitle', 'off', 'MenuBar', 'none', 'Color', 'white');

    % 创建面板 - 注意顺序
    inputPanel = uipanel('Title', '输入区域', 'Position', [0.02 0.35 0.3 0.6]);
    resultPanel = uipanel('Title', '处理结果', 'Position', [0.34 0.35 0.3 0.6]);
    paramPanel = uipanel('Title', '参数设置', 'Position', [0.66 0.35 0.32 0.6]);
    btnPanel = uipanel('Title', '操作区域', 'Position', [0.02 0.02 0.96 0.3]);

    % 在面板中创建axes
    ax1 = axes('Parent', inputPanel, 'Position', [0.1 0.35 0.8 0.6]); 
    image(ax1, 0.8 * ones(200, 200));
    colormap(ax1, gray);
    axis(ax1, 'image', 'off');
    title(ax1, '原始图像');
    
    ax2 = axes('Parent', inputPanel, 'Position', [0.1 0.1 0.8 0.2]);
    image(ax2, 0.8 * ones(50, 200));
    colormap(ax2, gray);
    axis(ax2, 'image', 'off');
    title(ax2, '水印图像');

    ax3 = axes('Parent', resultPanel, 'Position', [0.1 0.35 0.8 0.6]);
    image(ax3, 0.8 * ones(200, 200));
    colormap(ax3, gray);
    axis(ax3, 'image', 'off');
    title(ax3, '嵌入水印后的图像');
    
    ax4 = axes('Parent', resultPanel, 'Position', [0.1 0.1 0.8 0.2]);
    image(ax4, 0.8 * ones(50, 200));
    colormap(ax4, gray);
    axis(ax4, 'image', 'off');
    title(ax4, '提取的水印');

    % 嵌入强度控制
    uicontrol(paramPanel, 'Style', 'text', 'String', '嵌入强度(α):',...
        'Position', [20 280 80 20]);
    alphaSlider = uicontrol(paramPanel, 'Style', 'slider',...
        'Min', 0.1, 'Max', 100, 'Value', 20,...
        'Position', [20 260 200 20],...
        'Callback', @alphaChanged);
    alphaText = uicontrol(paramPanel, 'Style', 'text',...
        'String', '20', 'Position', [230 260 40 20]);

    % 检测阈值控制 - 修改Value默认值
    uicontrol(paramPanel, 'Style', 'text', 'String', '检测阈值:',...
        'Position', [20 220 80 20]);
    threshSlider = uicontrol(paramPanel, 'Style', 'slider',...
        'Min', 0, 'Max', 1, 'Value', 0.15,...
        'Position', [20 200 200 20],...
        'Callback', @thresholdChanged);
    threshText = uicontrol(paramPanel, 'Style', 'text',...
        'String', '0.15', 'Position', [230 200 40 20]);

    % 质量评估显示
    uicontrol(paramPanel, 'Style', 'text', 'String', 'PSNR:',...
        'Position', [20 160 80 20]);
    psnrText = uicontrol(paramPanel, 'Style', 'text',...
        'String', '--', 'Position', [100 160 80 20]);

    % 按钮面板
    uicontrol(btnPanel, 'Style', 'pushbutton', 'String', '载入原图',...
        'Position', [100 60 120 35], 'Callback', @loadOriginalImage);
    uicontrol(btnPanel, 'Style', 'pushbutton', 'String', '载入水印',...
        'Position', [250 60 120 35], 'Callback', @loadWatermark);
    uicontrol(btnPanel, 'Style', 'pushbutton', 'String', '嵌入水印',...
        'Position', [400 60 120 35], 'Callback', @embedWatermark);
    uicontrol(btnPanel, 'Style', 'pushbutton', 'String', '提取水印',...
        'Position', [550 60 120 35], 'Callback', @extractWatermark);

    % 全局变量 - 修改threshold默认值
    setappdata(f, 'originalImage', []);
    setappdata(f, 'watermark', []);
    setappdata(f, 'watermarkedImage', []);
    setappdata(f, 'alpha', 20);
    setappdata(f, 'threshold', 0.15);

    % 修改图像显示函数
    function displayImage(ax, img, titleStr)
        if ~isempty(img)
            axes(ax);
            imshow(img, [], 'Parent', ax);
            colormap(ax, gray);
            axis(ax, 'image', 'off');
            title(ax, titleStr);
            drawnow;
        end
    end

    % 修改回调函数中的显示部分
    function loadOriginalImage(~,~)
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', '图像文件 (*.jpg,*.png,*.bmp)'});
        if filename ~= 0
            try
                img = imread(fullfile(pathname, filename));
                img = im2double(img);
                setappdata(f, 'originalImage', img);
                displayImage(ax1, img, '原始图像');
            catch
                msgbox('图像加载失败！', '错误');
            end
        end
    end

    function loadWatermark(~,~)
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', '图像文件 (*.jpg,*.png,*.bmp)'});
        if filename ~= 0
            try
                wm = imread(fullfile(pathname, filename));
                if size(wm,3) > 1
                    wm = rgb2gray(wm);
                end
                wm = im2bw(wm, 0.5);
                setappdata(f, 'watermark', wm);
                displayImage(ax2, wm, '水印图像');
            catch
                msgbox('水印图像加载失败！', '错误');
            end
        end
    end

    % 修改水印嵌入函数
    function embedWatermark(~,~)
        img = getappdata(f, 'originalImage');
        wm = getappdata(f, 'watermark');
        alpha = getappdata(f, 'alpha');
        
        if isempty(img) || isempty(wm)
            msgbox('请先载入原图和水印图像！', '警告');
            return;
        end
        
        try
            if size(img,3) > 1
                img = rgb2gray(img);
            end
            
            % DCT水印嵌入
            [m,n] = size(img);
            wm_resize = imresize(wm, [32 32]);
            blocks = cell(floor(m/8), floor(n/8));
            
            % 显示进度条
            h = waitbar(0, '正在嵌入水印...');
            
            for i = 1:8:m-7
                waitbar(i/m, h);
                for j = 1:8:n-7
                    block = img(i:i+7, j:j+7);
                    dct_block = dct2(block);
                    
                    if i <= 32*8 && j <= 32*8
                        bi = floor(i/8) + 1;
                        bj = floor(j/8) + 1;
                        if wm_resize(bi,bj)
                            dct_block(4,4) = dct_block(4,4) * (1 + alpha/100);
                        end
                    end
                    
                    blocks{floor(i/8)+1, floor(j/8)+1} = idct2(dct_block);
                end
            end
            close(h);
            
            watermarked = cell2mat(blocks);
            setappdata(f, 'watermarkedImage', watermarked);
            
            % 显示结果
            figure(f);  % 确保主窗口激活
            displayImage(ax3, watermarked, '嵌入水印后的图像');
            
            % 计算并显示PSNR
            psnr_val = psnr(watermarked, img);
            set(psnrText, 'String', sprintf('%.2f dB', psnr_val));
            
        catch e
            msgbox(['水印嵌入失败：' e.message], '错误');
        end
    end

    % 修改水印提取函数
    function extractWatermark(~,~)
        watermarked = getappdata(f, 'watermarkedImage');
        original = getappdata(f, 'originalImage');
        threshold = getappdata(f, 'threshold');
        
        if isempty(watermarked) || isempty(original)
            msgbox('请先嵌入水印！', '警告');
            return;
        end
        
        try
            if size(original,3) > 1
                original = rgb2gray(original);
            end
            
            % 显示进度条
            h = waitbar(0, '正在提取水印...');
            
            [m,n] = size(original);
            extracted = zeros(32, 32);
            
            for i = 1:8:min(32*8,m-7)
                waitbar(i/(32*8), h);
                for j = 1:8:min(32*8,n-7)
                    block_orig = original(i:i+7, j:j+7);
                    block_water = watermarked(i:i+7, j:j+7);
                    
                    dct_orig = dct2(block_orig);
                    dct_water = dct2(block_water);
                    
                    bi = floor(i/8) + 1;
                    bj = floor(j/8) + 1;
                    
                    diff = abs(dct_water(4,4) - dct_orig(4,4)) / abs(dct_orig(4,4));
                    extracted(bi,bj) = diff > threshold;
                end
            end
            close(h);
            
            % 显示提取结果
            figure(f);  % 确保主窗口激活
            displayImage(ax4, extracted, '提取的水印');
            
        catch e
            msgbox(['水印提取失败：' e.message], '错误');
        end
    end

    function alphaChanged(hObject,~)
        alpha = get(hObject, 'Value');
        setappdata(f, 'alpha', alpha);
        set(alphaText, 'String', sprintf('%.1f', alpha));
    end

    function thresholdChanged(hObject,~)
        threshold = get(hObject, 'Value');
        setappdata(f, 'threshold', threshold);
        set(threshText, 'String', sprintf('%.2f', threshold));
    end
end