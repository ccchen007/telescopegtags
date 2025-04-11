-- 执行 global 符号查找命令
local function exec_global_symbol(symbol, extras)
    local global_cmd = string.format('global --result="grep" %s "%s" 2>&1', extras, symbol)
    return require("telescope-gtags").exec_global(global_cmd)
end

-- 执行 global 查找当前文件标签命令
local function exec_global_current_file()
    local file = vim.call("expand", '%')
    local global_cmd = string.format('global --result="grep" -f "%s" 2>&1', file)
    return require("telescope-gtags").exec_global(global_cmd)
end

-- 执行 global 命令并处理结果
local function exec_global(global_cmd)
    local result = {}
    local f = io.popen(global_cmd)

    result.count = 0
    repeat
        local line = f:read("*l")
        if line then
            local path, line_nr, text = string.match(line, "(.*):(%d+):(.*)")
            if path and line_nr then
                table.insert(result, { path = path, line_nr = tonumber(line_nr), text = text, raw = line })
                result.count = result.count + 1
            end
        end
    until line == nil

    f:close()
    return result
end

-- 查找符号定义
local function global_definition(symbol)
    return exec_global_symbol(symbol, "-d")
end

-- 查找符号引用
local function global_reference(symbol)
    return exec_global_symbol(symbol, "-r")
end

-- 引入 telescope 相关模块
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- 定义 gtags 选择器函数，支持过滤
local function gtags_picker(gtags_result, filter_func)
    -- 过滤结果
    local filtered_result = {}
    filtered_result.count = 0
    for _, entry in ipairs(gtags_result) do
        if not filter_func or filter_func(entry) then
            table.insert(filtered_result, entry)
            filtered_result.count = filtered_result.count + 1
        end
    end

    -- 如果过滤后无结果则提示并返回
    if filtered_result.count == 0 then
        print(string.format("E9999: Error gtags there is no symbol after filtering"))
        return
    end

    -- 如果只有一个结果则直接打开文件
    if filtered_result.count == 1 then
        vim.api.nvim_command(string.format(":edit +%d %s", filtered_result[1].line_nr, filtered_result[1].path))
        return
    end

    -- 创建 telescope 选择器
    local opts = {
        layout_strategy = "vertical",  -- 设置为垂直模式
        layout_config = {
            vertical = {
                width = 0.7,  -- 调整宽度，适配需要
                mirror = true, -- preview窗口在result下方
                preview_height = 0.3,  -- 设置预览区域的高度
            },
        },
    }
    pickers.new(opts, {
        prompt_title = "GNU Gtags",
        finder = finders.new_table({
            results = filtered_result,
            entry_maker = function(entry)
                return {
                    value = entry.raw,
                    ordinal = entry.raw,
                    display = entry.raw,
                    filename = entry.path,
                    path = entry.path,
                    lnum = entry.line_nr,
                    start = entry.line_nr,
                    col = 1,
                }
            end,
        }),
        previewer = conf.grep_previewer(opts),
        sorter = conf.generic_sorter(opts),
    }):find()
end

-- 模块表，记录作业运行状态
local M = { job_running = false }

-- 显示符号定义，支持过滤
function M.showDefinition(filter_func)
    local current_word = vim.call("expand", "<cword>")
    if current_word == nil then
        return
    end
    -- 精确匹配
    local gtags_result = global_definition(string.format('^%s$', current_word))
    gtags_picker(gtags_result, filter_func)
end

-- 显示符号引用，支持过滤
function M.showReference(filter_func)
    local current_word = vim.call("expand", "<cword>")
    if current_word == nil then
        return
    end
    -- 精确匹配
    local gtags_result = global_reference(string.format('^%s$', current_word))
    gtags_picker(gtags_result, filter_func)
end

-- 显示当前文件标签
function M.showCurrentFileTags()
    gtags_picker(exec_global_current_file())
end

-- 执行 global -u 命令更新数据库
local function global_update()
    local loop = vim.loop
    local job_handle, pid = loop.spawn("global", {
        args = { "-u" },
    }, function(code, signal)
        if code ~= 0 then
            print("ERROR: global -u return errors")
        end

        M.job_running = false
        job_handle:close()
    end)
end

-- 检查并触发 global 数据库更新
function M.updateGtags()
    local loop = vim.loop
    local handle = loop.spawn("global", {
        args = { "--print", "dbpath" },
    }, function(code, signal)
        if code == 0 and not M.job_running then
            M.job_running = true
            global_update()
        end
        handle:close()
    end)
end

-- 设置自动增量更新
function M.setAutoIncUpdate(enable)
    if enable then
        vim.api.nvim_command("augroup AutoUpdateGtags")
        vim.api.nvim_command('autocmd BufWritePost * lua require("telescope-gtags").updateGtags()')
        vim.api.nvim_command("augroup END")
    end
end

-- 生成过滤掉指定文件夹的函数
local function generate_folder_filter(folder_name)
    return function(entry)
        return not string.find(entry.path, folder_name)
    end
end

-- 生成根据文件类型过滤的函数
local function generate_file_type_filter(file_types)
    return function(entry)
        if not file_types or #file_types == 0 then
            return true
        end
        for _, file_type in ipairs(file_types) do
            if string.find(entry.path, "%." .. file_type .. "$") then
                return true
            end
        end
        return false
    end
end

-- 合并多个过滤函数
local function combine_filters(...)
    local filters = {...}
    return function(entry)
        for _, filter in ipairs(filters) do
            if not filter(entry) then
                return false
            end
        end
        return true
    end
end

M.exec_global = exec_global
M.generate_folder_filter = generate_folder_filter
M.generate_file_type_filter = generate_file_type_filter
M.combine_filters = combine_filters

return M
