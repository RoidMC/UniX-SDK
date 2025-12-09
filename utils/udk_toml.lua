-- ==================================================
-- * UniX SDK - Toml Utils
-- * Version: 0.0.2
-- *
-- * License: MPL-2.0
-- * See LICENSE file for details.
-- *
-- * Attribution: Applications using this SDK must display "Powered by UniX SDK".
-- * See ATTRIBUTION.md for details.
-- *
-- * Website: https://www.roidmc.com
-- * Github: https://github.com/RoidMC
-- * SDK-Doc: https://wiki.roidmc.com/docs/unix-sdk
-- *
-- * 2025 © RoidMC Studios
-- ==================================================

--[[
* UDK Toml Parse Lib | UDK non-standard Toml parsing library
* 支持功能：
* - 解析单行字符串 | 支持解析单行字符串
* - 解析多行字符串 | 支持解析多行字符串，包括'''和"""格式
* - 解析整数和浮点数 | 支持解析十进制、十六进制、八进制和二进制整数及浮点数
* - 解析内联表 | 支持解析内联表结构
* - 解析布尔值 | 支持解析true和false
* - 解析日期和时间 | 支持解析ISO 8601格式的日期和时间
* - 解析数组 | 支持解析数组结构，包括嵌套数组
* - 解析注释 | 支持解析以#开头的注释
* - 解析嵌套表 | 支持解析多层嵌套的表结构
* - 解析键值对 | 支持解析键值对结构
* - 解析转义字符 | 支持基本转义序列
]]
---@class UDK_TomlUtils
local UDK_Toml_Lib = {}

--- 去除字符串两端的空白字符
local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

-- 调试输出函数 （可选）
local function debug_print(...)
    --print("[UDK:TomlDEBUG]", ...)
    --Log:PrintDebug("[UDK:TomlDebug]", ... )
end

-- 预定义转义字符映射表
local escape_chars = {
    b = '\\b',     -- 退格符 (\\b)
    t = '\\t',     -- 制表符 (\\t)
    n = '\\n',     -- 换行符 (\\n)
    f = '\\f',     -- 换页符 (\\f)
    r = '\\r',     -- 回车符 (\\r)
    ['"'] = '"',   -- 双引号 (\")
    ['\\'] = '\\', -- 反斜杠 (\\\\)
    ["'"] = "'"    -- 单引号 (\')
}

-- Unicode转义序列缓存
local unicode_cache = {}

-- 处理转义字符
local function unescape(str)
    debug_print("Unescaping string:", str)

    -- 使用单次替换而非多次替换
    local result = str:gsub('\\([btnfr\\"\'])', escape_chars)

    -- 处理Unicode转义序列（简化版本，只处理ASCII范围）
    -- 使用缓存避免重复计算
    result = result:gsub('\\u(%x%x%x%x)', function(hex)
        if unicode_cache[hex] then
            return unicode_cache[hex]
        end

        local num = tonumber(hex, 16)
        debug_print("Found Unicode sequence:", '\\u' .. hex, "Value:", num)
        local char
        if num < 128 then
            char = string.char(num)
        else
            char = '?' -- 对于非ASCII字符，返回占位符
        end
        unicode_cache[hex] = char
        return char
    end)

    debug_print("Unescaped result:", result)
    return result
end

--- 处理多行字符串
local function parse_multiline_string(value, quote_type)
    debug_print("Parsing multiline string:", value)
    debug_print("Quote type:", quote_type)

    -- 确定引号类型
    local quote = quote_type == 'single' and "'''" or '"""'

    -- 提取内容（从开始引号后到结束引号前）
    local content = value:match("^%s*" .. quote .. "(.-)" .. quote .. "%s*$")
    if not content then
        debug_print("Error: Could not extract content:", value)
        return value
    end
    debug_print("Extracted content:", content)

    -- 处理首行换行符
    if content:sub(1, 1) == '\n' then
        content = content:sub(2)
        debug_print("Removed leading newline")
    end

    -- 处理转义字符（只在双引号字符串中处理）
    if quote_type == 'double' then
        content = unescape(content)
        debug_print("After unescaping:", content)
    end

    return content
end

-- 预编译常用的正则表达式模式
local patterns = {
    triple_quote = "^%s*(\"\"\"|''')(.-)(\"\"\"|\'\'\')%s*$",
    single_line_string = "^%s*([\"'])(.-[^\\])%1%s*$",
    integer = "^%d+$",
    float = "^%d*%.?%d+$",
    inline_table = "^%s*%{.*%}%s*$",
    array = "^%[.*%]$",
    boolean_true = "^true$",
    boolean_false = "^false$",
    hex_integer = "^%s*0x[%da-fA-F]+$",
    oct_integer = "^%s*0o[%d]+$",
    bin_integer = "^%s*0b[%d]+$",
    date_time = "^%s*%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%dZ%s*$",
    local_date = "^%s*%d%d%d%d%-%d%d%-%d%d%s*$",
    local_time = "^%s*%d%d:%d%d(:%d%d(%.%d+)?)?%s*$",
    local_date_time = "^%s*%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d(:%d%d(%.%d+)?)?%s*$",
    offset_date_time = "^%s*(%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d)[+-]%d%d:%d%d%s*$",
    parse_offset_datetime = function(value)
        -- 使用更精确的正则表达式匹配带时区偏移的日期时间
        local year, month, day, hour, min, sec, offset_sign, offset_h, offset_m =
            value:match("^%s*(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)([%+%-])(%d%d):(%d%d)%s*$")

        debug_print("Attempting to parse:", value)

        if not year then
            -- 尝试另一种格式匹配
            year, month, day, hour, min, sec, offset_sign, offset_h, offset_m =
                value:match("(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):(%d%d)([%+%-])(%d%d):(%d%d)")

            if not year then
                debug_print("Failed to parse offset datetime:", value)
                return value
            end
        end

        debug_print("Successfully parsed components:")
        debug_print("Date:", year, month, day)
        debug_print("Time:", hour, min, sec)
        debug_print("Offset:", offset_sign, offset_h, offset_m)

        -- 转换为UTC时间
        local offset_hour_num = tonumber(offset_h)
        local offset_min_num = tonumber(offset_m)

        -- 根据符号调整偏移量
        if offset_sign == "+" then
            offset_hour_num = -offset_hour_num
            offset_min_num = -offset_min_num
        end

        local utc_hour = tonumber(hour) + offset_hour_num
        local utc_min = tonumber(min) + offset_min_num

        debug_print("UTC time calculation:", utc_hour, utc_min)

        -- 处理分钟溢出
        if utc_min < 0 then
            utc_min = utc_min + 60
            utc_hour = utc_hour - 1
        elseif utc_min >= 60 then
            utc_min = utc_min - 60
            utc_hour = utc_hour + 1
        end

        -- 处理跨日情况
        local day_num = tonumber(day)
        if utc_hour < 0 then
            utc_hour = utc_hour + 24
            day_num = day_num - 1
        elseif utc_hour >= 24 then
            utc_hour = utc_hour - 24
            day_num = day_num + 1
        end

        -- 确保日期格式正确（补零）
        local day_str = string.format("%02d", day_num)

        debug_print("Final UTC time:", year, month, day_str, utc_hour, utc_min, sec)

        return string.format("%s-%s-%sT%02d:%02d:%02d.000Z", year, month, day_str, utc_hour, utc_min, sec)
    end
}

--- 根据值的类型进行解析
local function parse_value(value)
    -- 处理多行字符串（在其他类型检查之前）
    local start_quote, content, end_quote = value:match(patterns.triple_quote)
    if start_quote then
        local quote_type = start_quote:sub(1, 1) == '"' and 'double' or 'single'
        return parse_multiline_string(value, quote_type)
    end

    -- 增加对单行字符串的特殊处理
    if value:match('^%s*".*"%s*$') or value:match("^%s*'.*'%s*$") then
        local quote_char, str = value:match('^%s*(["\'])(.-[^\\])%1%s*$')
        if quote_char and str then
            if quote_char == '"' then
                return unescape(str) -- 双引号字符串需要处理转义
            else
                return str           -- 单引号字符串不处理转义
            end
        end
    end

    if value:match(patterns.integer) then
        return tonumber(value) -- 整数
    elseif value:match(patterns.float) then
        return tonumber(value) -- 浮点数
    elseif value:match(patterns.inline_table) then
        -- 内联表
        local inline_table = {}
        value = value:sub(value:find("{") + 1, value:find("}") - 1) -- 去除花括号

        local pos = 1
        local len = #value
        local depth = 0
        local in_string = false
        local string_char = nil
        local key_start = 1
        local key_end = nil
        local val_start = nil
        local val_end = nil

        while pos <= len do
            local char = value:sub(pos, pos)

            -- 处理字符串
            if not in_string and (char == '"' or char == "'") and (pos == 1 or value:sub(pos - 1, pos - 1) ~= '\\') then
                in_string = true
                string_char = char
            elseif in_string and char == string_char and value:sub(pos - 1, pos - 1) ~= '\\' then
                in_string = false
            end

            -- 处理嵌套结构
            if not in_string then
                if char == '{' or char == '[' then
                    depth = depth + 1
                elseif char == '}' or char == ']' then
                    depth = depth - 1
                elseif char == '=' and depth == 0 and not key_end then
                    key_end = pos - 1
                    val_start = pos + 1
                elseif char == ',' and depth == 0 and not in_string then
                    if not val_end then
                        val_end = pos - 1
                    end

                    -- 解析键值对
                    if key_end and val_start then
                        local key_str = trim(value:sub(key_start, key_end))
                        local val_str = trim(value:sub(val_start, val_end))
                        inline_table[key_str] = parse_value(val_str)

                        -- 重置状态
                        key_start = pos + 1
                        key_end = nil
                        val_start = nil
                        val_end = nil
                    end
                end
            end

            pos = pos + 1
        end

        -- 处理最后一个键值对
        if key_end and val_start and not val_end then
            val_end = len
            local key_str = trim(value:sub(key_start, key_end))
            local val_str = trim(value:sub(val_start, val_end))
            inline_table[key_str] = parse_value(val_str)
        end

        return inline_table
    elseif value:match(patterns.array) then
        -- 数组
        local array = {}
        value = value:sub(2, -2) -- 去除方括号
        local pos = 1
        local len = #value
        local depth = 0 -- 括号/方括号嵌套深度
        local buffer = ""
        local in_string = false
        local string_char = nil
        local key_buffer = nil
        local in_key = false

        while pos <= len do
            local char = value:sub(pos, pos)

            if not in_string then
                if char == '[' or char == '{' then
                    depth = depth + 1
                elseif char == ']' or char == '}' then
                    depth = depth - 1
                elseif (char == '"' or char == "'") and value:sub(pos - 1, pos - 1) ~= '\\' then
                    in_string = true
                    string_char = char
                elseif char == '=' and depth == 0 then
                    -- 发现键值对
                    key_buffer = trim(buffer)
                    buffer = ""
                    in_key = true
                    pos = pos + 1
                    goto continue
                elseif char == ',' and depth == 0 then
                    if buffer ~= "" then
                        if in_key then
                            -- 这是一个键值对
                            local val = parse_value(trim(buffer))
                            if type(array[1]) ~= "table" then array[1] = {} end
                            array[1][key_buffer] = val
                            in_key = false
                        else
                            -- 这是一个普通数组元素
                            table.insert(array, parse_value(trim(buffer)))
                        end
                        buffer = ""
                    end
                    pos = pos + 1
                    goto continue
                end
            else
                if char == string_char and value:sub(pos - 1, pos - 1) ~= '\\' then
                    in_string = false
                end
            end

            buffer = buffer .. char
            pos = pos + 1
            ::continue::
        end

        if buffer ~= "" then
            if in_key then
                -- 最后一个键值对
                local val = parse_value(trim(buffer))
                if type(array[1]) ~= "table" then array[1] = {} end
                array[1][key_buffer] = val
            else
                -- 最后一个数组元素
                table.insert(array, parse_value(trim(buffer)))
            end
        end

        -- 如果只有一个表元素，直接返回该表
        if #array == 1 and type(array[1]) == "table" then
            return array[1]
        end
        return array
    elseif value:match(patterns.boolean_true) then
        return true  -- 布尔值 true
    elseif value:match(patterns.boolean_false) then
        return false -- 布尔值 false
    elseif value:match(patterns.offset_date_time) then
        -- 带偏移量的日期时间（必须在local_date_time之前检查，避免错误匹配）
        debug_print("Found offset date time:", value)
        local result = patterns.parse_offset_datetime(value)
        debug_print("Converted to UTC:", result)
        return result
    elseif value:match(patterns.date_time) then
        -- 日期时间
        return value
    elseif value:match(patterns.local_date_time) then
        -- 本地日期时间
        return value
    elseif value:match(patterns.local_date) then
        -- 本地日期
        return value
    elseif value:match(patterns.local_time) then
        -- 本地时间
        return value
    elseif value:match(patterns.hex_integer) then
        -- 十六进制整数
        return tonumber(value:sub(3), 16)
    elseif value:match(patterns.oct_integer) then
        -- 八进制整数
        return tonumber(value:sub(3), 8)
    elseif value:match(patterns.bin_integer) then
        -- 二进制整数
        return tonumber(value:sub(3), 2)
    else
        return value
    end
end

local function parse_line(line, current_table)
    -- 先处理注释，但需要考虑字符串内的#不是注释
    local content_part = line
    local in_string = false
    local string_char = nil
    local comment_pos = nil

    -- 扫描行，找到不在字符串内的#字符
    for i = 1, #line do
        local char = line:sub(i, i)

        -- 处理字符串开始和结束
        if not in_string and (char == '"' or char == "'") then
            in_string = true
            string_char = char
        elseif in_string and char == string_char and line:sub(i - 1, i - 1) ~= '\\' then
            in_string = false
        end

        -- 如果找到不在字符串内的#，标记为注释开始
        if not in_string and char == '#' then
            comment_pos = i
            break
        end
    end

    -- 如果有注释，截取注释前的内容
    if comment_pos then
        content_part = line:sub(1, comment_pos - 1)
    end

    local key, value = content_part:match("([^=]+)%s*=%s*(.*)")
    if key and value then
        key = trim(key)                         -- 去除键的空白字符
        value = trim(value)                     -- 去除值的空白字符
        debug_print("Parsing key-value:", key, "=", value)
        current_table[key] = parse_value(value) -- 解析值并存储到当前表中
    end
end

local function parse_table_header(line, data)
    local table_name = line:match("^%[(.-)%]$")
    if table_name then
        table_name = trim(table_name) -- 去除表名的空白字符
        local keys = {}
        for k in table_name:gmatch("[^%.]+") do
            table.insert(keys, k) -- 分割表名并存储到键数组中
        end
        local current_table = data
        for i, k in ipairs(keys) do
            if not current_table[k] then
                current_table[k] = {}        -- 如果当前键不存在则创建新表
            end
            current_table = current_table[k] -- 进入下一层表
        end
        return current_table
    end
end

---|📘- Toml库 - 解析Toml数据
---@param toml_string string Toml字符串
---@return table data 解析结果
function UDK_Toml_Lib.Parse(toml_string)
    local data = {}
    local current_table = data
    local in_multiline = false
    local multiline_type = nil
    local multiline_key = nil
    local multiline_content = {}
    local multiline_indent = nil
    -- 多行数组相关变量
    local in_multiline_array = false
    local multiline_array_key = nil
    local multiline_array_content = ""
    local multiline_array_depth = 0

    -- 检查toml_string是否为nil或空字符串
    if not toml_string or toml_string == "" then
        debug_print("Warning: Empty or nil toml_string provided")
        print("[UDK Toml Lib] Warning: Empty or nil toml_string provided")
        return data
    end

    -- 预先分割行，避免多次调用gmatch
    local lines = {}
    for line in toml_string:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for _, line in ipairs(lines) do
        line = trim(line)

        if in_multiline then
            debug_print("Processing multiline content:", line)
            if line:match("^%s*" .. multiline_type .. "%s*$") then
                -- 结束多行字符串
                local end_quote_pos = line:find(multiline_type)
                local content_line = line:sub(1, end_quote_pos - 1)
                if #content_line > 0 then
                    table.insert(multiline_content, content_line)
                end

                local full_content = multiline_type .. table.concat(multiline_content, "\n") .. multiline_type
                debug_print("Full multiline content:", full_content)

                current_table[multiline_key] = parse_multiline_string(full_content,
                    multiline_type == "'''" and 'single' or 'double')
                debug_print("Parsed multiline result:", current_table[multiline_key])

                in_multiline = false
                multiline_content = {}
                multiline_indent = nil
                debug_print("Exiting multiline mode")
            else
                -- 保持缩进一致性
                if multiline_indent and line:match("^" .. multiline_indent) then
                    line = line:sub(#multiline_indent + 1)
                end
                table.insert(multiline_content, line)
                debug_print("Added line to multiline content")
            end
        elseif in_multiline_array then
            debug_print("Processing multiline array content:", line)

            -- 处理注释
            local comment_pos = line:find("#")
            if comment_pos then
                line = line:sub(1, comment_pos - 1)
                line = trim(line)
            end

            if line ~= "" then
                -- 计算方括号深度
                for c in line:gmatch(".") do
                    if c == "[" then
                        multiline_array_depth = multiline_array_depth + 1
                    elseif c == "]" then
                        multiline_array_depth = multiline_array_depth - 1
                        if multiline_array_depth == 0 then
                            -- 数组结束
                            multiline_array_content = multiline_array_content .. line:sub(1, line:find("]"))
                            debug_print("Multiline array complete:", multiline_array_content)
                            current_table[multiline_array_key] = parse_value(multiline_array_content)
                            debug_print("Parsed multiline array result:", current_table[multiline_array_key])
                            in_multiline_array = false
                            multiline_array_content = ""
                            break
                        end
                    end
                end

                if in_multiline_array then
                    -- 如果数组还没结束，添加当前行到内容中
                    if multiline_array_content ~= "" and not multiline_array_content:match(",$%s*$") then
                        multiline_array_content = multiline_array_content .. "\n"
                    end
                    multiline_array_content = multiline_array_content .. line
                    debug_print("Updated multiline array content:", multiline_array_content)
                end
            end
        else
            if line:match("^%s*#") or line == "" then
                -- 注释或空行
                debug_print("Skipping comment or empty line:", line)
            elseif line:match("^%[.-%]$") then
                -- 表头
                debug_print("Processing table header:", line)
                current_table = parse_table_header(line, data)
            else
                -- 检查是否开始多行数组
                local key, array_start = line:match("([^=]+)%s*=%s*(%[.*)$")
                -- 确保不是内联表（不以 { 开头）
                if key and array_start and not array_start:match("%]%s*$") and not line:match("=%s*{") then
                    debug_print("Starting multiline array:", key)
                    multiline_array_key = trim(key)
                    in_multiline_array = true
                    multiline_array_content = array_start

                    -- 计算初始方括号深度
                    multiline_array_depth = 0
                    for c in array_start:gmatch(".") do
                        if c == "[" then
                            multiline_array_depth = multiline_array_depth + 1
                        elseif c == "]" then
                            multiline_array_depth = multiline_array_depth - 1
                        end
                    end
                    debug_print("Initial array depth:", multiline_array_depth)

                    -- 检查是否在同一行结束
                    if multiline_array_depth == 0 then
                        debug_print("Array completed in the same line")
                        current_table[multiline_array_key] = parse_value(multiline_array_content)
                        in_multiline_array = false
                        multiline_array_content = ""
                    end
                else
                    -- 检查是否开始多行字符串
                    local key = line:match("([^=]+)%s*=%s*\"\"\"")
                    if key then
                        debug_print("Starting double-quoted multiline string:", key)
                        multiline_type = '"""'
                        multiline_key = trim(key)
                        in_multiline = true
                        multiline_content = {}
                        -- 记录缩进
                        multiline_indent = line:match("^(%s*)")
                        local content = line:match("=\"\"\"(.*)$")
                        if content then
                            table.insert(multiline_content, content)
                            debug_print("Added first line of content:", content)
                        end
                    else
                        key = line:match("([^=]+)%s*=%s*'''")
                        if key then
                            debug_print("Starting single-quoted multiline string:", key)
                            multiline_type = "'''"
                            multiline_key = trim(key)
                            in_multiline = true
                            multiline_content = {}
                            -- 记录缩进
                            multiline_indent = line:match("^(%s*)")
                            local content = line:match("='''(.*)$")
                            if content then
                                table.insert(multiline_content, content)
                                debug_print("Added first line of content:", content)
                            end
                        else
                            -- 普通键值对
                            debug_print("Processing regular key-value pair:", line)
                            parse_line(line, current_table)
                        end
                    end
                end
            end
        end
    end

    if in_multiline then
        debug_print("Warning: Unclosed multiline string at end of input")
    end

    if in_multiline_array then
        debug_print("Warning: Unclosed multiline array at end of input")
    end

    return data
end

return UDK_Toml_Lib
