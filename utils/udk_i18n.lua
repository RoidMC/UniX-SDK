-- ==================================================
-- * UniX SDK - I18N
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

local UDK_I18N = {}

---|📘- I18N获取键值
---<br>
---| `使用方法：UDK.I18N.I18NGetKey("keyName", "zh-CN", i18n_Toml)`
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-i18n/#udki18ni18ngetkey)
---@param key string 键名
---@param i18n_lang string 语言
---@param i18n_Toml table 配置表
---@return string pasreKey 解析后的键值
---@return boolean isExist 键值是否存在
function UDK_I18N.I18NGetKey(key, i18n_lang, i18n_Toml)
    local currentLang = i18n_lang and i18n_lang:lower()                        -- 标准化语言代码为小写
    local i18nTable = i18n_Toml[currentLang] or i18n_Toml[currentLang:upper()] -- 尝试大写版本

    if not i18nTable then
        -- 尝试不区分大小写查找语言代码
        for lang, content in pairs(i18n_Toml) do
            if lang:lower() == currentLang:lower() then
                i18nTable = content
                break
            end
        end
    end

    if not i18nTable then
        local logOutput = string.format("[UDK:I18N] Language not found: %s", currentLang)
        print(logOutput)
        return logOutput, false
    end

    -- 直接查找完整键
    if i18nTable[key] ~= nil then
        return i18nTable[key], true
    end

    -- 处理嵌套键
    local parts = {}
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end

    -- 递归查找嵌套值
    local function getNestedValue(tbl, index)
        if index > #parts then
            return tbl
        end

        local currentKey = parts[index]
        -- 处理数字索引
        if tonumber(currentKey) then
            currentKey = tonumber(currentKey)
        end

        if type(tbl) ~= "table" then
            return nil
        end

        -- 直接查找当前键
        local value = tbl[currentKey]

        -- 如果找不到当前键
        if value == nil then
            -- 1. 检查是否存在完整的点分隔键（如 "key.account_info"）
            local fullKey = table.concat(parts, ".", index)
            if tbl[fullKey] ~= nil then
                -- 如果找到完整键，并且还有更多部分要处理
                if index < #parts then
                    -- 如果完整键对应的值是表，继续递归查找
                    if type(tbl[fullKey]) == "table" then
                        return getNestedValue(tbl[fullKey], index + 1)
                    else
                        -- 如果不是表但还有更多部分，返回nil
                        return nil
                    end
                else
                    -- 如果这是最后一部分，直接返回值
                    return tbl[fullKey]
                end
            end

            -- 2. 特殊处理：检查是否存在嵌套表结构
            -- 例如 "test.content" 可能存储为 { test = { content = "值" } }
            if index == 1 and parts[2] and tbl[parts[1]] and type(tbl[parts[1]]) == "table" then
                return getNestedValue(tbl[parts[1]], 2)
            end

            -- 3. 尝试查找点分隔的键组合
            -- 例如 "key.account_info" 可能存储为 { ["key.account_info"] = { test = 1 } }
            for i = index + 1, #parts do
                local combinedKey = table.concat(parts, ".", index, i)
                if tbl[combinedKey] ~= nil then
                    if i == #parts then
                        return tbl[combinedKey]
                    elseif type(tbl[combinedKey]) == "table" then
                        return getNestedValue(tbl[combinedKey], i + 1)
                    end
                end
            end

            return nil
        end

        return getNestedValue(value, index + 1)
    end

    local result = getNestedValue(i18nTable, 1)

    if result ~= nil then
        return result, true
    else
        local logOutput = string.format("[UDK:I18N] Missing Key: %s Lang: %s", key, currentLang)
        Log:PrintError(logOutput)
        return logOutput, false
    end
end

return UDK_I18N
