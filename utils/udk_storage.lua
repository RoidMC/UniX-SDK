-- ==================================================
-- * UniX SDK - Storage
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

---@class UDK.Storage
local UDK_Storage = {}

UDK_Storage.NetMsg = {
    ClientUpload = 200100,
    ClientQuery = 200101,
    ServerRespQuery = 200102
}

UDK_Storage.Status = {
    DebugMode = false -- 调试模式，启用后服务器可返回mock数据用于测试
}

local Conf = {
    EnvType = {
        Standalone = { ID = 0, Name = "Standalone" },
        Server = { ID = 1, Name = "Server" },
        Client = { ID = 2, Name = "Client" }
    }
}

-- 存储客户端查询的回调函数
local queryCallbacks = {}

---返回当前环境状态
---@return table {
---     envID: number,       -- 环境ID（Server=1, Client=2, Standalone=0）
---     envName: string,     -- 环境名称（"Server", "Client", "Standalone"）
---     isStandalone: boolean -- 是否为单机模式
---}
local function envCheck()
    local isStandalone = System:IsStandalone()
    local envType = isStandalone and Conf.EnvType.Standalone or
        (System:IsServer() and Conf.EnvType.Server or Conf.EnvType.Client)

    return {
        envID = envType.ID,
        envName = envType.Name,
        isStandalone = isStandalone
    }
end

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

-- 生成mock测试数据
local function generateMockData(saveType)
    if saveType == "Boolean" then
        return math.random(0, 1) == 1
    elseif saveType == "Number" then
        return math.random(1, 100)
    elseif saveType == "String" then
        local mockStrings = { "test_data", "mock_value", "sample_text", "demo_string" }
        return mockStrings[math.random(1, #mockStrings)]
    end
    return nil
end

--- 上传数据到服务器
---@param playerID number 玩家ID
---@param saveType string 存储类型字符串
---@param saveName string 存储名称
---@param saveData boolean | number | string 存储数据
---@param autoIncrement boolean? 是否自动累加
local function performUpload(playerID, saveType, saveName, saveData, autoIncrement)
    local return_saveType = saveTypeGet(saveType)
    local tempAutoIncrement = autoIncrement or false

    if return_saveType ~= false then
        local checkHasData = Archive:HasPlayerData(playerID, return_saveType, saveName)
        -- 如果存在Number类型的存档数据，则进行累加
        if checkHasData == true and return_saveType == Archive.TYPE.Number and tempAutoIncrement ~= false then
            local tempData = Archive:GetPlayerData(playerID, return_saveType, saveName)
            saveData = tempData + saveData
        end
        Archive:SetPlayerData(playerID, return_saveType, saveName, saveData)
    end
end

--- 查询数据（根据调试模式返回mock或真实数据）
---@param playerID number 玩家ID
---@param saveType string 存储类型字符串
---@param saveName string 存储名称
---@return any data 查询到的数据
local function performQuery(playerID, saveType, saveName)
    -- 检查是否启用调试模式返回mock数据
    if UDK_Storage.Status.DebugMode then
        return generateMockData(saveType)
    end

    local return_saveType = saveTypeGet(saveType)
    if return_saveType ~= false then
        -- 检查是否存在数据
        if Archive:HasPlayerData(playerID, return_saveType, saveName) then
            return Archive:GetPlayerData(playerID, return_saveType, saveName)
        end
    end
    return nil
end

-- 处理客户端上传请求
local function handleClientUpload(msg, playerId)
    if not msg or not msg.PlayerID or not msg.SaveType or not msg.SaveName or msg.SaveData == nil then
        Log:PrintError("[UDK:Storage] Invalid client upload message")
        return
    end

    -- 验证玩家ID是否匹配（安全检查）
    if msg.PlayerID ~= playerId then
        Log:PrintWarning("[UDK:Storage] Player ID mismatch in upload request")
        return
    end

    -- 调用共享函数执行上传
    performUpload(msg.PlayerID, msg.SaveType, msg.SaveName, msg.SaveData, msg.AutoIncrement)
end

-- 处理客户端查询请求
local function handleClientQuery(msg, playerId)
    if not msg or not msg.PlayerID or not msg.SaveType or not msg.SaveName then
        Log:PrintError("[UDK:Storage] Invalid client query message")
        return
    end

    -- 验证玩家ID是否匹配（安全检查）
    if msg.PlayerID ~= playerId then
        Log:PrintWarning("[UDK:Storage] Player ID mismatch in query request")
        return
    end

    -- 执行查询（会根据调试模式返回mock或真实数据）
    local data = performQuery(msg.PlayerID, msg.SaveType, msg.SaveName)

    -- 构造响应消息
    local responseMsg = {
        MsgID = UDK_Storage.NetMsg.ServerRespQuery,
        PlayerID = msg.PlayerID,
        SaveType = msg.SaveType,
        SaveName = msg.SaveName,
        SaveData = data
    }

    -- 发送响应给客户端
    System:SendToClient(playerId, UDK_Storage.NetMsg.ServerRespQuery, responseMsg)
end

-- 处理服务器响应查询
local function handleServerRespQuery(msg, playerId)
    if not msg or not msg.PlayerID or not msg.SaveType or not msg.SaveName then
        Log:PrintError("[UDK:Storage] Invalid server response query message")
        return
    end

    -- 检查是否有注册的回调函数
    local callbackKey = msg.PlayerID .. "_" .. msg.SaveType .. "_" .. msg.SaveName
    if queryCallbacks[callbackKey] then
        -- 调用回调函数
        queryCallbacks[callbackKey](msg.PlayerID, msg.SaveType, msg.SaveName, msg.SaveData)
        -- 移除已使用的回调
        queryCallbacks[callbackKey] = nil
    end
end

local function createMessageHandler()
    return function(msgId, msg, playerId)
        if msgId == UDK_Storage.NetMsg.ClientUpload then
            handleClientUpload(msg, playerId)
        elseif msgId == UDK_Storage.NetMsg.ClientQuery then
            handleClientQuery(msg, playerId)
        elseif msgId == UDK_Storage.NetMsg.ServerRespQuery then
            handleServerRespQuery(msg, playerId)
        end
    end
end

local function networkBindNotifyInit()
    if System:IsServer() then
        System:BindNotify(UDK_Storage.NetMsg.ClientUpload, createMessageHandler())
        System:BindNotify(UDK_Storage.NetMsg.ClientQuery, createMessageHandler())
    end

    if System:IsClient() then
        System:BindNotify(UDK_Storage.NetMsg.ServerRespQuery, createMessageHandler())
    end
end

-- 调用游戏运行事件，进行注册网络消息通知
System:RegisterEvent(Events.ON_BEGIN_PLAY, networkBindNotifyInit)

---|📘- 云存储玩家的数据
---
---| `范围`：`服务端` | `客户端`
---@param player number 玩家ID
---@param saveType string 存储类型（Boolean、Number、String）
---@param saveName string 存储名称
---@param saveData boolean | number | string  存储数据
---@param autoIncrement boolean? 是否自动累加（仅Number类型有效，默认为false）
function UDK_Storage.ArchiveUpload(player, saveType, saveName, saveData, autoIncrement)
    local envInfo = envCheck()
    -- 如果环境是服务端或者单机模式，直接调用存档API，否则则需要通过网络发送请求
    if envInfo.envID == Conf.EnvType.Server.ID or envInfo.isStandalone then
        -- 直接调用共享函数执行上传
        performUpload(player, saveType, saveName, saveData, autoIncrement)
    elseif envInfo.envID == Conf.EnvType.Client.ID then
        local msg = {
            MsgID = UDK_Storage.NetMsg.ClientUpload,
            PlayerID = player,
            SaveType = saveType,
            SaveName = saveName,
            SaveData = saveData,
            AutoIncrement = autoIncrement
        }
        System:SendToServer(msg.MsgID, msg)
    end
end

---|📘- 云存储获取玩家数据
---
---| `范围`：`服务端` | `客户端`
---
---| 在客户端环境中，可以使用回调函数处理异步返回的数据
---@param player number 玩家ID
---@param saveType string 存储类型（Boolean、Number、String）
---@param saveName string 存储名称
---@param callback function | nil 回调函数 function(playerId, saveType, saveName, data)，仅在客户端环境中使用
---@return boolean | number | string | nil returnData 存储数据，仅在服务端或单机模式下返回
function UDK_Storage.ArchiveGet(player, saveType, saveName, callback)
    local envInfo = envCheck()
    -- 优先处理服务端或单机模式
    if envInfo.envID == Conf.EnvType.Server.ID or envInfo.isStandalone then
        -- 服务端或单机模式下直接调用查询并返回结果
        local data = performQuery(player, saveType, saveName)
        if callback then
            callback(player, saveType, saveName, data)
        end
        return data
    elseif envInfo.envID == Conf.EnvType.Client.ID then
        -- 客户端模式下注册回调并发送查询请求
        if callback then
            local callbackKey = player .. "_" .. saveType .. "_" .. saveName
            -- 检查是否已存在回调函数，如果存在则先清理避免内存泄漏
            if queryCallbacks[callbackKey] then
                Log:PrintWarning("[UDK:Storage] Overwriting existing callback for key: " .. callbackKey)
            end
            queryCallbacks[callbackKey] = callback
        end

        local msg = {
            MsgID = UDK_Storage.NetMsg.ClientQuery,
            PlayerID = player,
            SaveType = saveType,
            SaveName = saveName
        }
        System:SendToServer(msg.MsgID, msg)
    else
        -- 不应该到达这里，如果到达说明环境检测有问题
        Log:PrintError("[UDK:Storage] ArchiveGet called in unexpected environment: " .. tostring(envInfo.envName))
        if callback then
            callback(player, saveType, saveName, nil)
        end
        return nil
    end
end

---|📘- 清理所有未使用的回调函数
---
---| `范围`：`客户端`
function UDK_Storage.ClearPendingCallbacks()
    local envInfo = envCheck()
    if envInfo.envID ~= Conf.EnvType.Client.ID or envInfo.isStandalone then
        Log:PrintWarning("[UDK:Storage] ClearPendingCallbacks can only be called on client side")
        return
    end

    local count = 0
    for key, _ in pairs(queryCallbacks) do
        queryCallbacks[key] = nil
        count = count + 1
    end
    Log:PrintLog("[UDK:Storage] Cleaned up " .. count .. " pending callbacks")
end

---| 📘- 获取待处理的回调数量
---
---| `范围`：`客户端`
---@return number count 待处理的回调数量
function UDK_Storage.GetPendingCallbackCount()
    local envInfo = envCheck()
    if envInfo.envID ~= Conf.EnvType.Client.ID or envInfo.isStandalone then
        Log:PrintWarning("[UDK:Storage] GetPendingCallbackCount can only be called on client side")
        return 0
    end

    local count = 0
    for _ in pairs(queryCallbacks) do
        count = count + 1
    end
    return count
end

return UDK_Storage
