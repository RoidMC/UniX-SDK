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
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk) | [示例代码](https://github.com/RoidMC/UniX-SDK/blob/master/Sample/i18n.lua)
---@param key string 键名
---@param i18n_lang string 语言
---@param i18n_Toml table 配置表
---@return string pasreKey 解析后的键值
function UDK_I18N.I18NGetKey(key, i18n_lang, i18n_Toml)
    local currentLang = i18n_lang
    local i18nTable = i18n_Toml[currentLang]

    -- 递归解析复杂键
    local function parseKey(tbl, key)
        local keys = {}
        for k in key:gmatch("[^%.%[%]]+") do
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

    if parseKey(i18nTable, key) ~= nil then
        return parseKey(i18nTable, key)
    else
        return "Missing Key: " .. key .. " Lang: " .. currentLang
    end
end

return UDK_I18N