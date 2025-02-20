-- 引入需要匹配的配置文件
local ExportConfig = require("PLS.Insert.Conf.Path")
-- RegX正则匹配规则
local RegX_Rule = "regX Param"
-- 分隔符配置项
local SeparatorConfig = ",\n"  -- 默认分隔符为逗号加换行符

-- 定义一个函数来提取包含正则结果的键值对
local function extractExportData(config)
    local exportData = {}

    -- 遍历玩家中的所有键值对
    for key, value in pairs(config) do
        if type(value) == "table" then
            -- 如果值是一个表，递归检查其内容
            local subData = extractExportData(value)
            for subKey, subValue in pairs(subData) do
                exportData[subKey] = subValue
            end
        elseif type(key) == "string" and key:match(RegX_Rule) then
            -- 如果键包含正则匹配结果，则添加到结果数组中
            exportData[key] = value
        end
    end

    return exportData
end

-- 提取包含正则匹配结果的键值对
local exportData = extractExportData(ExportConfig)

-- 对数据进行排序
local sortedKeys = {}
for key in pairs(exportData) do
    table.insert(sortedKeys, key)
end
table.sort(sortedKeys)

-- 定义一个函数来处理打印和文件写入
local function processOutput(data, filename, separator)
    local file
    if filename then
        file = io.open(filename, "w")
        if not file then
            print("无法打开文件 " .. filename .. " 进行写入")
            return
        end
    end

    local output = {}
    for _, key in ipairs(sortedKeys) do
        table.insert(output, key .. " = \"" .. data[key] .. "\"")
    end

    -- 使用传入的分隔符
    local outputString = table.concat(output, separator)
    if file then
        file:write(outputString)
        file:close()
        print("数据已保存到 " .. filename)
    else
        print(outputString)
    end
end

-- 打印结果
processOutput(exportData, nil, SeparatorConfig)

-- 将结果保存到文件（可选）
processOutput(exportData, "exportData.txt", SeparatorConfig)