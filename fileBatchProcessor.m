function fileBatchProcessor()

    % 创建主窗口
    fig = figure('Name', '文件批量处理器', 'NumberTitle', 'off', ...
        'Position', [100, 100, 800, 600], 'MenuBar', 'none', 'Color', [0.94 0.94 0.94]);
    
    % 初始化变量
    currentPath = pwd;
    handles = struct('fig', fig, 'path', currentPath);
    
    % 路径选择区
    uicontrol('Style', 'text', 'String', '目标文件夹:', 'Position', [20, 550, 70, 20], ...
        'BackgroundColor', [0.94 0.94 0.94]);
    pathEdit = uicontrol('Style', 'edit', 'String', currentPath, 'Position', [100, 550, 600, 25]);
    uicontrol('Style', 'pushbutton', 'String', '浏览', 'Position', [710, 550, 60, 25], ...
        'Callback', @(~,~) set(pathEdit, 'String', uigetdir(get(pathEdit, 'String'))));
    
    % 文件列表
    fileList = uicontrol('Style', 'listbox', 'Position', [20, 350, 760, 180], 'Max', 2);
    uicontrol('Style', 'pushbutton', 'String', '刷新', 'Position', [20, 320, 60, 25], ...
        'Callback', @(~,~) refreshList());
    uicontrol('Style', 'pushbutton', 'String', '全选', 'Position', [90, 320, 60, 25], ...
        'Callback', @(~,~) set(fileList, 'Value', 1:length(get(fileList, 'String'))));
    
    % 功能选择（下拉菜单替代单选按钮组）
    uicontrol('Style', 'text', 'String', '功能:', 'Position', [20, 280, 40, 20], ...
        'BackgroundColor', [0.94 0.94 0.94]);
    funcPopup = uicontrol('Style', 'popupmenu', 'String', {
        '1.添加前缀/后缀', '2.替换/删除', '3.更换新名', '4.日期命名', ...
        '5.规律命名', '6.按时间创建命名', '7.处理子文件夹', ...
        '8.分类处理', '9.自动分类到文件夹', '10.提取合并文件'}, ...
        'Position', [70, 280, 150, 25]);
    
    % 参数输入
    uicontrol('Style', 'text', 'String', '参数1:', 'Position', [240, 280, 50, 20], ...
        'BackgroundColor', [0.94 0.94 0.94]);
    param1 = uicontrol('Style', 'edit', 'Position', [300, 280, 150, 25]);
    uicontrol('Style', 'text', 'String', '参数2:', 'Position', [460, 280, 50, 20], ...
        'BackgroundColor', [0.94 0.94 0.94]);
    param2 = uicontrol('Style', 'edit', 'Position', [520, 280, 150, 25]);
    
    % 选项
    subCheck = uicontrol('Style', 'checkbox', 'String', '含子文件夹', ...
        'Position', [20, 240, 90, 20], 'BackgroundColor', [0.94 0.94 0.94]);
    prevCheck = uicontrol('Style', 'checkbox', 'String', '预览模式', ...
        'Position', [120, 240, 90, 20], 'Value', 1, 'BackgroundColor', [0.94 0.94 0.94]);
    typeCheck = uicontrol('Style', 'checkbox', 'String', '按类型分类', ...
        'Position', [220, 240, 100, 20], 'BackgroundColor', [0.94 0.94 0.94]);
    
    % 执行按钮
    uicontrol('Style', 'pushbutton', 'String', '执行', 'Position', [350, 200, 100, 40], ...
        'FontWeight', 'bold', 'BackgroundColor', [0.3 0.6 0.9], 'ForegroundColor', 'white', ...
        'Callback', @(~,~) execute());
    
    % 状态栏
    status = uicontrol('Style', 'text', 'String', '就绪', 'Position', [20, 10, 300, 20], ...
        'ForegroundColor', [0.4 0.4 0.4], 'HorizontalAlignment', 'left');
    
    refreshList();
    
    % 嵌套函数
    function refreshList()
        p = get(pathEdit, 'String');
        if ~exist(p, 'dir'), set(fileList, 'String', {'路径无效'}); return; end
        f = dir(fullfile(p, '*.*')); f = f(~[f.isdir]);
        set(fileList, 'String', {f.name}, 'Value', []);
        set(status, 'String', sprintf('找到 %d 个文件', length(f)));
    end

    function execute()
        p = get(pathEdit, 'String');
        if ~exist(p, 'dir'), msgbox('路径无效!', '错误', 'error'); return; end
        
        func = get(funcPopup, 'Value');
        s1 = get(param1, 'String'); s2 = get(param2, 'String');
        preview = get(prevCheck, 'Value');
        
        % 获取选中文件
        allFiles = get(fileList, 'String');
        sel = get(fileList, 'Value');
        if isempty(sel) || strcmp(allFiles{1}, '路径无效'), files = {}; else files = allFiles(sel); end
        
        try
            switch func
                case 1, r = proc(files, @(f,n) [s1 f s2 n], preview, p);  % 加前后缀
                case 2, r = proc(files, @(f,n) strrep(f,s1,s2), preview, p);  % 替换
                case 3, r = proc(files, @(f,n) sprintf('%s_%03d',s1,n), preview, p, 1);  % 新名
                case 4, r = dateProc(files, s1, preview, p);  % 日期命名
                case 5, r = patternProc(files, s1, preview, p);  % 规律命名
                case 6, r = timeProc(files, p, preview);  % 按时间命名
                case 7, r = subfolderProc(p, s1, preview);  % 子文件夹
                case 8, r = classifyProc(p, files, get(typeCheck, 'Value'), preview);  % 分类
                case 9, r = autoClassify(p, files, s1, preview);  % 自动分类
                case 10, r = extractProc(p, get(subCheck, 'Value'), preview);  % 提取合并
            end
            msgbox({iff(preview, '预览结果:', '执行完成:'), r}, iff(preview, '预览', '成功'));
            if ~preview, refreshList(); end
        catch ME
            msgbox(ME.message, '错误', 'error');
        end
    end

    % 关键修改：增加 p 作为输入参数
    function r = proc(files, nameFunc, preview, p, keepExt)
        if isempty(files), files = getFiles(p); end
        r = {}; 
        for i = 1:length(files)
            [~, name, ext] = fileparts(files{i});
            if nargin > 4 && keepExt, ext = ''; end
            newName = [nameFunc(name, i) ext];
            r{end+1} = doRename(files{i}, newName, preview, p);
        end
        r = join(r);
    end

    % 关键修改：增加 p 作为输入参数
    function r = dateProc(files, base, preview, p)
        if isempty(files), files = getFiles(p); end
        if isempty(base), base = 'file'; end
        r = {};
        for i = 1:length(files)
            [~, ~, ext] = fileparts(files{i});
            newName = sprintf('%s_%s%s', base, datestr(now+i-1, 'yyyymmdd'), ext);
            r{end+1} = doRename(files{i}, newName, preview, p);
        end
        r = join(r);
    end

    % 关键修改：增加 p 作为输入参数
    function r = patternProc(files, names, preview, p)
        if isempty(files), files = getFiles(p); end
        n = strsplit(names, {',', '，'}); n = strtrim(n);
        r = {};
        for i = 1:min(length(files), length(n))
            [~, ~, ext] = fileparts(files{i});
            r{end+1} = doRename(files{i}, sprintf('file_%s%s', n{i}, ext), preview, p);
        end
        r = join(r);
    end

    function r = timeProc(files, folder, preview)
        if isempty(files)
            f = dir(fullfile(folder, '*.*')); f = f(~[f.isdir]);
            [~, idx] = sort([f.datenum]); files = {f(idx).name};
        end
        r = {}; currDate = ''; cnt = 0;
        for i = 1:length(files)
            info = dir(fullfile(folder, files{i}));
            d = datestr(info.datenum, 'yyyymmdd');
            if ~strcmp(d, currDate), currDate = d; cnt = 1; else cnt = cnt + 1; end
            [~, ~, ext] = fileparts(files{i});
            r{end+1} = doRename(files{i}, sprintf('%s_%03d%s', d, cnt, ext), preview, folder);
        end
        r = join(r);
    end

    function r = subfolderProc(folder, mode, preview)
        d = dir(folder); d = d([d.isdir]); d = d(~ismember({d.name}, {'.', '..'}));
        r = {}; cnt = 0;
        for i = 1:length(d)
            f = getFiles(fullfile(folder, d(i).name));
            for j = 1:length(f)
                if strcmpi(mode, 'global'), cnt = cnt + 1; n = cnt; else n = j; end
                [~, ~, ext] = fileparts(f{j});
                r{end+1} = doRename(fullfile(d(i).name, f{j}), ...
                    sprintf('%s_%03d%s', d(i).name, n, ext), preview, folder);
            end
        end
        r = join(r);
    end

    function r = classifyProc(folder, files, byType, preview)
        if isempty(files), files = getFiles(folder); end
        if byType
            groups = containers.Map();
            for i = 1:length(files)
                [~, ~, ext] = fileparts(files{i});
                ext = lower(ext);
                if ~isKey(groups, ext), groups(ext) = {}; end
                g = groups(ext); g{end+1} = files{i}; groups(ext) = g;
            end
            k = keys(groups); r = {};
            for i = 1:length(k)
                g = groups(k{i});
                for j = 1:length(g)
                    [~, name, ext] = fileparts(g{j});
                    r{end+1} = doRename(g{j}, sprintf('%s_%03d%s', k{i}(2:end), j, ext), preview, folder);
                end
            end
        else
            r = proc(files, @(f,n) sprintf('file_%03d', n), preview, folder);
        end
        r = join(r);
    end

    function r = autoClassify(folder, files, pattern, preview)
        if isempty(files), files = getFiles(folder, 1); end
        if isempty(pattern), pattern = 'chinese'; end
        r = {};
        for i = 1:length(files)
            [~, name, ext] = fileparts(files{i});
            if strcmp(pattern, 'chinese')
                tok = regexp(name, '[\u4e00-\u9fa5]+', 'match');
                cat = iff(isempty(tok), '其他', tok{1});
            else
                tok = regexp(name, pattern, 'match');
                cat = iff(isempty(tok), '其他', tok{1});
            end
            tgt = fullfile(folder, cat);
            if ~preview && ~exist(tgt, 'dir'), mkdir(tgt); end
            newPath = fullfile(tgt, [name ext]);
            if exist(newPath, 'file') && ~preview
                newPath = fullfile(tgt, sprintf('%s_%s%s', name, datestr(now, 'HHMMSS'), ext));
            end
            if ~preview, movefile(fullfile(folder, files{i}), newPath); end
            r{end+1} = sprintf('%s -> %s\\%s', files{i}, cat, [name ext]);
        end
        r = join(r);
    end

    function r = extractProc(folder, includeSub, preview)
        tgt = fullfile(folder, '合并结果');
        if ~preview && ~exist(tgt, 'dir'), mkdir(tgt); end
        
        if includeSub, allF = getFilesRecursive(folder); else allF = getFiles(folder); end
        
        r = {};
        for i = 1:length(allF)
            if isstruct(allF{i})
                src = allF{i}.path; [~, fname, ext] = fileparts(allF{i}.name);
                [srcFolder, ~, ~] = fileparts(src); [~, folderName] = fileparts(srcFolder);
            else
                src = fullfile(folder, allF{i}); [~, fname, ext] = fileparts(allF{i});
                folderName = '当前文件夹';
            end
            
            newName = [fname ext];
            if exist(fullfile(tgt, newName), 'file')
                newName = sprintf('%s_%s%s', fname, folderName, ext);
            end
            if ~preview, copyfile(src, fullfile(tgt, newName)); end
            r{end+1} = sprintf('%s -> %s', allF{i}, newName);
        end
        r = join(r);
    end

    function s = doRename(old, new, preview, baseFolder)
        oldPath = fullfile(baseFolder, old);
        newPath = fullfile(baseFolder, new);
        if ~preview, movefile(oldPath, newPath); end
        s = sprintf('%s -> %s', old, new);
    end

    function f = getFiles(folder, recursive)
        if nargin < 2, recursive = false; end
        if recursive, f = getFilesRecursive(folder); return; end
        d = dir(fullfile(folder, '*.*')); f = {d(~[d.isdir]).name};
    end

    function f = getFilesRecursive(folder)
        f = {}; d = dir(folder); d = d(~ismember({d.name}, {'.', '..'}));
        for i = 1:length(d)
            path = fullfile(folder, d(i).name);
            if d(i).isdir
                sub = getFilesRecursive(path);
                f = [f, sub];
            else
                f{end+1} = struct('path', path, 'name', d(i).name);
            end
        end
    end

    function s = join(c), s = strjoin(c, '\n'); end
    function out = iff(cond, a, b), if cond, out = a; else, out = b; end, end
end