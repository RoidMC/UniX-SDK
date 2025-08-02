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
function UDK_I18N.I18NGetKey(key, i18n_lang, i18n_Toml)
    local currentLang = i18n_lang
    local i18nTable = i18n_Toml[currentLang]

    -- 递归解析复杂键
    local function parseKey(tbl, parseKeyName)
        local keys = {}
        for k in parseKeyName:gmatch("[^%.%[%]]+") do
            table.insert(keys, k)
        end

        local current_value = tbl
        for _, k in ipairs(keys) do
            if type(current_value) == "table" then
                -- 检查是否为数组索引
                if tonumber(k) then
                    k = tonumber(k) -- Lua 数组索引从1开始，但TOML数组索引从0开始，所以不需要加1
                end
                current_value = current_value[k]
            else
                return nil
            end
        end
        return current_value
    end

    local parsedValue = parseKey(i18nTable, key)
    if parsedValue ~= nil then
        return parsedValue
    else
        local logOutput = string.format("[UDK:I18N] Missing Key: %s Lang: %s", key, currentLang)
        Log:PrintError(logOutput)
        return logOutput
    end
end

return UDK_I18N