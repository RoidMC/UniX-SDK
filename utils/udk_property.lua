-- ==================================================
-- * UniX SDK - Property Module (C/S Sync)
-- * Version: 0.0.3 (Development)
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

--- 支持类型枚举别名
---@alias SupportType
---| 'Boolean'     # 布尔值，支持单个值或布尔值数组
---| 'Number'     # 数值，支持单个值或数值数组
---| 'String'     # 字符串，支持单个值或字符串数组
---| 'Array'      # 数组，支持单个值或数组
---| 'Vector'     # 向量值（XYZ或XYZW格式），支持单个值或向量数组
---| 'Color'      # 颜色值（#RRGGBB或#AARRGGBB格式），支持单个值或颜色数组
---| 'Map'        # 关联数组，支持单个值或关联数组
---| 'Any'        # 任意有效的Lua值

---@class UDK.Property
local UDK_Property = {}

--- 关联数组请使用Map/Any类型，其它类型数组仅支持连续数组
---@enum UDK_Property.Type
UDK_Property.Type = {
    Boolean = "Boolean", -- 布尔值，支持单个值或布尔值数组
    Number = "Number",   -- 数字值，支持单个值或数字数组
    String = "String",   -- 字符串值，支持单个值或字符串数组
    Array = "Array",     -- 数组，支持单个值或数组,
    Vector = "Vector",   -- 向量值（XYZ或XYZW格式），支持单个值或向量数组
    Color = "Color",     -- 颜色值（#RRGGBB或#AARRGGBB格式），支持单个值或颜色数组
    Map = "Map",         -- 关联数组，支持单个值或关联数组
    Any = "Any",         -- 任意有效的Lua值
}

--- ACL权控
---@enum UDK_Property.AccessLevel
UDK_Property.AccessLevel = {
    Public = "Public",      -- 公开访问
    Protected = "Protected" -- 受保护访问
}

--- ACL权控细分权限
---@enum UDK_Property.ACLOwnerShip
UDK_Property.ACLOwnerShip = {
    Isolate = "Isolate", -- 隔离
    Shared = "Shared"    -- 共享
}

--- 网络消息ID
---@enum UDK_Property.NetMsg
UDK_Property.NetMsg = {
    ServerSync = 200000,
    ClientSync = 200001,
    ServerSendAuthorityData = 200002,  --TODO
    ClientQueryAuthorityData = 200003, --TODO
    ServerAuthoritySync = 200010,
}

--- 同步配置
---@class UDK_Property.SyncConf
UDK_Property.SyncConf = {
    RequestLifetime = 15000, -- 请求超时时间
    Type = {
        ServerSync = "ServerSyncEvent",
        ClientSync = "ClientSyncEvent",
        ClientQueryAuthorityData = "ClientQueryAuthorityData", --TODO
        ServerSendAuthorityData = "ServerSendAuthorityData",   --TODO
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
        StandaloneDebug = true,    -- 编辑器和单机环境Debug测试使用
        DebugPrint      = false,   -- 调试打印
        UnitTestMode    = false,   -- 单元测试模式
        ProtocolVersion = "2.0.0", -- 协议版本
    },
    EnvType = {
        Standalone = { ID = 0, Name = "Standalone" },
        Server = { ID = 1, Name = "Server" },
        Client = { ID = 2, Name = "Client" }
    }
}

--- 内部数据存储
local dataStore = {
    -- 主数据存储 {object -> {propertyType -> {propertyName -> value}}}
    data = {},
    -- 统计信息
    stats = {
        totalCount = 0,
        typeCount = {},
    }
}

-- ==================================================
-- * UDK Property Utils Code
-- ==================================================

--- 辅助函数：检查是否为数组（连续的数字键从1开始）
local function isArray(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    for i = 1, count do
        if t[i] == nil then return false end
    end
    return true
end

--- 辅助函数：检查数组元素类型
local function checkArrayElements(arr, elementTypeChecker)
    if not isArray(arr) then return false end
    for _, v in ipairs(arr) do
        if not elementTypeChecker(v) then return false end
    end
    return true
end

---返回当前环境状态 (仅元梦Lua环境可调用)
---@return table {
---     envID: number,       -- 环境ID（Server=1, Client=2, Standalone=0）
---     envName: string,     -- 环境名称（"Server", "Client", "Standalone"）
---     isDebug: boolean,    -- 是否启用调试模式（StandaloneDebug）
---     isStandalone: boolean -- 是否为单机模式
---}
local function envCheck()
    local isStandalone = System:IsStandalone()
    local envType = isStandalone and UDK_Property.SyncConf.EnvType.Standalone or
        (System:IsServer() and UDK_Property.SyncConf.EnvType.Server or UDK_Property.SyncConf.EnvType.Client)

    return {
        envID = envType.ID,
        envName = envType.Name,
        isDebug = UDK_Property.SyncConf.Status.StandaloneDebug,
        isStandalone = isStandalone
    }
end

--- 辅助函数：类型检查
local TypeValidators = {
    Boolean = function(value)
        -- 定义一个内部函数来检查单个值是否为有效的布尔表示
        local function isValidBoolean(v)
            -- 直接布尔值
            if type(v) == "boolean" then
                return true
            end

            -- 数值类型（0/1）
            if type(v) == "number" then
                return v == 0 or v == 1
            end

            -- 字符串类型（"true"/"false"/"0"/"1"）
            if type(v) == "string" then
                local lower = v:lower()
                return lower == "true" or lower == "false" or lower == "0" or lower == "1"
            end

            return false
        end

        -- 如果是数组，检查所有元素
        if isArray(value) then
            return checkArrayElements(value, isValidBoolean)
        end

        -- 否则检查单个值
        return isValidBoolean(value)
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
    Vector = function(value)
        local function isVector(v)
            if type(v) ~= "table" then
                return false
            end

            -- 检查必需的XYZ分量
            if type(v.X) ~= "number" or type(v.Y) ~= "number" or type(v.Z) ~= "number" then
                return false
            end

            -- W是可选的，如果存在必须是数字
            if v.W ~= nil and type(v.W) ~= "number" then
                return false
            end

            return true
        end

        return isVector(value) or
            (isArray(value) and checkArrayElements(value, isVector))
    end,
    Color = function(value)
        local function isValidColor(v)
            -- 调试信息输出
            if UDK_Property.SyncConf.Status.DebugPrint then
                print(string.format("调试Color验证: 值=%s, 类型=%s", tostring(v), type(v)))
            end

            if type(v) ~= "string" then
                if UDK_Property.SyncConf.Status.DebugPrint then
                    print("  失败: 不是字符串类型")
                end
                return false
            end

            -- 移除可能的空白字符
            local cleanValue = string.gsub(v, "%s", "")

            if UDK_Property.SyncConf.Status.DebugPrint then
                print(string.format("清理后的值: %s", cleanValue))
            end

            -- 检查长度（#RRGGBB 或 #RRGGBBAA）
            if #cleanValue ~= 7 and #cleanValue ~= 9 then
                if UDK_Property.SyncConf.Status.DebugPrint then
                    print(string.format("失败: 长度无效 (长度=%d, 应为7或9)", #cleanValue))
                end
                return false
            end

            -- 检查#前缀
            if string.sub(cleanValue, 1, 1) ~= "#" then
                if UDK_Property.SyncConf.Status.DebugPrint then
                    print("失败: 缺少#前缀")
                end
                return false
            end

            -- 检查其余字符是否都是有效的十六进制数字
            local hex = string.sub(cleanValue, 2)
            for i = 1, #hex do
                local c = string.sub(hex, i, i)
                if not string.match(c, "[0-9A-Fa-f]") then
                    if UDK_Property.SyncConf.Status.DebugPrint then
                        print(string.format("失败: 无效的十六进制字符 '%s' 在位置 %d", c, i + 1))
                    end
                    return false
                end
            end

            if UDK_Property.SyncConf.Status.DebugPrint then
                print("  验证通过")
            end

            return true
        end

        return isValidColor(value) or
            (isArray(value) and checkArrayElements(value, isValidColor))
    end,
    Map = function(value)
        if type(value) == "table" then
            for k, v in pairs(value) do
                if type(k) ~= "string" then
                    return false
                end
            end
            return true
        else
            return false
        end
    end,
    Any = function(value)
        if value ~= nil then
            return true
        else
            return false
        end
    end,
}

--- 辅助函数：规范化对象标识符
local function normalizeObjectID(object)
    -- 检查nil值
    if object == nil then
        return nil, "对象标识符不能为nil"
    end

    -- 处理字符串类型（直接返回）
    if type(object) == "string" then
        return object
    end

    -- 处理数字类型和表类型（带id属性）
    local valueToConvert
    if type(object) == "number" then
        valueToConvert = object
    elseif type(object) == "table" and object.id then
        valueToConvert = object.id
    else
        -- 其他情况，直接转换对象本身
        valueToConvert = object
    end

    -- 转换为字符串并验证结果
    local converted = tostring(valueToConvert)
    if converted == nil then
        return nil, "无法将对象转换为有效的标识符"
    end

    return converted
end

--- 辅助函数：创建格式化日志
local function createFormatLog(msg)
    local prefix = "[UDK:Property]"
    local log = string.format("%s %s", prefix, msg)
    return log
end


--- 辅助函数：获取时间戳
---@return number integer 时间戳（毫秒）
local function getTimestamp()
    if UDK_Property.SyncConf.Status.UnitTestMode then
        return os.time()
    else
        local serverTime = MiscService:GetServerTimeToTime()
        local timeStamp = MiscService:DateYMDHMSToTime(serverTime) --1702594800
        return math.floor(timeStamp * 1000)
    end
end

--- 生成NanoID
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

--- 通用验证函数
---@param object string | number | {id: string | number}
---@param propertyType string 强制检查
---@param propertyName string? 只有get操作需要检查propertyName参数
---@param data any | nil 只有set操作需要检查data参数
---@param operation string 操作类型 (`get` |  `set`)
---@return string|nil normalizeID 标准化后的对象ID
---@return string? error 错误信息
local function validatePropertyParams(object, propertyType, propertyName, data, operation)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return nil, error
    end

    -- 只有get操作时，propertyType不能为nil
    if operation == "get" and not propertyType then
        return nil, "属性类型不能为nil"
    end

    -- 只有get操作才需要属性名称
    if operation == "get" and not propertyName then
        return nil, "属性名称不能为nil"
    end

    -- 只有set操作需要检查data参数
    if operation == "set" and data == nil then
        return nil, "属性值不能为nil"
    end

    return normalizeID
end

--- 验证属性值类型
---@param object string|number 对象标识符
---@param propertyType string 属性类型
---@param data any 属性值
---@return boolean isValid 是否有效
---@return string? error 错误信息
local function validatePropertyValue(object, propertyType, data)
    local errorMsg, fmtLog
    if not UDK_Property.Type[propertyType] then
        errorMsg = string.format("[Validate] 不支持的属性类型: %s | TimeStamp: %s", propertyType, getTimestamp())
        fmtLog = createFormatLog(errorMsg)
        return false, fmtLog
    end

    -- 验证数据是否为nil
    if data == nil then
        errorMsg = string.format("[Validate] 对象: %s (Type: %s) 属性值不能为nil | TimeStamp: %s",
            tostring(object),
            propertyType,
            getTimestamp()
        )
        fmtLog = createFormatLog(errorMsg)
        return false, fmtLog
    end

    -- 获取验证函数
    local validator = TypeValidators[propertyType]
    if not validator then
        errorMsg = string.format("[Validate] 找不到类型验证器: %s", propertyType)
        fmtLog = createFormatLog(errorMsg)
        return false, fmtLog
    end

    -- 验证数据
    if not validator(data) then
        errorMsg = string.format("[Validate] 属性值类型无效，期望 %s，实际为 %s", propertyType, type(data))
        fmtLog = createFormatLog(errorMsg)
        return false, fmtLog
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
    for _, typeName in pairs(UDK_Property.Type) do
        if TypeValidators[typeName](value) then
            return typeName
        end
    end

    return "Any"
end

-- ==================================================
-- * UDK Property ACL Code
-- ==================================================


-- ==================================================
-- * UDK Property Network Code
-- ==================================================

--- 检测网络请求是否有效
local function networkValidRequest(requestTime)
    local currentTime = getTimestamp()
    if currentTime - requestTime > UDK_Property.SyncConf.RequestLifetime then
        return false, "请求已过期"
    else
        return true, "请求有效"
    end
end

--- 检测网络协议版本
local function networkProtocolVersionCheck(protocolVersion)
    -- 检查版本号是否存在
    if not protocolVersion then
        Log:PrintError(createFormatLog("NetProtocolCheck: 协议版本检查失败: 缺少协议版本号"))
        return false
    end

    -- 获取期望的协议版本
    local expectedVersion = UDK_Property.SyncConf.Status.ProtocolVersion

    -- 比较版本号
    if protocolVersion ~= expectedVersion then
        Log:PrintError(createFormatLog(string.format("NetProtocolCheck: 协议版本不匹配: 期望 %s, 实际 %s",
            expectedVersion, protocolVersion)))
        return false
    end

    -- 版本匹配
    if UDK_Property.SyncConf.Status.DebugPrint then
        Log:PrintLog(createFormatLog("NetProtocolCheck: 协议版本匹配: " .. protocolVersion))
    end

    return true
end

--- 网络同步请求处理
local function networkSyncEventHandle(reqMsg)
    -- body
end

--- 网络同步消息数据包构建
local function networkSyncMessageBuild(msgStructure, dataStructure)
    local msg = {
        event = {
            id = msgStructure.MsgID,
            type = msgStructure.EventType,
            reqID = msgStructure.RequestID or 0,
            reqTimestamp = msgStructure.RequestTimestamp or 0,
            envType = msgStructure.EnvType or 0,
            envName = msgStructure.EnvName or "Unknown",
            protocolVersion = msgStructure.ProtocolVersion or 0,
        },
        dataSyncReq = {
            reqType = msgStructure.ReqType,
            object = dataStructure.Object,
            type = dataStructure.Type,
            name = dataStructure.Name,
            data = dataStructure.Data
        }
    }
end

local function networkRpcMessageHandler()
    return function(_msgId, msg, _playerID)
        -- 检查请求有效性
        local reqValid, errorMsg = networkValidRequest(msg.event.reqTimestamp)
        local event, syncReq, text = msg.event, msg.dataSyncReq, ""
        local envType = UDK_Property.SyncConf.EnvType

        -- 处理单机/编辑器模式
        if event.envType == envType.Server.ID then
            if UDK_Property.SyncConf.Status.DebugPrint then
                text = "Client"
                Log:PrintLog(string.format("[%s] 收到了来自%s的同步请求: %s (%s, %s)",
                    text, event.envName, event.reqID, event.reqTimestamp, syncReq.reqType))
            end
        end
        if event.envType == envType.Client.ID then
            text = "Server"
            if UDK_Property.SyncConf.Status.DebugPrint then
                Log:PrintLog(string.format("[%s] 收到了来自%s的同步请求: %s (%s, %s)",
                    text, event.envName, event.reqID, event.reqTimestamp, syncReq.reqType))
                Log:PrintLog(syncReq.object, syncReq.type, syncReq.name, tostring(syncReq.data))
            end
        end
        if event.envType == envType.Standalone.ID and UDK_Property.SyncConf.Status.StandaloneDebug then
            text = "Standalone Debug"
            if UDK_Property.SyncConf.Status.DebugPrint then
                Log:PrintLog(string.format("[%s] 收到了来自%s的同步请求: %s (%s, %s)",
                    text, event.envName, event.reqID, event.reqTimestamp, syncReq.reqType))
            end
        end

        -- 处理请求
        if reqValid then
            networkSyncEventHandle(msg)
        else
            Log:PrintWarning(string.format("收到来自%s的请求，但请求已过期: %s (%s, %s)",
                text, event.reqID, event.reqTimestamp, syncReq.reqType))
        end
    end
end

--- 网络RPC通知初始化
local function networkBindNotifyInit()
    if System:IsServer() then
        System:BindNotify(UDK_Property.NetMsg.ClientSync, networkRpcMessageHandler())
        System:BindNotify(UDK_Property.NetMsg.ClientQueryAuthorityData, networkRpcMessageHandler()) --TODO
    end

    if System:IsClient() then
        System:BindNotify(UDK_Property.NetMsg.ServerSync, networkRpcMessageHandler())
        System:BindNotify(UDK_Property.NetMsg.ServerAuthoritySync, networkRpcMessageHandler())
        System:BindNotify(UDK_Property.NetMsg.ServerSendAuthorityData, networkRpcMessageHandler()) --TODO
    end
end

-- 调用游戏运行事件，进行注册网络消息通知
if not UDK_Property.SyncConf.Status.UnitTestMode then
    System:RegisterEvent(Events.ON_BEGIN_PLAY, networkBindNotifyInit)
end

---| 设置属性数据
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param propertyType SupportType | string
---@param propertyName string
---@param data any
---@param accessLevel string?
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.SetProperty(object, propertyType, propertyName, data, accessLevel)
    local normalizeID, error = validatePropertyParams(object, propertyType, propertyName, data, "set")
    if not normalizeID then
        return false, error
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return false, "无效的访问级别: " .. tostring(accessLevel)
    end

    -- 验证属性值类型
    local isVaild, error = validatePropertyValue(normalizeID, propertyType, data)
    if not isVaild then
        return false, error
    end

    -- 初始化多级存储结构
    dataStore.data[normalizeID] = dataStore.data[normalizeID] or {}
    dataStore.data[normalizeID][propertyType] = dataStore.data[normalizeID][propertyType] or {}

    -- 初始化访问控制结构
    --accessControlStore[normalizeID] = accessControlStore[normalizeID] or {}
    --accessControlStore[normalizeID][propertyType] = accessControlStore[normalizeID][propertyType] or {}

    -- 检查是否是新属性
    local isNewProperty = dataStore.data[normalizeID][propertyType][propertyName] == nil

    -- 存储数据和访问控制信息
    dataStore.data[normalizeID][propertyType][propertyName] = data
    --accessControlStore[normalizeID][propertyType][propertyName] = accessLevel

    -- 更新统计信息（仅对新属性）
    if isNewProperty then
        dataStore.stats.totalCount = dataStore.stats.totalCount + 1
        dataStore.stats.typeCount[propertyType] = (dataStore.stats.typeCount[propertyType] or 0) + 1
    end

    return true
end

---| 批量设置属性数据
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param properties table<string, table<string, any>> 属性表 {propertyType = {propertyName = value}}
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.SetBatchProperties(object, properties)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
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
            local isValid, error = validatePropertyValue(normalizeID, propertyType, value)
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

    return true
end

---| 获取属性值
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param propertyType SupportType | string
---@param propertyName string
---@return any? data 获取到的属性值
---@return string? error 错误信息
function UDK_Property.GetProperty(object, propertyType, propertyName)
    local normalizeID, error = validatePropertyParams(object, propertyType, propertyName, nil, "get")
    if not normalizeID then
        return nil, error
    end

    -- 检查数据是否存在
    if dataStore.data[normalizeID] == nil or
        dataStore.data[normalizeID][propertyType] == nil or
        dataStore.data[normalizeID][propertyType][propertyName] == nil then
        return false, "属性不存在"
    end

    -- 直接返回值，包括 false
    return dataStore.data[normalizeID][propertyType][propertyName]
end

---|📘- 获取对象的所有属性
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@return table<string, table<string, any>>? properties 属性表 {propertyType = {propertyName = value}}
---@return string? error 错误信息
function UDK_Property.GetAllProperties(object)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return nil, error
    end

    if not dataStore.data[normalizeID] then
        return {}, "对象没有任何属性"
    end

    -- 创建一个新表来存储结果，避免直接返回内部数据引用
    local result = {}
    for propertyType, properties in pairs(dataStore.data[normalizeID]) do
        result[propertyType] = {}
        for propertyName, value in pairs(properties) do
            result[propertyType][propertyName] = value
        end
    end

    return result
end

---| 获取属性类型信息
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param propertyType SupportType | string 属性类型
---@param propertyName string 属性名称
---@return table? data 类型信息 {type: string, isArray: boolean, elementType?: string}
---@return string? error 错误信息
function UDK_Property.GetPropertyTypeInfo(object, propertyType, propertyName)
    local normalizeID, error = validatePropertyParams(object, propertyType, propertyName, nil, "get")
    if not normalizeID then
        return nil, error
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

---| 获取对象特定类型的所有属性
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param propertyType SupportType | string 属性类型
---@return table<string, any>? properties 属性表 {propertyName = value}
---@return string? error 错误信息
function UDK_Property.GetPropertiesByType(object, propertyType)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return nil, error
    end

    if not propertyType then
        return nil, "属性类型不能为nil"
    end

    if not dataStore.data[normalizeID] or not dataStore.data[normalizeID][propertyType] then
        return {}, "对象没有该类型的属性"
    end

    -- 创建一个新表来存储结果，避免直接返回内部数据引用
    local result = {}
    for propertyName, value in pairs(dataStore.data[normalizeID][propertyType]) do
        result[propertyName] = value
    end

    return result
end

---| 删除属性值
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param propertyType SupportType | string
---@param propertyName string
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.DeleteProperty(object, propertyType, propertyName)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return false, error
    end

    -- 检查数据是否存在
    if dataStore.data[normalizeID] == nil or
        dataStore.data[normalizeID][propertyType] == nil or
        dataStore.data[normalizeID][propertyType][propertyName] == nil then
        return false, "属性不存在"
    end

    -- 更新统计信息
    dataStore.stats.totalCount = dataStore.stats.totalCount - 1
    dataStore.stats.typeCount[propertyType] = dataStore.stats.typeCount[propertyType] - 1

    -- 删除属性
    dataStore.data[normalizeID][propertyType][propertyName] = nil

    -- 清理空表
    if next(dataStore.data[normalizeID][propertyType]) == nil then
        dataStore.data[normalizeID][propertyType] = nil
        if next(dataStore.data[normalizeID]) == nil then
            dataStore.data[normalizeID] = nil
        end
    end

    return true
end

---| 删除对象下面所有对应类型的属性
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param propertyType SupportType | string
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.ClearProperty(object, propertyType)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return false, error
    end

    if not dataStore.data[normalizeID] then
        return false, "对象不存在"
    end

    if propertyType then
        -- 删除指定类型的所有属性
        if dataStore.data[normalizeID][propertyType] then
            local count = 0
            for _ in pairs(dataStore.data[normalizeID][propertyType]) do
                count = count + 1
            end
            dataStore.stats.totalCount = dataStore.stats.totalCount - count
            dataStore.stats.typeCount[propertyType] = (dataStore.stats.typeCount[propertyType] or 0) - count
            dataStore.data[normalizeID][propertyType] = nil

            -- 如果对象没有其他属性类型，清理对象
            if next(dataStore.data[normalizeID]) == nil then
                dataStore.data[normalizeID] = nil
            end
        end
    else
        -- 删除所有类型的属性
        for pType, properties in pairs(dataStore.data[normalizeID]) do
            local count = 0
            for _ in pairs(properties) do
                count = count + 1
            end
            dataStore.stats.totalCount = dataStore.stats.totalCount - count
            dataStore.stats.typeCount[pType] = (dataStore.stats.typeCount[pType] or 0) - count
        end
        dataStore.data[normalizeID] = nil
    end

    return true
end

---| 获取统计数据
---@return table info  统计信息
function UDK_Property.GetStats()
    return {
        totalCount = dataStore.stats.totalCount,
        typeCount = dataStore.stats.typeCount,
    }
end

---| 检查值是否为数组类型
---@param value any 要检查的值
---@param elementType? string 元素类型（可选）
---@return boolean isArray 是否为数组
---@return string? error 错误信息
function UDK_Property.IsArray(value, elementType)
    if not isArray(value) then
        return false, "不是有效的数组"
    end

    if elementType then
        local validator = TypeValidators[elementType]
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

---|📘- 检查属性是否存在
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number}
---@param propertyType SupportType | string
---@param propertyName string 属性名称
---@return boolean exists 是否存在
function UDK_Property.CheckPropertyHasExist(object, propertyType, propertyName)
    local normalizeID = normalizeObjectID(object)
    if not normalizeID or not propertyType or not propertyName then
        return false
    end

    return dataStore.data[normalizeID] ~= nil and
        dataStore.data[normalizeID][propertyType] ~= nil and
        dataStore.data[normalizeID][propertyType][propertyName] ~= nil
end

return UDK_Property
