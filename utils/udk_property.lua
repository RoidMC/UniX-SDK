-- ==================================================
-- * UniX SDK - Property Module (C/S Sync)
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

local UDK_Property = {}

---数据类型枚举
---@enum UDK_Property.TYPE
UDK_Property.TYPE = {
    Boolean = "Boolean",           -- 布尔值
    Number = "Number",             -- 数值
    String = "String",             -- 字符串
    Array = "Array",               -- 数组
    Vector3 = "Vector3",           -- 向量
    Player = "Player",             -- 玩家
    Character = "Character",       -- 角色
    Element = "Element",           -- 元件
    Prefab = "Prefab",             -- 模组
    Prop = "Prop",                 -- 道具
    LogicElement = "LogicElement", -- 逻辑元件
    MotionUnit = "MotionUnit",     -- 运动单元
    Timer = "Timer",               -- 计时器
    Task = "Task",                 --任务
    Effect = "Effect",             -- 特效
    SignalBox = "SignalBox",       -- 触发盒
    Audio = "Audio",               -- 音效
    Creature = "Creature",         -- 生物
    UIWidget = "Widget",           -- UI控件
    Scene = "Scene",               -- 场景
    Item = "Item",                 -- 物品
    Color = "Color",               -- 颜色
    Map = "Map",                   -- 关联数组
    Any = "Any"                    -- 任意类型
}

UDK_Property.NetMsg = {
    ServerSync = 20000,
    ClientSync = 20001,
    ServerSendAuthorityData = 20002,
    ClientQueryAuthorityData = 20003,
    ServerAuthoritySync = 20010,
}

UDK_Property.SyncConf = {
    RequestLifetime = 15000, -- 请求超时时间
    Type = {
        ServerSync = "ServerSyncEvent",
        ClientSync = "ClientSyncEvent",
        ClientQueryAuthorityData = "ClientQueryAuthorityData",
        ServerAuthoritySync = "ServerAuthoritySync"
    },
    CRUD = {
        Create = "Create",
        SetBatch = "SetBatch",
        Update = "Update",
        Delete = "Delete",
        Clear = "Clear",
        Get = "Get",
        ForceSync = "ForceSync"
    },
    Status = {
        StandaloneDebug = false, --编辑器和单机环境Debug测试使用
        DebugPrint      = false   --调试打印
    }
}

-- 辅助函数：检查是否为数组（连续的数字键从1开始）
local function isArray(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    for i = 1, count do
        if t[i] == nil then return false end
    end
    return true
end

-- 辅助函数：检查数组元素类型
local function checkArrayElements(arr, elementTypeChecker)
    if not isArray(arr) then return false end
    for _, v in ipairs(arr) do
        if not elementTypeChecker(v) then return false end
    end
    return true
end

-- 类型验证规则
local TYPE_VALIDATORS = {
    Boolean = function(value)
        if type(value) == "boolean" then
            return true
        end

        -- 处理数值类型的布尔值（0/1）
        if type(value) == "number" and (value == 0 or value == 1) then
            return true
        end

        -- 处理字符串类型的布尔值（"true"/"false"）
        if type(value) == "string" then
            local lower = value:lower()
            return lower == "true" or lower == "false" or lower == "0" or lower == "1"
        end

        -- 处理数组形式的布尔值
        if isArray(value) then
            return checkArrayElements(value, function(v)
                return type(v) == "boolean" or
                    (type(v) == "number" and (v == 0 or v == 1)) or
                    (type(v) == "string" and (v:lower() == "true" or v:lower() == "false" or v == "0" or v == "1"))
            end)
        end

        return false
    end,

    Number = function(value)
        return type(value) == "number" or
            (isArray(value) and checkArrayElements(value, function(v) return type(v) == "number" end))
    end,

    String = function(value)
        return type(value) == "string" or
            (isArray(value) and checkArrayElements(value, function(v) return type(v) == "string" end))
    end,

    Array = function(value)
        return isArray(value)
    end,

    Vector3 = function(value)
        local function isVector3(v)
            return type(v) == "table"
                and type(v.X) == "number"
                and type(v.Y) == "number"
                and type(v.Z) == "number"
        end
        return isVector3(value) or
            (isArray(value) and checkArrayElements(value, isVector3))
    end,

    Color = function(value)
        local function isValidColor(v)
            if type(v) ~= "string" then return false end

            -- 移除可能的空白字符
            v = string.gsub(v, "%s", "")

            -- 检查长度（#RRGGBB 或 #RRGGBBAA）
            if #v ~= 7 and #v ~= 9 then return false end

            -- 检查#前缀
            if string.sub(v, 1, 1) ~= "#" then return false end

            -- 检查其余字符是否都是有效的十六进制数字
            local hex = string.sub(v, 2)
            for i = 1, #hex do
                local c = string.sub(hex, i, i)
                if not string.match(c, "[0-9A-Fa-f]") then
                    return false
                end
            end

            return true
        end

        return isValidColor(value) or
            (isArray(value) and checkArrayElements(value, isValidColor))
    end,

    -- 对于复杂类型，支持表、字符串（ID引用）或它们的数组
    Player = function(value)
        local function isValidPlayer(v)
            return type(v) == "table" or type(v) == "string"
        end
        return isValidPlayer(value) or
            (isArray(value) and checkArrayElements(value, isValidPlayer))
    end,
}

-- 为其他复杂类型复制Player验证器的行为
local complexTypes = {
    "Character", "Element", "Prefab", "Prop", "LogicElement",
    "MotionUnit", "Timer", "Task", "Effect", "SignalBox",
    "Audio", "Creature", "UIWidget", "Scene", "Item"
}

for _, typeName in ipairs(complexTypes) do
    TYPE_VALIDATORS[typeName] = TYPE_VALIDATORS.Player
end

-- Map关联数组验证
TYPE_VALIDATORS.Map = function(value)
    return type(value) == "table"
end

-- Any类型验证器
TYPE_VALIDATORS.Any = function(value)
    -- 确保至少是有效的Lua值
    return value ~= nil
end

-- 辅助函数：规范化对象标识符
local function normalizeObjectId(object)
    if object == nil then
        return nil, "对象标识符不能为nil"
    end

    -- 如果是数字，转换为字符串
    if type(object) == "number" then
        return tostring(object)
    end

    -- 如果是字符串，直接返回
    if type(object) == "string" then
        return object
    end

    -- 如果是表，尝试获取id属性
    if type(object) == "table" and object.id then
        return tostring(object.id)
    end

    -- 其他情况，尝试转换为字符串
    local converted = tostring(object)
    if converted == nil then
        return nil, "无法将对象转换为有效的标识符"
    end

    return converted
end

-- 内部数据存储
local dataStore = {
    -- 主数据存储 {object -> {propertyType -> {propertyName -> value}}}
    data = {},
    -- 统计信息
    stats = {
        totalCount = 0,
        typeCount = {},
    }
}

-- 获取当前时间戳
local function getTimestamp()
    -- Lua2.0用不了os.time()
    -- 换成Lua2.0提供的接口生成需要的时间戳
    local serverTime = MiscService:GetServerTimeToTime()
    local timeStamp = MiscService:DateYMDHMSToTime(serverTime) --1702594800
    return math.floor(timeStamp * 1000)
end

-- 获取当前环境（返回值仅用于IF判断）
local function getSystemEnv(type)
    if type == "server" then
        if UDK_Property.SyncConf.Status.StandaloneDebug then
            return System:IsServer()
        else
            return System:IsServer() and not System:IsStandalone()
        end
    elseif type == "client" then
        if UDK_Property.SyncConf.Status.StandaloneDebug then
            return System:IsClient()
        else
            return System:IsClient() and not System:IsStandalone()
        end
    else
        return nil
    end
end

---|📘- 生成NanoID
--- @param size number? ID长度，默认21
--- @return string
local function nanoIDGenerate(size)
    math.randomseed(getTimestamp()) -- 初始化随机种子
    size = size or 21
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    local id = ""
    for _ = 1, size do
        local idx = math.random(1, #chars)
        id = id .. chars:sub(idx, idx)
    end
    return id
end

--  网络请求有效期
local function networkValidRequest(requestTime)
    local currentTime = getTimestamp()
    if currentTime - requestTime > UDK_Property.SyncConf.RequestLifetime then
        return false, "请求已过期"
    else
        return true, "请求有效"
    end
end

--  网络同步事件处理
local function networkSyncEventHandle(reqMsg)
    if reqMsg ~= nil then
        local event = reqMsg.event
        local syncReq = reqMsg.dataSyncReq
        local crud = UDK_Property.SyncConf.CRUD
        -- 创建/更新
        if syncReq.reqType == crud.Create or syncReq.reqType == crud.Update then
            --Log:PrintTable(reqMsg)
            UDK_Property.SetProperty(syncReq.object, syncReq.type, syncReq.name, syncReq.data, true)
            print(string.format("已接收并应用服务器权威数据，共 %d 个属性，名称 %s", dataStore.stats.totalCount, tostring(syncReq.name)))
        end
        -- 常规删除
        if syncReq.reqType == crud.Delete then
            UDK_Property.DeleteProperty(syncReq.object, syncReq.type, syncReq.name, true)
        end
        -- 清除
        if syncReq.reqType == crud.Clear then
            UDK_Property.ClearProperty(syncReq.object, syncReq.type, true)
        end
        -- 批量设置
        if syncReq.reqType == crud.SetBatch then
            UDK_Property.SetBatchProperties(syncReq.object, syncReq.data, true)
        end
        -- 强制更新
        if syncReq.reqType == crud.ForceSync then
            if syncReq.data and syncReq.data.data then
                -- 完全替换本地数据存储
                dataStore = syncReq.data
                print(string.format("已接收并应用服务器权威数据，共 %d 个属性", dataStore.stats.totalCount))
            elseif syncReq.object and syncReq.type and syncReq.name then
                -- 单个属性强制更新
                UDK_Property.SetProperty(syncReq.object, syncReq.type, syncReq.name, syncReq.data, true)
            end
        end
    end
end

-- 创建通用消息构建函数
local function buildSyncMessage(MsgId, eventType, reqType, object, type, name, data)
    return {
        event = {
            id = MsgId,
            type = eventType,
            reqID = nanoIDGenerate(),
            reqTimestamp = getTimestamp(),
            isStandalone = System:IsStandalone(),
            isServer = System:IsServer(),
            isClient = System:IsClient()
        },
        dataSyncReq = {
            reqType = reqType,
            object = object,
            type = type,
            name = name,
            data = data
        }
    }
end

-- 网络同步数据
local function networkSyncSend(reqType, object, type, name, data)
    local isServer = getSystemEnv("server")
    local isClient = getSystemEnv("client")

    if isServer then
        local Msg = buildSyncMessage(
            UDK_Property.NetMsg.ServerSync,
            UDK_Property.SyncConf.Type.ServerSync,
            reqType, object, type, name, data
        )
        System:SendToAllClients(Msg.event.id, Msg)
    end

    if isClient then
        local Msg = buildSyncMessage(
            UDK_Property.NetMsg.ClientSync,
            UDK_Property.SyncConf.Type.ClientSync,
            reqType, object, type, name, data
        )
        System:SendToServer(Msg.event.id, Msg)
    end
end

-- 发送服务器权威数据（适用于断线重连等极端情况导致Client数据不同步的情况）
-- 该接口很危险，请谨慎使用，应该在确定客户端和服务器存在数据不同步的情况下使用
-- 该接口仅允许服务器调用，客户端调用无效
local function networkSyncAuthorityData(playerID, object, type, name, data)
    local isServer = getSystemEnv("server")
    local isClient = getSystemEnv("client")
    if isServer then
        local MsgId = UDK_Property.NetMsg.ServerAuthoritySync
        local EventType = UDK_Property.SyncConf.Type.ServerAuthoritySync
        local reqType = UDK_Property.SyncConf.CRUD.ForceSync
        local Msg = {
            event = {
                id = MsgId,
                type = EventType,
                reqID = nanoIDGenerate(),
                reqTimestamp = getTimestamp(),
                isStandalone = System:IsStandalone(),
                isServer = System:IsServer(),
                isClient = System:IsClient()
            },
            dataSyncReq = {
                reqType = reqType,
                data = dataStore
            }
        }
        if playerID ~= nil then
            System:SendToClient(playerID, MsgId, Msg)
            print(string.format("向玩家%s发送了同步请求: %s (%s, %s)", playerID, Msg.event.reqID, Msg.event.reqTimestamp,
                Msg.dataSyncReq.reqType))
        else
            System:SendToAllClients(MsgId, Msg)
            print(string.format("向所有客户端发送了同步请求: %s (%s, %s)", Msg.event.reqID, Msg.event.reqTimestamp,
                Msg.dataSyncReq.reqType))
        end
    end

    if isClient then
        print("[UDK:Property] NetworkAuthoritySync: 客户端无法调用该接口，请更换服务器调用")
    end
end

local function networkQueryAuthorityData()
    local isClient = getSystemEnv("client")
    if isClient then
        local MsgId = UDK_Property.NetMsg.ClientQueryAuthorityData
        local EventType = UDK_Property.SyncConf.Type.ClientQueryAuthorityData
        local Msg = {
            event = {
                id = MsgId,
                type = EventType,
                reqID = nanoIDGenerate(),
                reqTimestamp = getTimestamp(),
                isStandalone = System:IsStandalone(),
                isServer = System:IsServer(),
                isClient = System:IsClient()
            },
            dataSyncReq = {
                reqType = reqType,
                object = object,
                type = type,
                name = name,
                data = data
            }
        }
        System:SendToServer(MsgId, Msg)
    end
end

local function clientDataCache()
    -- body
end

local function createMessageHandler(source)
    return function(msgId, msg, playerId)
        -- 检查请求有效性
        local reqValid, errorMsg = networkValidRequest(msg.event.reqTimestamp)
        local text

        -- 处理单机/编辑器模式
        if msg.event.isServer then
            text = "Client"
            if UDK_Property.SyncConf.Status.DebugPrint then
                print(string.format("[%s] 收到了来自%s的同步请求: %s (%s, %s)", text, source, msg.event.reqID, msg.event
                    .reqTimestamp,
                    msg.dataSyncReq.reqType))
            end
        end
        if msg.event.isClient then
            text = "Server"
            if UDK_Property.SyncConf.Status.DebugPrint then
                print(string.format("[%s] 收到了来自%s的同步请求: %s (%s, %s)", text, source, msg.event.reqID, msg.event
                    .reqTimestamp,
                    msg.dataSyncReq.reqType))
                print(msg.dataSyncReq.object, msg.dataSyncReq.type, msg.dataSyncReq.name, tostring(msg.dataSyncReq.data))
            end
        end
        if msg.event.isStandalone and UDK_Property.SyncConf.Status.StandaloneDebug then
            text = "Standalone Debug"
            if UDK_Property.SyncConf.Status.DebugPrint then
                print(string.format("[%s] 收到了来自%s的同步请求: %s (%s, %s)", text, source, msg.event.reqID, msg.event
                    .reqTimestamp,
                    msg.dataSyncReq.reqType))
            end
        end

        -- 处理请求
        if reqValid then
            networkSyncEventHandle(msg)
        else
            print(string.format("收到来自%s的请求，但请求已过期: %s (%s, %s)", text, msg.event.reqID, msg.event.reqTimestamp,
                msg.dataSyncReq.reqType))
        end
    end
end

local function networkBindNotifyInit()
    if System:IsServer() then
        System:BindNotify(UDK_Property.NetMsg.ClientSync, createMessageHandler("Client"))
        System:BindNotify(UDK_Property.NetMsg.ClientQueryAuthorityData, createMessageHandler("Client"))
    end

    if System:IsClient() then
        System:BindNotify(UDK_Property.NetMsg.ServerSync, createMessageHandler("Server"))
        System:BindNotify(UDK_Property.NetMsg.ServerAuthoritySync, createMessageHandler("Server"))
    end
end

-- 调用游戏运行事件，进行注册网络消息通知
System:RegisterEvent(Events.ON_BEGIN_PLAY, networkBindNotifyInit)

-- 调试函数：打印验证结果
local function debugValidateColor(value)
    print(string.format("调试Color验证: 值=%s, 类型=%s",
        tostring(value), type(value)))

    if type(value) ~= "string" then
        print("  失败: 不是字符串类型")
        return false
    end

    -- 移除空白字符
    local cleanValue = string.gsub(value, "%s", "")
    print(string.format("清理后的值: %s", cleanValue))

    -- 检查长度
    if #cleanValue ~= 7 and #cleanValue ~= 9 then
        print(string.format("失败: 长度无效 (长度=%d, 应为7或9)", #cleanValue))
        return false
    end

    -- 检查#前缀
    if string.sub(cleanValue, 1, 1) ~= "#" then
        print("失败: 缺少#前缀")
        return false
    end

    -- 检查十六进制字符
    local hex = string.sub(cleanValue, 2)
    for i = 1, #hex do
        local c = string.sub(hex, i, i)
        if not string.match(c, "[0-9A-Fa-f]") then
            print(string.format("失败: 无效的十六进制字符 '%s' 在位置 %d", c, i + 1))
            return false
        end
    end

    print("  验证通过")
    return true
end

-- 验证属性值类型
---@param object string 对象标识符
---@param propertyType string 属性类型
---@param value any 属性值
---@return boolean isValid 是否有效
---@return string? error 错误信息
local function validatePropertyValue(object, propertyType, value)
    -- 检查类型是否存在
    if not UDK_Property.TYPE[propertyType] then
        local errorMsg = string.format("不支持的属性类型: %s", propertyType)
        print(string.format("[UDK:Property][Validate] Error: %s | Timestamp: %d", errorMsg, getTimestamp()))
        return false, errorMsg
    end

    -- 检查值是否为nil
    if value == nil then
        local errorMsg = "属性值不能为nil"
        print(string.format("[UDK:Property][Validate] Error: %s | Object: %s | Type: %s | Timestamp: %d",
            errorMsg, tostring(object), propertyType, getTimestamp()))
        return false, errorMsg
    end

    -- 特殊处理Color类型进行调试
    if propertyType == "Color" and type(value) == "string" then
        local isValid = debugValidateColor(value)
        if not isValid then
            return false, string.format(
                "[UDK:Property] Color值无效: %s",
                value
            )
        end
        return true
    end

    -- 获取类型验证器
    local validator = TYPE_VALIDATORS[propertyType]
    if not validator then
        return false, string.format("[UDK:Property] 找不到类型验证器: %s", propertyType)
    end

    -- 执行验证
    if not validator(value) then
        return false, string.format(
            "[UDK:Property] 属性值类型无效: 期望 %s，实际为 %s",
            propertyType,
            type(value)
        )
    end

    return true
end

---| - 📘 添加属性数据
---<br>
---| 支持类型 (默认数组支持仅支持连续数组，关联数组请使用Map类型)
---<br>
---| `Boolean` | `Number` | `String` | `Vector3` | `Player` | `Character` |`Element` | `Prefab` | `Prop` | `LogicElement`
---<br>
---| `MotionUnit` | `Timer` | `Task` | `Effects` | `SignalBox` | `Audio` |  `Creature` | `UIWidget` | `Scene` | `Item` | `Color`
---<br>
---| `Array` | `Map` | `Any` (如果你想YOLO，那么你可以使用这个类型，出问题概不负责)
---@param object string 对象标识符
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@param data any 属性值
---@param isBypassSync boolean? 是否跳过同步（可选，添加则只在本地有效，不进行同步）
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.SetProperty(object, propertyType, propertyName, data, isBypassSync)
    local normalizedId, error = normalizeObjectId(object)
    if not normalizedId then
        return false, error
    end

    if not propertyType then
        return false, "属性类型不能为nil"
    end

    if not propertyName then
        return false, "属性名称不能为nil"
    end

    if data == nil then
        return false, "属性值不能为nil"
    end

    -- 验证属性值类型
    local isValid, error = validatePropertyValue(normalizedId, propertyType, data)
    if not isValid then
        return false, string.format("属性值验证失败: %s", error)
    end

    -- 初始化多级存储结构
    dataStore.data[normalizedId] = dataStore.data[normalizedId] or {}
    dataStore.data[normalizedId][propertyType] = dataStore.data[normalizedId][propertyType] or {}

    -- 检查是否是新属性
    local isNewProperty = dataStore.data[normalizedId][propertyType][propertyName] == nil

    -- 存储数据
    dataStore.data[normalizedId][propertyType][propertyName] = data

    -- 更新统计信息（仅对新属性）
    if isNewProperty then
        dataStore.stats.totalCount = dataStore.stats.totalCount + 1
        dataStore.stats.typeCount[propertyType] = (dataStore.stats.typeCount[propertyType] or 0) + 1
    end

    -- 如果不加true或置空则触发同步（用于确保单元测试也能正常工作）
    if not isBypassSync then
        local crudType = isNewProperty and "Create" or "Update"
        if isNewProperty then
            --print("创建数据" .. object .. " " .. propertyName, tostring(data))
            --print(crudType)
        elseif not isNewProperty then
            --print("更新数据" .. object .. " " .. propertyName, tostring(data))
            --print(crudType)
        end
        networkSyncSend(crudType, object, propertyType, propertyName, data)
    end

    return true
end

---| - 📘 获取属性数据
---@param object string|number|table 对象标识符或对象实例
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@return any? value 属性值
---@return string? error 错误信息
function UDK_Property.GetProperty(object, propertyType, propertyName)
    local normalizedId, error = normalizeObjectId(object)
    if not normalizedId then
        return nil, error
    end

    if not propertyType then
        return nil, "属性类型不能为nil"
    end

    if not propertyName then
        return nil, "属性名称不能为nil"
    end

    -- 检查数据是否存在
    if dataStore.data[normalizedId] == nil or
        dataStore.data[normalizedId][propertyType] == nil or
        dataStore.data[normalizedId][propertyType][propertyName] == nil then
        --print("属性不存在"..normalizedId.." "..propertyType.." "..propertyName)
        return nil, "属性不存在"
    end

    -- 直接返回值，包括 false
    return dataStore.data[normalizedId][propertyType][propertyName]
end

---| - 📘 删除对象已有的自定义属性数据
---@param object string|number|table 对象标识符或对象实例
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@param isBypassSync boolean? 是否跳过同步（可选，添加则只在本地有效，不进行同步）
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.DeleteProperty(object, propertyType, propertyName, isBypassSync)
    local normalizedId, error = normalizeObjectId(object)
    if not normalizedId then
        print(string.format("[UDK:Property][Delete] NormalizeID失败: %s | Object: %s | Timestamp: %d",
            error, tostring(object), getTimestamp()))
        return false, error
    end

    if not propertyType then
        local errorMsg = "属性类型不能为nil"
        print(string.format("[UDK:Property][Delete] %s | Object: %s | Property: %s | Timestamp: %d",
            errorMsg, normalizedId, propertyName, getTimestamp()))
        return false, errorMsg
    end

    if not propertyName then
        local errorMsg = "属性名称不能为nil"
        print(string.format("[UDK:Property][Delete] %s | Object: %s | Property: %s | Timestamp: %d",
            errorMsg, normalizedId, propertyName, getTimestamp()))
        return false, errorMsg
    end

    -- 检查数据是否存在
    if not dataStore.data[normalizedId] or
        not dataStore.data[normalizedId][propertyType] or
        not dataStore.data[normalizedId][propertyType][propertyName] then
        return false, "属性不存在"
    end

    -- 更新统计信息
    dataStore.stats.totalCount = dataStore.stats.totalCount - 1
    dataStore.stats.typeCount[propertyType] = dataStore.stats.typeCount[propertyType] - 1

    -- 删除属性
    dataStore.data[normalizedId][propertyType][propertyName] = nil

    -- 清理空表
    if next(dataStore.data[normalizedId][propertyType]) == nil then
        dataStore.data[normalizedId][propertyType] = nil
        if next(dataStore.data[normalizedId]) == nil then
            dataStore.data[normalizedId] = nil
        end
    end

    -- 如果不加true或置空则触发同步（用于确保单元测试也能正常工作）
    if not isBypassSync then
        local crudType = UDK_Property.SyncConf.CRUD.Delete
        networkSyncSend(crudType, object, propertyType, propertyName)
    end

    return true
end

---| - 📘 删除对象所有的自定义属性数据
---@param object string|number|table 对象标识符或对象实例
---@param propertyType string? 属性类型（可选，如果不指定则删除所有类型）
---@param isBypassSync boolean? 是否跳过同步（可选，添加则只在本地有效，不进行同步）
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.ClearProperty(object, propertyType, isBypassSync)
    local normalizedId, error = normalizeObjectId(object)
    if not normalizedId then
        return false, error
    end

    if not dataStore.data[normalizedId] then
        return false, "对象不存在"
    end

    if propertyType then
        -- 删除指定类型的所有属性
        if dataStore.data[normalizedId][propertyType] then
            local count = 0
            for _ in pairs(dataStore.data[normalizedId][propertyType]) do
                count = count + 1
            end
            dataStore.stats.totalCount = dataStore.stats.totalCount - count
            dataStore.stats.typeCount[propertyType] = (dataStore.stats.typeCount[propertyType] or 0) - count
            dataStore.data[normalizedId][propertyType] = nil

            -- 如果对象没有其他属性类型，清理对象
            if next(dataStore.data[normalizedId]) == nil then
                dataStore.data[normalizedId] = nil
            end
        end
    else
        -- 删除所有类型的属性
        for pType, properties in pairs(dataStore.data[normalizedId]) do
            local count = 0
            for _ in pairs(properties) do
                count = count + 1
            end
            dataStore.stats.totalCount = dataStore.stats.totalCount - count
            dataStore.stats.typeCount[pType] = (dataStore.stats.typeCount[pType] or 0) - count
        end
        dataStore.data[normalizedId] = nil
    end

    -- 如果不加true或置空则触发同步（用于确保单元测试也能正常工作）
    if not isBypassSync then
        local crudType = UDK_Property.SyncConf.CRUD.Clear
        networkSyncSend(crudType, object, propertyType)
    end

    return true
end

---| - 📘 检查属性是否存在
---@param object string|number|table 对象标识符或对象实例
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@return boolean exists 是否存在
function UDK_Property.CheckPropertyHasExist(object, propertyType, propertyName)
    local normalizedId = normalizeObjectId(object)
    if not normalizedId or not propertyType or not propertyName then
        return false
    end

    return dataStore.data[normalizedId] ~= nil and
        dataStore.data[normalizedId][propertyType] ~= nil and
        dataStore.data[normalizedId][propertyType][propertyName] ~= nil
end

---| - 📘 获取对象的所有属性
---@param object string|number|table 对象标识符或对象实例
---@return table<string, table<string, any>>? properties 属性表 {propertyType = {propertyName = value}}
---@return string? error 错误信息
function UDK_Property.GetAllProperties(object)
    local normalizedId, error = normalizeObjectId(object)
    if not normalizedId then
        return nil, error
    end

    if not dataStore.data[normalizedId] then
        return {}, "对象没有任何属性"
    end

    -- 创建一个新表来存储结果，避免直接返回内部数据引用
    local result = {}
    for propertyType, properties in pairs(dataStore.data[normalizedId]) do
        result[propertyType] = {}
        for propertyName, value in pairs(properties) do
            result[propertyType][propertyName] = value
        end
    end

    return result
end

---| - 📘 获取对象特定类型的所有属性
---@param object string|number|table 对象标识符或对象实例
---@param propertyType string 属性类型
---@return table<string, any>? properties 属性表 {propertyName = value}
---@return string? error 错误信息
function UDK_Property.GetPropertiesByType(object, propertyType)
    local normalizedId, error = normalizeObjectId(object)
    if not normalizedId then
        return nil, error
    end

    if not propertyType then
        return nil, "属性类型不能为nil"
    end

    if not dataStore.data[normalizedId] or not dataStore.data[normalizedId][propertyType] then
        return {}, "对象没有该类型的属性"
    end

    -- 创建一个新表来存储结果，避免直接返回内部数据引用
    local result = {}
    for propertyName, value in pairs(dataStore.data[normalizedId][propertyType]) do
        result[propertyName] = value
    end

    return result
end

---| - 📘 打印属性系统的调试信息
---@param object string? 对象标识符（可选，如果不指定则打印所有信息）
function UDK_Property.PrintDebugInfo(object)
    print("=== UDK_Property Debug Info ===")
    print(string.format("Total properties: %d", dataStore.stats.totalCount))

    -- 打印类型统计
    print("\nProperty type statistics:")
    for propertyType, count in pairs(dataStore.stats.typeCount) do
        print(string.format("  %s: %d", propertyType, count))
    end

    -- 如果指定了对象，打印该对象的详细信息
    if object then
        print(string.format("\nObject details for: %s", object))
        if dataStore.data[object] then
            for propertyType, properties in pairs(dataStore.data[object]) do
                print(string.format("  %s:", propertyType))
                for propertyName, value in pairs(properties) do
                    print(string.format("    %s = %s", propertyName, tostring(value)))
                end
            end
        else
            print("  No properties found")
        end
    end

    print("===========================")
end

---| - 📘 批量设置属性数据
---@param object string|number|table 对象标识符或对象实例
---@param properties table<string, table<string, any>> 属性表 {propertyType = {propertyName = value}}
---@param isBypassSync boolean? 是否跳过同步（可选，添加则只在本地有效，不进行同步）
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.SetBatchProperties(object, properties, isBypassSync)
    local normalizedId, error = normalizeObjectId(object)
    if not normalizedId then
        return false, error
    end

    if not properties or type(properties) ~= "table" then
        return false, "属性表不能为nil且必须是table类型"
    end

    -- 先验证所有属性
    for propertyType, props in pairs(properties) do
        if type(props) ~= "table" then
            return false, string.format("属性类型 %s 的值必须是table类型", propertyType)
        end

        for propertyName, value in pairs(props) do
            local isValid, error = validatePropertyValue(normalizedId, propertyType, value)
            if not isValid then
                return false, string.format("属性验证失败 [%s.%s]: %s", propertyType, propertyName, error)
            end
        end
    end

    -- 所有属性验证通过后，开始设置
    for propertyType, props in pairs(properties) do
        for propertyName, value in pairs(props) do
            local success, error = UDK_Property.SetProperty(object, propertyType, propertyName, value)
            if not success then
                return false, string.format("设置属性失败 [%s.%s]: %s", propertyType, propertyName, error)
            end
        end
    end

    -- 如果不加true或置空则触发同步（用于确保单元测试也能正常工作）
    if not isBypassSync then
        local crudType = UDK_Property.SyncConf.CRUD.SetBatch
        networkSyncSend(crudType, object, "", "", properties)
    end

    return true
end

---| - 📘 获取所有支持的属性类型
---@return table<string, string> types 类型列表及其描述
function UDK_Property.GetSupportedTypes()
    return {
        Boolean = "布尔值，支持单个值或布尔值数组",
        Number = "数值，支持单个值或数值数组",
        String = "字符串，支持单个值或字符串数组",
        Array = "数组类型，支持任意类型的数组",
        Vector3 = "三维向量，支持单个值或向量数组",
        Player = "玩家对象或ID，支持单个值或数组",
        Character = "角色对象或ID，支持单个值或数组",
        Element = "元件对象或ID，支持单个值或数组",
        Prefab = "预制体对象或ID，支持单个值或数组",
        Prop = "道具对象或ID，支持单个值或数组",
        LogicElement = "逻辑元件对象或ID，支持单个值或数组",
        MotionUnit = "运动单元对象或ID，支持单个值或数组",
        Timer = "计时器对象或ID，支持单个值或数组",
        Task = "任务对象或ID，支持单个值或数组",
        Effect = "特效对象或ID，支持单个值或数组",
        SignalBox = "触发盒对象或ID，支持单个值或数组",
        Audio = "音效对象或ID，支持单个值或数组",
        Creature = "生物对象或ID，支持单个值或数组",
        UIWidget = "UI控件对象或ID，支持单个值或数组",
        Scene = "场景对象或ID，支持单个值或数组",
        Item = "物品对象或ID，支持单个值或数组",
        Color = "颜色值（#RRGGBB或#AARRGGBB格式），支持单个值或数组",
        Any = "任意有效的Lua值"
    }
end

---| - 📘 检查值是否为数组类型
---@param value any 要检查的值
---@param elementType? string 元素类型（可选）
---@return boolean isArray 是否为数组
---@return string? error 错误信息
function UDK_Property.IsArray(value, elementType)
    if not isArray(value) then
        return false, "不是有效的数组"
    end

    if elementType then
        local validator = TYPE_VALIDATORS[elementType]
        if not validator then
            return false, string.format("不支持的元素类型: %s", elementType)
        end

        for i, element in ipairs(value) do
            if not validator(element) then
                return false, string.format("数组索引 %d 的元素类型无效", i)
            end
        end
    end

    return true
end

-- 辅助函数：确定值的具体类型
local function determineValueType(value)
    -- 检查基本类型
    if type(value) == "boolean" then
        return "Boolean"
    elseif type(value) == "number" then
        return "Number"
    elseif type(value) == "string" then
        -- 检查是否是颜色值
        if string.match(value, "^#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]([0-9A-Fa-f][0-9A-Fa-f])?$") then
            return "Color"
        end
        return "String"
    elseif type(value) == "table" then
        -- 检查是否是Vector3
        if type(value.X) == "number" and type(value.Y) == "number" and type(value.Z) == "number" then
            return "Vector3"
        end
        -- 检查是否是数组
        if isArray(value) then
            return "Array"
        end
    end

    -- 检查复杂类型
    for _, typeName in ipairs(complexTypes) do
        if TYPE_VALIDATORS[typeName](value) then
            return typeName
        end
    end

    return "Any"
end

---| - 📘 获取属性的类型信息
---@param object string 对象标识符
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@return table? info 类型信息 {type: string, isArray: boolean, elementType?: string}
---@return string? error 错误信息
function UDK_Property.GetPropertyTypeInfo(object, propertyType, propertyName)
    if not object or not propertyType or not propertyName then
        return nil, "参数不能为nil"
    end

    local value = UDK_Property.GetProperty(object, propertyType, propertyName)
    if not value then
        return nil, "属性不存在"
    end

    local result = {
        type = propertyType,
        isArray = isArray(value),
    }

    if result.isArray and #value > 0 then
        -- 尝试确定数组元素的类型
        local firstElement = value[1]
        result.elementType = determineValueType(firstElement)

        -- 验证所有元素是否都是相同类型
        for i = 2, #value do
            if determineValueType(value[i]) ~= result.elementType then
                result.elementType = "Any"
                break
            end
        end
    end

    return result
end

---| - 📘 获取统计数据
---@return table info  统计信息
function UDK_Property.GetStats()
    return {
        totalCount = dataStore.stats.totalCount,
        typeCount = dataStore.stats.typeCount,
    }
end

---| - 📘 同步服务器权威数据
---<br>
---| `范围`：`服务端`
---<br>
---| `该功能用于在极端情况下客户端数据不同步时，强制同步服务器权威数据`
---@param playerID number? 玩家ID（客户端ID，可选，不填默认给全部玩家同步最新数据）
---@param object string? 对象名称（可选，用于同步单个数据）
---@param propertyType string? 属性类型（可选，用于同步单个数据）
---@param propertyName string? 属性名称（可选，用于同步单个数据）
function UDK_Property.SyncAuthorityData(playerID, object, propertyType, propertyName)
    networkSyncAuthorityData(playerID, object, propertyType, propertyName)
    print("已同步服务器权威数据")
end

return UDK_Property