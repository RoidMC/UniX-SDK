-- ==================================================
-- * UniX SDK - Array
-- * Version: 0.0.1
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

local UDK_Array = {}

---|📘- 获取枚举数组内的指定数据
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-array/#udkarraygetvaluebyenum)
---@param table table Table表
---@param target string|number Key值或Value值
---@return string|number key 返回的Key值或Value值
function UDK_Array.GetValueByEnum(table, target)
    -- 如果输入是字符串（Key），直接返回值
    if type(target) == "string" then
        return table[target]
        -- 如果输入是数字（Value），遍历查找Key
    elseif type(target) == "number" then
        for key, value in pairs(table) do
            if value == target then
                return key
            end
        end
    end
    return nil -- 未找到
end

---|📘- 添加枚举数组内的指定数据
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-array/#udkarrayaddvaluebyenum)
---@param table table Table表
---@param key string Key值
---@param value string|number Value值
function UDK_Array.AddValueByEnum(table, key, value)
    table[key] = value
end

---|📘- 移除枚举数组内的指定数据
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-array/#udkarrayremovevaluebyenum)
---@param table table Table表
---@param target string|number Key值或Value值
function UDK_Array.RemoveValueByEnum(table, target)
    -- 如果输入是字符串（Key），直接移除
    if type(target) == "string" then
        table[target] = nil
        -- 如果输入是数字（Value），遍历查找并移除Key
    elseif type(target) == "number" then
        for key, value in pairs(table) do
            if value == target then
                table[key] = nil
                break
            end
        end
    end
end

---|📘- 替换枚举数组内的指定数据
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-array/#udkarrayreplacevaluebyenum)
---@param table table Table表
---@param target string|number 要替换的Key值或Value值
---@param newValue string|number 新的Value值
function UDK_Array.ReplaceValueByEnum(table, target, newValue)
    -- 如果输入是字符串（Key），直接替换值
    if type(target) == "string" then
        if table[target] ~= nil then
            table[target] = newValue
        end
        -- 如果输入是数字（Value），遍历查找并替换Key对应的值
    elseif type(target) == "number" then
        for key, value in pairs(table) do
            if value == target then
                table[key] = newValue
                break
            end
        end
    end
end

---|📘- 根据正则遍历枚举数组内的指定数据
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-array/#udkarrayforkeytovalueregx)
---@param table table Table表
---@param regX string 正则表达式
---@return table values 返回遍历的数据
function UDK_Array.ForKeyToValueRegX(table, regX)
    local resultTable = {} -- 创建一个空表来存储所有匹配的值
    for key, value in pairs(table) do
        if string.match(key, regX) then
            resultTable[key] = value -- 将匹配的值插入到resultTable表中
        end
    end
    return resultTable -- 返回包含所有匹配值的表
end

---|📘- 通用排序函数，按key排序
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-array/#udkarraysortarraybykey)
---@param table table 需要排序的表
---@return table sorted_table 返回排序后的表
function UDK_Array.SortArrayByKey(table)
    local sorted_table = {}
    for key, value in pairs(table) do
        sorted_table[#sorted_table + 1] = { key = key, value = value }
    end

    -- 冒泡排序
    local n = #sorted_table
    for i = 1, n do
        for j = 1, n - i do
            if sorted_table[j].key > sorted_table[j + 1].key then
                sorted_table[j], sorted_table[j + 1] = sorted_table[j + 1], sorted_table[j]
            end
        end
    end

    return sorted_table
end

return UDK_Array