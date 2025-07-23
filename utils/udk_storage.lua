-- ==================================================
-- * UniX SDK - Storage
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

local UDK_Storage = {}
-- 获取存档类型
local function saveTypeGet(saveType)
    local return_saveType
    if saveType == "Boolean" then
        return_saveType = Archive.TYPE.Bool
    elseif saveType == "Number" then
        return_saveType = Archive.TYPE.Number
    elseif saveType == "String" then
        return_saveType = Archive.TYPE.String
    else
        Log:PrintError("[UDK:Storage] Invalid save type: " .. tostring(saveType))
        return_saveType = false
    end
    return return_saveType
end

---| -📘 云存储玩家的数据
---<br>
---| `范围`：`服务端`
---@param player number 玩家ID
---@param saveType string 存储类型（Boolean、Number、String）
---@param saveName string 存储名称
---@param saveData boolean | number | string  存储数据
---@param autoIncrement boolean? 是否自动累加（仅Number类型有效，默认为false）
function UDK_Storage.ArchiveUpload(player, saveType, saveName, saveData, autoIncrement)
    local return_saveType = saveTypeGet(saveType)
    local tempData
    local tempAutoIncrement

    if autoIncrement == nil then
        tempAutoIncrement = false
    else
        tempAutoIncrement = autoIncrement
    end

    if return_saveType ~= false then
        local checkHasData = Archive:HasPlayerData(player, return_saveType, saveName)
        -- 如果存在Number类型的存档数据，则进行累加
        if checkHasData == true and return_saveType == Archive.TYPE.Number and tempAutoIncrement ~= false then
            tempData = Archive:GetPlayerData(player, return_saveType, saveName)
            saveData = tempData + saveData
        end
        Archive:SetPlayerData(player, return_saveType, saveName, saveData)
    end
end

---| -📘 云存储获取玩家数据
---<br>
---| `范围`：`服务端`
---@param player number 玩家ID
---@param saveType string 存储类型（Boolean、Number、String）
---@param saveName string 存储名称
---@return boolean | number | string returnData 存储数据
function UDK_Storage.ArchiveGet(player, saveType, saveName)
    local return_saveType = saveTypeGet(saveType)
    return Archive:GetPlayerData(player, return_saveType, saveName)
end

return UDK_Storage
