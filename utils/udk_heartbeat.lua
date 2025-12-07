-- ==================================================
-- * UniX SDK - Heartbeat Monitor
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

---@class UDK.Heartbeat
local UDK_Heartbeat = {}

-- 心跳包网络消息ID定义
UDK_Heartbeat.NetMsg = {
    Server = 210003,
    Client = 210004
}

-- 心跳包配置
UDK_Heartbeat.Config = {
    Interval = 3,       -- 默认心跳间隔(秒)
    Timeout = 1,        -- 超时时间(秒)，单机模式需要更宽松
    AutoSend = true,    -- 自动发送心跳包
    DebugPrint = false, -- 调试打印，默认关闭以减少日志量
    EnvType = {
        Server = { ID = 1, Name = "Server" },
        Client = { ID = 2, Name = "Client" },
        Standalone = { ID = 0, Name = "Standalone" }
    }
}

-- 存储回调函数
local callbacks = {}

-- 存储待处理的请求
local pendingRequests = {}

-- 请求ID计数器，用于确保唯一性
local requestCounter = 0

-- 心跳包统计数据
local heartbeatStats = {
    totalSent = 0,     -- 总发送次数
    totalReceived = 0, -- 总接收次数
    totalTimeout = 0,  -- 总超时次数
    playerStats = {},  -- 玩家统计数据 {playerID = {sent=0, received=0, timeout=0, lastSeen=0, avgResponseTime=0}}
    startTime = 0,     -- 统计开始时间
    resetTime = 0      -- 上次重置时间
}

-- 获取当前时间戳
local function getTimestamp()
    -- Lua2.0用不了os.time()
    -- 换成Lua2.0提供的接口生成需要的时间戳
    local serverTime = MiscService:GetServerTimeToTime()
    local timeStamp = MiscService:DateYMDHMSToTime(serverTime) --1702594800
    return math.floor(timeStamp * 1000)
end

-- 生成NanoID
local function nanoIDGenerate(size, randomSeed)
    math.randomseed(getTimestamp(), randomSeed)
    size = size or 21
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    local id = ""
    for _ = 1, size do
        local idx = math.random(1, #chars)
        id = id .. chars:sub(idx, idx)
    end
    return id
end

-- 生成唯一请求ID
local function generateUniqueRequestID()
    requestCounter = requestCounter + 1
    local timestamp = getTimestamp()
    local randomPart = nanoIDGenerate(6) -- 减少随机部分长度
    -- 格式: timestamp_counter_random
    return string.format("%d_%d_%s", timestamp, requestCounter, randomPart)
end

-- 创建格式化日志
local function createFormatLog(msg)
    local prefix = "[UDK:Heartbeat]"
    local log = string.format("%s %s", prefix, msg)
    return log
end

---返回当前环境状态
---@return table {
---     envID: number,       -- 环境ID（Server=1, Client=2, Standalone=0）
---     envName: string,     -- 环境名称（"Server", "Client", "Standalone"）
---     isStandalone: boolean -- 是否为单机模式
---}
local function envCheck()
    local isStandalone = System:IsStandalone()
    local envType = isStandalone and UDK_Heartbeat.Config.EnvType.Standalone or
        (System:IsServer() and UDK_Heartbeat.Config.EnvType.Server or UDK_Heartbeat.Config.EnvType.Client)

    return {
        envID = envType.ID,
        envName = envType.Name,
        isStandalone = isStandalone
    }
end

-- 自动发送心跳包
local function autoSendHeartbeat()
    local envInfo = envCheck()
    local sendLock = false
    if envInfo.envID == UDK_Heartbeat.Config.EnvType.Server.ID or envInfo.isStandalone then
        TimerManager:AddLoopTimer(0.1, function()
            if UDK_Heartbeat.Config.AutoSend and not sendLock then
                sendLock = true
                for _, v in ipairs(Character:GetAllPlayerIds()) do
                    UDK_Heartbeat.Send(v)
                end
                TimerManager:AddTimer(UDK_Heartbeat.Config.Interval, function()
                    sendLock = false
                end)
            end
        end)
    end
end

--  网络请求有效期
local function networkValidRequest(requestTime)
    local currentTime = getTimestamp()
    if currentTime - requestTime > UDK_Heartbeat.Config.Timeout * 1000 then
        return false, "请求已过期"
    else
        return true, "请求有效"
    end
end

-- 检查并处理超时请求
local function checkTimeoutRequests()
    local currentTime = getTimestamp()
    local envInfo = envCheck() -- 获取环境信息以判断是否为单机模式
    local timeoutCount = 0

    for reqID, request in pairs(pendingRequests) do
        -- 在单机模式下使用更宽松的超时检查
        local timeoutThreshold = UDK_Heartbeat.Config.Timeout * 1000
        if envInfo.isStandalone then
            -- 单机模式下增加50%的宽容时间
            timeoutThreshold = timeoutThreshold * 1.5
        end

        if currentTime - request.sendTime > timeoutThreshold then
            timeoutCount = timeoutCount + 1
            -- 请求超时
            if request.timeoutCallback then
                local success, errorMsg = pcall(request.timeoutCallback, request.playerID)
                if not success then
                    Log:PrintError(createFormatLog(string.format("超时回调执行出错: %s", errorMsg)))
                end
            end

            -- 更新统计数据
            heartbeatStats.totalTimeout = heartbeatStats.totalTimeout + 1
            local playerID = request.playerID
            if heartbeatStats.playerStats[playerID] then
                heartbeatStats.playerStats[playerID].timeout = heartbeatStats.playerStats[playerID].timeout + 1
            end

            if UDK_Heartbeat.Config.DebugPrint then
                Log:PrintLog(createFormatLog(string.format("请求 %s 超时，已清理 (发送时间: %d, 当前时间: %d, 阈值: %d)",
                    reqID, request.sendTime, currentTime, timeoutThreshold)))
            end

            pendingRequests[reqID] = nil
        end
    end
    if timeoutCount > 0 and UDK_Heartbeat.Config.DebugPrint then
        Log:PrintLog(createFormatLog(string.format("本轮超时检查发现 %d 个超时请求", timeoutCount)))
    end

    -- 在调试模式下打印pendingRequests的状态
    if UDK_Heartbeat.Config.DebugPrint then
        local pendingCount = 0
        for _ in pairs(pendingRequests) do
            pendingCount = pendingCount + 1
        end
        if pendingCount > 0 then
            Log:PrintLog(createFormatLog(string.format("当前还有 %d 个待处理请求", pendingCount)))
        end
    end
end

-- 客户端接收心跳包请求
local function clientRecvHeartbeat(msgId, msg, playerId)
    local currentTime = getTimestamp()
    local Msg = {
        timeStamp = currentTime,
        playerID = Character:GetLocalPlayerId()
    }

    -- 将请求ID包含在响应中，以便服务器可以匹配请求
    if msg and msg.reqID then
        Msg.reqID = msg.reqID
    end

    System:SendToServer(UDK_Heartbeat.NetMsg.Client, Msg)

    if UDK_Heartbeat.Config.DebugPrint then
        Log:PrintLog(createFormatLog(string.format("客户端发送心跳包响应 (消息ID: %s, 时间: %d)",
            msg and msg.reqID or "未知", currentTime)))
    end
end

-- 服务端接收心跳包响应
local function serverRecvHeartbeat(msgId, msg, playerId)
    local currentTime = getTimestamp()

    if msg and msg.playerID then
        local isValid, errorMsg = networkValidRequest(msg.timeStamp)
        if not isValid then
            Log:PrintError(createFormatLog(string.format("心跳包请求已过期: %s", errorMsg)))
            return
        end

        -- 更新统计数据
        heartbeatStats.totalReceived = heartbeatStats.totalReceived + 1
        local playerID = msg.playerID
        if not heartbeatStats.playerStats[playerID] then
            heartbeatStats.playerStats[playerID] = {
                sent = 0,
                received = 1,
                timeout = 0,
                lastSeen = currentTime,
                avgResponseTime = 0,
                responseHistory = {}
            }
        else
            heartbeatStats.playerStats[playerID].received = heartbeatStats.playerStats[playerID].received + 1
            heartbeatStats.playerStats[playerID].lastSeen = currentTime
        end

        if UDK_Heartbeat.Config.DebugPrint then
            Log:PrintLog(createFormatLog(string.format("收到来自玩家 %s 的心跳包响应 (消息ID: %s, 时间: %d)",
                Chat:GetCustomName(msg.playerID), msg.reqID or "未知", currentTime)))
        end

        -- 处理回调函数
        for id, callback in pairs(callbacks) do
            local success, result = pcall(callback, msg.playerID)
            if not success then
                Log:PrintError(createFormatLog(string.format("心跳包回调执行出错: %s", result)))
            end
        end
    end

    -- 检查是否有特定请求ID的响应
    if msg and msg.reqID and pendingRequests[msg.reqID] then
        -- 获取请求信息
        local request = pendingRequests[msg.reqID]

        -- 计算响应时间并更新统计
        local responseTime = getTimestamp() - request.sendTime
        local playerID = request.playerID

        if heartbeatStats.playerStats[playerID] then
            -- 保存最近10次响应时间用于计算平均值
            local history = heartbeatStats.playerStats[playerID].responseHistory or {}
            table.insert(history, responseTime)
            if #history > 10 then
                table.remove(history, 1)
            end

            -- 计算平均响应时间
            local sum = 0
            for _, time in ipairs(history) do
                sum = sum + time
            end
            heartbeatStats.playerStats[playerID].avgResponseTime = sum / #history
            heartbeatStats.playerStats[playerID].responseHistory = history
        end

        -- 正常响应，调用响应回调（如果存在）
        if request.responseCallback then
            local success, errorMsg = pcall(request.responseCallback, request.playerID)
            if not success then
                Log:PrintError(createFormatLog(string.format("响应回调执行出错: %s", errorMsg)))
            end
        end

        if UDK_Heartbeat.Config.DebugPrint then
            Log:PrintLog(createFormatLog(string.format("请求 %s 已收到响应，已清理 (响应时间: %d ms)",
                msg.reqID, responseTime)))
        end

        -- 清理请求
        pendingRequests[msg.reqID] = nil

        -- 在收到响应后主动检查是否有其他请求超时，提高处理及时性
        checkTimeoutRequests()
    elseif msg and msg.reqID and not pendingRequests[msg.reqID] and UDK_Heartbeat.Config.DebugPrint then
        Log:PrintWarning(createFormatLog(string.format("收到未知请求ID %s 的响应", msg.reqID)))
    end
end

-- 初始化网络监听
local function networkBindNotifyInit()
    if System:IsServer() then
        System:BindNotify(UDK_Heartbeat.NetMsg.Client, serverRecvHeartbeat)
    end

    if System:IsClient() then
        System:BindNotify(UDK_Heartbeat.NetMsg.Server, function(msgId, msg, playerId)
            if UDK_Heartbeat.Config.DebugPrint then
                Log:PrintLog(createFormatLog(string.format("收到来自服务器的心跳包请求 (消息ID: %s, 时间: %d)",
                    msg and msg.reqID or "未知", getTimestamp())))
            end
            clientRecvHeartbeat(msgId, msg, playerId)
        end)
    end
end

local function heartbeatInit()
    networkBindNotifyInit()
    autoSendHeartbeat()

    -- 初始化统计数据
    heartbeatStats.startTime = getTimestamp()
    heartbeatStats.resetTime = heartbeatStats.startTime

    -- 定期检查超时请求 - 使用0.5秒间隔以平衡精度和性能
    TimerManager:AddLoopTimer(0.5, function()
        checkTimeoutRequests()
    end)

    Log:PrintLog(createFormatLog("心跳包监控初始化完成"))
end

---|📘- 设置心跳包间隔
---
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-heartbeat/#udkheartbeatsetinterval)
---@param interval number 心跳包间隔(秒)
function UDK_Heartbeat.SetInterval(interval)
    if type(interval) == "number" and interval > 0 then
        UDK_Heartbeat.Config.Interval = interval
        Log:PrintLog(createFormatLog(string.format("心跳包间隔设置为: %d秒", interval)))
    else
        Log:PrintWarning(createFormatLog("无效的心跳包间隔值"))
    end
end

---|📘- 设置超时时间
---
---| `范围`：`服务端`
---
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-heartbeat/#udkheartbeatsettimeout)
---@param timeout number 超时时间(秒)
function UDK_Heartbeat.SetTimeout(timeout)
    if type(timeout) == "number" and timeout > 0 then
        UDK_Heartbeat.Config.Timeout = timeout
        Log:PrintLog(createFormatLog(string.format("超时时间设置为: %d秒", timeout)))
    else
        Log:PrintWarning(createFormatLog("无效的超时时间值"))
    end
end

---|📘- 设置自动发送心跳包
---
---| `范围`：`服务端`
---
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-heartbeat/#udkheartbeatsetautosend)
---@param autoSend boolean 是否自动发送心跳包
function UDK_Heartbeat.SetAutoSend(autoSend)
    if type(autoSend) == "boolean" then
        UDK_Heartbeat.Config.AutoSend = autoSend
        Log:PrintLog(createFormatLog(string.format("自动发送心跳包设置为: %s", autoSend and "开启" or "关闭")))
    else
        Log:PrintWarning(createFormatLog("无效的自动发送心跳包值"))
    end
end

---|📘- 发送心跳包
---
---| `范围`：`服务端`
---
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-heartbeat/#udkheartbeatsend)
---@param playerID number? 玩家ID(可选，不填则发送给所有客户端)
---@param timeoutCallback function? 超时回调函数(可选)
function UDK_Heartbeat.Send(playerID, timeoutCallback)
    local envInfo = envCheck()
    if envInfo.envID == UDK_Heartbeat.Config.EnvType.Server.ID or envInfo.isStandalone then
        local reqID = generateUniqueRequestID()
        local currentTime = getTimestamp()
        local Msg = {
            timeStamp = currentTime,
            reqID = reqID
        }

        if playerID == nil then
            System:SendToAllClients(UDK_Heartbeat.NetMsg.Server, Msg)
            if UDK_Heartbeat.Config.DebugPrint then
                Log:PrintLog(createFormatLog(string.format("向所有客户端发送心跳包请求 (消息ID: %s, 时间: %d)",
                    reqID, currentTime)))
            end

            -- 更新统计数据 - 群发消息按照在线玩家数量计算
            local players = Character:GetAllPlayerIds()
            heartbeatStats.totalSent = heartbeatStats.totalSent + #players
            for _, pid in ipairs(players) do
                if not heartbeatStats.playerStats[pid] then
                    heartbeatStats.playerStats[pid] = {
                        sent = 1,
                        received = 0,
                        timeout = 0,
                        lastSeen = 0,
                        avgResponseTime = 0,
                        responseHistory = {}
                    }
                else
                    heartbeatStats.playerStats[pid].sent = heartbeatStats.playerStats[pid].sent + 1
                end
            end
        else
            System:SendToClient(playerID, UDK_Heartbeat.NetMsg.Server, Msg)
            -- 存储请求信息用于跟踪
            pendingRequests[reqID] = {
                playerID = playerID,
                sendTime = currentTime,
                timeoutCallback = timeoutCallback
            }

            -- 更新统计数据
            heartbeatStats.totalSent = heartbeatStats.totalSent + 1
            if not heartbeatStats.playerStats[playerID] then
                heartbeatStats.playerStats[playerID] = {
                    sent = 1,
                    received = 0,
                    timeout = 0,
                    lastSeen = 0,
                    avgResponseTime = 0,
                    responseHistory = {}
                }
            else
                heartbeatStats.playerStats[playerID].sent = heartbeatStats.playerStats[playerID].sent + 1
            end

            if UDK_Heartbeat.Config.DebugPrint then
                Log:PrintLog(createFormatLog(string.format("向玩家 %d 发送心跳包请求，请求ID: %s (时间: %d)",
                    playerID, reqID, currentTime)))
            end
        end
    end
end

---|📘- 发送带跟踪的心跳包
---
---| `范围`：`服务端`
---
---| `说明`：`该API提供带WatchDog的心跳包，用于跟踪玩家是否掉线`
---@param playerID number 玩家ID
---@param timeoutCallback function? 超时回调函数(可选)
---@param responseCallback function? 响应回调函数(可选)
function UDK_Heartbeat.SendWithTracking(playerID, timeoutCallback, responseCallback)
    local envInfo = envCheck()
    if envInfo.envID == UDK_Heartbeat.Config.EnvType.Server.ID or envInfo.isStandalone then
        local reqID = generateUniqueRequestID()
        local currentTime = getTimestamp()
        local Msg = {
            timeStamp = currentTime,
            reqID = reqID
        }

        -- 存储请求信息用于跟踪
        pendingRequests[reqID] = {
            playerID = playerID,
            sendTime = currentTime,
            timeoutCallback = timeoutCallback,
            responseCallback = responseCallback
        }

        System:SendToClient(playerID, UDK_Heartbeat.NetMsg.Server, Msg)

        -- 更新统计数据
        heartbeatStats.totalSent = heartbeatStats.totalSent + 1
        if not heartbeatStats.playerStats[playerID] then
            heartbeatStats.playerStats[playerID] = {
                sent = 1,
                received = 0,
                timeout = 0,
                lastSeen = 0,
                avgResponseTime = 0,
                responseHistory = {}
            }
        else
            heartbeatStats.playerStats[playerID].sent = heartbeatStats.playerStats[playerID].sent + 1
        end

        if UDK_Heartbeat.Config.DebugPrint then
            Log:PrintLog(createFormatLog(string.format("向玩家 %d 发送带跟踪的心跳包请求，请求ID: %s (时间: %d)",
                playerID, reqID, currentTime)))
        end
    end
end

---|📘- 注册心跳包回调函数
---
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-heartbeat/#udkheartbeatonheartbeat)
---@param callback function 心跳包回调函数
---@return string callbackId 回调函数ID
function UDK_Heartbeat.RegisterCallback(callback)
    if type(callback) == "function" then
        local callbackId = nanoIDGenerate(8)
        callbacks[callbackId] = callback
        Log:PrintLog(createFormatLog(string.format("注册心跳包回调函数，ID: %s", callbackId)))
        return callbackId
    else
        Log:PrintWarning(createFormatLog("注册的回调函数无效"))
        return nil
    end
end

---|📘- 注销心跳包回调函数
---
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/api/udk-heartbeat/#udkheartbeatoffheartbeat)
---@param callbackId string 回调函数ID
function UDK_Heartbeat.UnRegisterCallback(callbackId)
    if callbacks[callbackId] then
        callbacks[callbackId] = nil
        Log:PrintLog(createFormatLog(string.format("注销心跳包回调函数，ID: %s", callbackId)))
    else
        Log:PrintWarning(createFormatLog(string.format("未找到ID为 %s 的回调函数", callbackId)))
    end
end

---|📘- 获取玩家心跳状态
---
---| `范围`：`服务端`
---
---| `说明`：`获取指定玩家的心跳状态信息`
---@param playerID number 玩家ID
---@return table 玩家心跳状态信息 {sent=发送次数, received=接收次数, timeout=超时次数, lastSeen=最后响应时间戳, avgResponseTime=平均响应时间(毫秒), health=连接健康度(0-100)}
function UDK_Heartbeat.GetPlayerStatus(playerID)
    local envInfo = envCheck()
    if envInfo.envID ~= UDK_Heartbeat.Config.EnvType.Server.ID and not envInfo.isStandalone then
        Log:PrintWarning(createFormatLog("只有服务端可以获取玩家心跳状态"))
        return nil
    end

    if not playerID or type(playerID) ~= "number" then
        Log:PrintWarning(createFormatLog("无效的玩家ID"))
        return nil
    end

    local stats = heartbeatStats.playerStats[playerID]
    if not stats then
        return {
            sent = 0,
            received = 0,
            timeout = 0,
            lastSeen = 0,
            avgResponseTime = 0,
            health = 0
        }
    end

    -- 计算连接健康度 (0-100)
    local health = 100
    if stats.sent > 0 then
        -- 基于成功率和响应时间计算健康度
        local successRate = stats.received / stats.sent
        health = math.floor(successRate * 100)

        -- 如果平均响应时间过长，降低健康度
        if stats.avgResponseTime > 500 then -- 500ms以上开始降低健康度
            local responseTimePenalty = math.min(30, math.floor((stats.avgResponseTime - 500) / 100))
            health = math.max(0, health - responseTimePenalty)
        end
    end

    return {
        sent = stats.sent,
        received = stats.received,
        timeout = stats.timeout,
        lastSeen = stats.lastSeen,
        avgResponseTime = stats.avgResponseTime,
        health = health
    }
end

---|📘- 获取心跳统计信息
---
---| `范围`：`服务端`
---
---| `说明`：`获取心跳包系统的统计信息`
---@return table 心跳统计信息 {totalSent=总发送次数, totalReceived=总接收次数, totalTimeout=总超时次数, uptime=运行时间(毫秒), playerCount=监控玩家数量}
function UDK_Heartbeat.GetStats()
    local envInfo = envCheck()
    if envInfo.envID ~= UDK_Heartbeat.Config.EnvType.Server.ID and not envInfo.isStandalone then
        Log:PrintWarning(createFormatLog("只有服务端可以获取心跳统计信息"))
        return nil
    end

    local currentTime = getTimestamp()
    local playerCount = 0
    for _ in pairs(heartbeatStats.playerStats) do
        playerCount = playerCount + 1
    end

    return {
        totalSent = heartbeatStats.totalSent,
        totalReceived = heartbeatStats.totalReceived,
        totalTimeout = heartbeatStats.totalTimeout,
        uptime = currentTime - heartbeatStats.startTime,
        playerCount = playerCount
    }
end

---|📘- 重置心跳统计信息
---
---| `范围`：`服务端`
---
---| `说明`：`重置心跳包系统的统计信息`
---@param resetPlayerStats boolean? 是否同时重置玩家统计信息(默认: false)
function UDK_Heartbeat.ResetStats(resetPlayerStats)
    local envInfo = envCheck()
    if envInfo.envID ~= UDK_Heartbeat.Config.EnvType.Server.ID and not envInfo.isStandalone then
        Log:PrintWarning(createFormatLog("只有服务端可以重置心跳统计信息"))
        return
    end

    heartbeatStats.totalSent = 0
    heartbeatStats.totalReceived = 0
    heartbeatStats.totalTimeout = 0
    heartbeatStats.resetTime = getTimestamp()

    if resetPlayerStats then
        heartbeatStats.playerStats = {}
        Log:PrintLog(createFormatLog("心跳统计信息和玩家统计数据已重置"))
    else
        Log:PrintLog(createFormatLog("心跳统计信息已重置"))
    end
end

-- 调用游戏运行事件，进行注册网络消息通知
System:RegisterEvent(Events.ON_BEGIN_PLAY, heartbeatInit)

return UDK_Heartbeat
