-- ==================================================
-- * UniX SDK - Property Module (C/S Sync)
-- * Version: 0.0.3
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
-- * 2025-2026 © RoidMC Studios
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
    Public = "Public",   -- 公开访问
    Isolate = "Isolate", -- 隔离访问
}

--- 网络消息ID
---@enum UDK_Property.NetMsg
UDK_Property.NetMsg = {
    ServerSync = 200000,
    ClientSync = 200001,
    ServerAuthoritySync = 200010,
}

--- 同步配置
---@class UDK_Property.SyncConf
UDK_Property.SyncConf = {
    RequestLifetime = 15000, -- 请求超时时间
    Type = {
        ServerSync = "ServerSyncEvent",
        ClientSync = "ClientSyncEvent",
        ServerAuthoritySync = "ServerAuthoritySync"
    },
    CRUD = {
        Create = "Create",
        SetBatch = "SetBatch",
        Update = "Update",
        Delete = "Delete",
        Clear = "Clear",
        Get = "Get", -- WIP
        Sync = "Sync"
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

--- 返回当前环境状态 (仅元梦Lua环境可调用)
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
            for k, _ in pairs(value) do
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
---@return integer timeStamp 时间戳（毫秒）
local function getTimestamp()
    if UDK_Property.SyncConf.Status.UnitTestMode then
        return os.time()
    else
        local serverTime = MiscService:GetServerTimestamp()
        return serverTime
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

---计算数据的 CRC32 校验值
---@param data string | table  输入数据（字符串 或 存储字节值的 table，如 {0x48, 0x65, 0x6c, 0x6c, 0x6f}）
---@return number checkSum 校验值（32 位无符号整数）
local function crc32(data)
    -- CRC32 多项式（IEEE 802.3 标准，反射多项式）
    local POLYNOMIAL = 0xEDB88320

    -- 预生成 CRC32 查找表（使用闭包避免重复计算）
    local crc_table = {}
    for i = 0, 255 do
        local crc = i
        for _ = 1, 8 do
            local crc_msb = (crc & 1) ~= 0
            crc = crc >> 1
            if crc_msb then
                crc = crc ~ POLYNOMIAL
            end
        end
        crc_table[i] = crc
    end

    -- 表序列化函数（内联实现）
    local function tableToBytes(tbl)
        local bytes = {}
        local byteCount = 0

        local function addByte(byte)
            byteCount = byteCount + 1
            bytes[byteCount] = byte & 0xFF
        end

        local function addInt(num)
            num = math.floor(num)
            addByte(num & 0xFF)
            addByte((num >> 8) & 0xFF)
            addByte((num >> 16) & 0xFF)
            addByte((num >> 24) & 0xFF)
        end

        local function addString(str)
            addInt(#str)
            for i = 1, #str do
                addByte(str:byte(i))
            end
        end

        local function serializeTable(t)
            addByte(1) -- 表标记

            local numberKeys, stringKeys, otherKeys = {}, {}, {}
            for k in pairs(t) do
                local tk = type(k)
                if tk == "number" then
                    table.insert(numberKeys, k)
                elseif tk == "string" then
                    table.insert(stringKeys, k)
                else
                    table.insert(otherKeys, k)
                end
            end

            table.sort(numberKeys)
            table.sort(stringKeys)
            table.sort(otherKeys, function(a, b) return tostring(a) < tostring(b) end)

            local totalKeys = #numberKeys + #stringKeys + #otherKeys
            addInt(totalKeys)

            for _, k in ipairs(numberKeys) do
                addByte(2); addInt(k)
                local v = t[k]
                local tv = type(v)
                if tv == "nil" then
                    addByte(0)
                elseif tv == "number" then
                    addByte(2); addInt(v)
                elseif tv == "string" then
                    addByte(3); addString(v)
                elseif tv == "boolean" then
                    addByte(5); addByte(v and 1 or 0)
                elseif tv == "table" then
                    addByte(1); serializeTable(v)
                else
                    addByte(4); addString(tostring(v))
                end
            end

            for _, k in ipairs(stringKeys) do
                addByte(3); addString(k)
                local v = t[k]
                local tv = type(v)
                if tv == "nil" then
                    addByte(0)
                elseif tv == "number" then
                    addByte(2); addInt(v)
                elseif tv == "string" then
                    addByte(3); addString(v)
                elseif tv == "boolean" then
                    addByte(5); addByte(v and 1 or 0)
                elseif tv == "table" then
                    addByte(1); serializeTable(v)
                else
                    addByte(4); addString(tostring(v))
                end
            end

            for _, k in ipairs(otherKeys) do
                addByte(4); addString(tostring(k))
                local v = t[k]
                local tv = type(v)
                if tv == "nil" then
                    addByte(0)
                elseif tv == "number" then
                    addByte(2); addInt(v)
                elseif tv == "string" then
                    addByte(3); addString(v)
                elseif tv == "boolean" then
                    addByte(5); addByte(v and 1 or 0)
                elseif tv == "table" then
                    addByte(1); serializeTable(v)
                else
                    addByte(4); addString(tostring(v))
                end
            end
        end

        serializeTable(tbl)
        return bytes
    end

    -- 处理输入数据类型
    local dataType = type(data)
    if dataType == "table" then
        data = tableToBytes(data)
        dataType = "table"
    end

    -- 计算CRC32
    local crc = 0xFFFFFFFF

    if dataType == "string" then
        local len = #data
        for i = 1, len do
            ---@diagnostic disable-next-line: param-type-mismatch
            local byte = data:byte(i)
            local index = (crc ~ byte) & 0xFF
            crc = (crc >> 8) ~ crc_table[index]
        end
    else -- 字节数组
        local len = #data
        for i = 1, len do
            local byte = data[i]
            local index = (crc ~ (byte & 0xFF)) & 0xFF
            crc = (crc >> 8) ~ crc_table[index]
        end
    end

    return crc ~ 0xFFFFFFFF
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
-- * UDK Property Swift Database Code
-- * Built-in ACL-based access control auditing
-- ==================================================

--- 内部数据存储
local dataStore = {
    -- 主数据存储 {object -> {accessLevel -> {propertyType -> {propertyName -> {value, createdAt, updatedAt}}}}
    data = {},
    -- 统计信息
    stats = {
        totalCount = 0,
        accessLevelCount = {
            Public = 0,
            Isolate = 0
        },
        typeCount = {},
    }
}

--- 设置数据到存储
---@param object string 对象ID
---@param accessLevel string 访问级别
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@param data any 属性值
---@return boolean success 是否成功
---@return string? error 错误信息
local function swiftDBSet(object, accessLevel, propertyType, propertyName, data)
    -- 初始化多级存储结构
    dataStore.data[object] = dataStore.data[object] or {}
    dataStore.data[object][accessLevel] = dataStore.data[object][accessLevel] or {}
    dataStore.data[object][accessLevel][propertyType] = dataStore.data[object][accessLevel][propertyType] or {}

    -- 检查是否是新属性
    local isNewProperty = dataStore.data[object][accessLevel][propertyType][propertyName] == nil

    -- 获取当前时间戳
    local currentTime = getTimestamp()

    -- 存储完整的数据结构
    if isNewProperty then
        dataStore.data[object][accessLevel][propertyType][propertyName] = {
            value = data,
            createdAt = currentTime,
            updatedAt = currentTime
        }

        -- 更新统计信息
        dataStore.stats.totalCount = dataStore.stats.totalCount + 1
        dataStore.stats.accessLevelCount[accessLevel] = (dataStore.stats.accessLevelCount[accessLevel] or 0) + 1
        dataStore.stats.typeCount[propertyType] = (dataStore.stats.typeCount[propertyType] or 0) + 1
    else
        -- 更新现有属性：保留创建时间，更新修改时间
        local existingData = dataStore.data[object][accessLevel][propertyType][propertyName]
        existingData.value = data
        existingData.updatedAt = currentTime
    end

    return true
end

--- 批量设置数据到存储
---@param object string 对象ID
---@param accessLevel string 访问级别
---@param properties table<string, table<string, any>> 属性表 {propertyType = {propertyName = value}}
---@return boolean success 是否成功
---@return string? error 错误信息
local function swiftDBSetBatch(object, accessLevel, properties)
    if not properties or type(properties) ~= "table" then
        return false, "属性表不能为nil且必须是table类型"
    end

    -- 遍历所有属性类型和属性名，使用 swiftDBSet 进行批量设置
    for propertyType, typeData in pairs(properties) do
        if type(typeData) ~= "table" then
            return false, string.format("属性类型 %s 的值必须是table类型", propertyType)
        end

        for propertyName, value in pairs(typeData) do
            local success, error = swiftDBSet(object, accessLevel, propertyType, propertyName, value)
            if not success then
                return false, string.format("设置属性失败 [%s.%s]: %s", propertyType, propertyName, error or "未知错误")
            end
        end
    end

    return true
end

--- 从存储获取数据
---@param object string 对象ID
---@param accessLevel string 访问级别
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@return any? data 属性值
---@return string? error 错误信息
local function swiftDBGet(object, accessLevel, propertyType, propertyName)
    -- 检查数据是否存在
    if dataStore.data[object] == nil or
        dataStore.data[object][accessLevel] == nil or
        dataStore.data[object][accessLevel][propertyType] == nil or
        dataStore.data[object][accessLevel][propertyType][propertyName] == nil then
        return nil, "属性不存在"
    end

    local propertyData = dataStore.data[object][accessLevel][propertyType][propertyName]

    -- 返回纯值，屏蔽元数据
    return propertyData.value
end

--- 获取对象的所有属性
---@param object string 对象ID
---@param accessLevel string? 访问级别，nil表示获取所有级别的属性
---@return table<string, table<string, any>>? properties 属性表 {accessLevel = {propertyType = {propertyName = value}}}
---@return string? error 错误信息
local function swiftDBGetAll(object, accessLevel)
    if not dataStore.data[object] then
        return {}, "对象没有任何属性"
    end

    -- 创建一个新表来存储结果，避免直接返回内部数据引用
    local result = {}

    if accessLevel then
        -- 获取指定访问级别的属性
        if not dataStore.data[object][accessLevel] then
            return {}, "对象没有该访问级别的属性"
        end

        result[accessLevel] = {}
        for propertyType, properties in pairs(dataStore.data[object][accessLevel]) do
            result[accessLevel][propertyType] = {}
            for propertyName, propertyData in pairs(properties) do
                result[accessLevel][propertyType][propertyName] = propertyData.value
            end
        end
    else
        -- 获取所有访问级别的属性
        for aLevel, aLevelData in pairs(dataStore.data[object]) do
            result[aLevel] = {}
            for propertyType, properties in pairs(aLevelData) do
                result[aLevel][propertyType] = {}
                for propertyName, propertyData in pairs(properties) do
                    result[aLevel][propertyType][propertyName] = propertyData.value
                end
            end
        end
    end

    return result
end

--- 获取对象特定类型的所有属性
---@param object string 对象ID
---@param accessLevel string 访问级别
---@param propertyType string 属性类型
---@return table<string, any>? properties 属性表 {propertyName = value}
---@return string? error 错误信息
local function swiftDBGetByType(object, accessLevel, propertyType)
    if not dataStore.data[object] or not dataStore.data[object][accessLevel] or not dataStore.data[object][accessLevel][propertyType] then
        return {}, "对象没有该访问级别或类型的属性"
    end

    -- 创建一个新表来存储结果，避免直接返回内部数据引用
    local result = {}
    for propertyName, propertyData in pairs(dataStore.data[object][accessLevel][propertyType]) do
        result[propertyName] = propertyData.value
    end

    return result
end

--- 检查属性是否存在
---@param object string 对象ID
---@param accessLevel string 访问级别
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@return boolean exists 是否存在
local function swiftDBExists(object, accessLevel, propertyType, propertyName)
    return dataStore.data[object] ~= nil and
        dataStore.data[object][accessLevel] ~= nil and
        dataStore.data[object][accessLevel][propertyType] ~= nil and
        dataStore.data[object][accessLevel][propertyType][propertyName] ~= nil
end

--- 删除属性
---@param object string 对象ID
---@param accessLevel string 访问级别
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@return boolean success 是否成功
---@return string? error 错误信息
local function swiftDBDelete(object, accessLevel, propertyType, propertyName)
    -- 检查数据是否存在
    if dataStore.data[object] == nil or
        dataStore.data[object][accessLevel] == nil or
        dataStore.data[object][accessLevel][propertyType] == nil or
        dataStore.data[object][accessLevel][propertyType][propertyName] == nil then
        return false, "属性不存在"
    end

    -- 更新统计信息
    dataStore.stats.totalCount = dataStore.stats.totalCount - 1
    dataStore.stats.accessLevelCount[accessLevel] = (dataStore.stats.accessLevelCount[accessLevel] or 0) - 1
    dataStore.stats.typeCount[propertyType] = (dataStore.stats.typeCount[propertyType] or 0) - 1

    -- 删除属性
    dataStore.data[object][accessLevel][propertyType][propertyName] = nil

    -- 清理空表
    if next(dataStore.data[object][accessLevel][propertyType]) == nil then
        dataStore.data[object][accessLevel][propertyType] = nil
        if next(dataStore.data[object][accessLevel]) == nil then
            dataStore.data[object][accessLevel] = nil
            if next(dataStore.data[object]) == nil then
                dataStore.data[object] = nil
            end
        end
    end

    return true
end

--- 清理对象属性
---@param object string 对象ID
---@param accessLevel string? 访问级别，nil表示清理所有级别
---@param propertyType string? 属性类型，nil表示清理所有类型
---@return boolean success 是否成功
---@return string? error 错误信息
local function swiftDBClear(object, accessLevel, propertyType)
    if not dataStore.data[object] then
        return false, "对象不存在"
    end

    if accessLevel and propertyType then
        -- 删除指定访问级别和类型的所有属性
        if dataStore.data[object][accessLevel] and dataStore.data[object][accessLevel][propertyType] then
            local count = 0
            for _ in pairs(dataStore.data[object][accessLevel][propertyType]) do
                count = count + 1
            end
            dataStore.stats.totalCount = dataStore.stats.totalCount - count
            dataStore.stats.accessLevelCount[accessLevel] = (dataStore.stats.accessLevelCount[accessLevel] or 0) - count
            dataStore.stats.typeCount[propertyType] = (dataStore.stats.typeCount[propertyType] or 0) - count
            dataStore.data[object][accessLevel][propertyType] = nil

            -- 清理空表
            if next(dataStore.data[object][accessLevel]) == nil then
                dataStore.data[object][accessLevel] = nil
            end
            if next(dataStore.data[object]) == nil then
                dataStore.data[object] = nil
            end
        end
    elseif accessLevel then
        -- 删除指定访问级别的所有属性
        if dataStore.data[object][accessLevel] then
            for pType, properties in pairs(dataStore.data[object][accessLevel]) do
                local count = 0
                for _ in pairs(properties) do
                    count = count + 1
                end
                dataStore.stats.totalCount = dataStore.stats.totalCount - count
                dataStore.stats.accessLevelCount[accessLevel] = (dataStore.stats.accessLevelCount[accessLevel] or 0) -
                    count
                dataStore.stats.typeCount[pType] = (dataStore.stats.typeCount[pType] or 0) - count
            end
            dataStore.data[object][accessLevel] = nil

            -- 如果对象没有其他访问级别，清理对象
            if next(dataStore.data[object]) == nil then
                dataStore.data[object] = nil
            end
        end
    else
        -- 删除所有访问级别的所有属性
        for aLevel, aLevelData in pairs(dataStore.data[object]) do
            for pType, properties in pairs(aLevelData) do
                local count = 0
                for _ in pairs(properties) do
                    count = count + 1
                end
                dataStore.stats.totalCount = dataStore.stats.totalCount - count
                dataStore.stats.accessLevelCount[aLevel] = (dataStore.stats.accessLevelCount[aLevel] or 0) - count
                dataStore.stats.typeCount[pType] = (dataStore.stats.typeCount[pType] or 0) - count
            end
        end
        dataStore.data[object] = nil
    end

    return true
end

--- 获取属性的完整数据结构（包括元数据）
---@param object string 对象ID
---@param accessLevel string 访问级别
---@param propertyType string 属性类型
---@param propertyName string 属性名称
---@return table? propertyData 完整属性数据 {value, createdAt, updatedAt}
---@return string? error 错误信息
local function swiftDBGetPropertyData(object, accessLevel, propertyType, propertyName)
    -- 检查数据是否存在
    local propertyData = dataStore.data[object] and
        dataStore.data[object][accessLevel] and
        dataStore.data[object][accessLevel][propertyType] and
        dataStore.data[object][accessLevel][propertyType][propertyName]

    if not propertyData then
        return nil, "属性不存在"
    end

    -- 返回完整的数据结构（深拷贝避免外部修改）
    return {
        value = propertyData.value,
        createdAt = propertyData.createdAt,
        updatedAt = propertyData.updatedAt
    }
end

--- 获取统计信息
---@return table info 统计信息
local function swiftDBGetStats()
    return {
        totalCount = dataStore.stats.totalCount,
        accessLevelCount = dataStore.stats.accessLevelCount,
        typeCount = dataStore.stats.typeCount,
    }
end

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

    -- 检查版本号格式（应该是一个有效的语义版本号）
    if type(protocolVersion) ~= "string" or not protocolVersion:match("^%d+%.%d+%.%d+$") then
        Log:PrintError(createFormatLog("NetProtocolCheck: 协议版本格式无效: " .. tostring(protocolVersion)))
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

--- 网络同步CRC32生成
local function networkSyncCRC32Generate(reqMsg)
    local checksumData = {
        reqInfo = {
            reqID = reqMsg.event.reqID,
            reqTimestamp = reqMsg.event.reqTimestamp,
        },
        checkData = reqMsg.dataSyncReq,
    }
    local checkSum = crc32(checksumData)
    return checkSum
end

--- 网络同步请求处理
local function networkSyncEventHandle(reqMsg)
    if reqMsg == nil then
        return
    end

    local event = reqMsg.event
    local syncReq = reqMsg.dataSyncReq

    -- 协议版本检查
    if not networkProtocolVersionCheck(event.protocolVersion) then
        Log:PrintError(createFormatLog("NetSyncHandle: 消息处理中止: 协议版本检查失败"))
        return
    end

    -- 检查是否存在 CRC32 字段
    if event.crc32 == nil then
        Log:PrintError(createFormatLog("NetSyncHandle: 接收到的消息缺少crc32字段，请求无效"))
        return
    end

    -- CRC32 校验
    local receivedCRC32 = event.crc32
    local calculatedCRC32 = networkSyncCRC32Generate(reqMsg)

    if receivedCRC32 ~= calculatedCRC32 then
        Log:PrintError(createFormatLog("NetSyncHandle: CRC32校验失败: 期望 " .. calculatedCRC32 .. ", 实际 " .. receivedCRC32))
        return
    end

    -- 请求处理
    if syncReq ~= nil then
        -- 验证必需字段
        if not syncReq.object or not syncReq.accessLevel then
            Log:PrintError(createFormatLog("NetSyncHandle: 同步请求缺少必需字段"))
            return
        end

        -- 验证访问级别
        if not UDK_Property.AccessLevel[syncReq.accessLevel] then
            Log:PrintError(createFormatLog("NetSyncHandle: 无效的访问级别: " .. tostring(syncReq.accessLevel)))
            return
        end

        local crud = UDK_Property.SyncConf.CRUD
        -- 创建/更新
        if syncReq.reqType == crud.Create or syncReq.reqType == crud.Update then
            -- 验证字段完整性
            if not syncReq.type or not syncReq.name or syncReq.data == nil then
                Log:PrintError(createFormatLog("NetSyncHandle: 创建/更新请求缺少必需字段"))
                return
            end
            swiftDBSet(syncReq.object, syncReq.accessLevel, syncReq.type, syncReq.name, syncReq.data)
            if UDK_Property.SyncConf.Status.DebugPrint then
                print(string.format("已接收并应用%s权威数据，共 %d 个属性，名称 %s",
                    event.envName or "Unknown", dataStore.stats.totalCount, tostring(syncReq.name)))
            end
            -- 常规删除
        elseif syncReq.reqType == crud.Delete then
            -- 验证字段完整性
            if not syncReq.type or not syncReq.name then
                Log:PrintError(createFormatLog("NetSyncHandle: 删除请求缺少必需字段"))
                return
            end
            swiftDBDelete(syncReq.object, syncReq.accessLevel, syncReq.type, syncReq.name)
            -- 批量设置
        elseif syncReq.reqType == crud.Clear then
            -- 验证字段完整性
            if not syncReq.type then
                Log:PrintError(createFormatLog("NetSyncHandle: 清理请求缺少必需字段"))
                return
            end
            swiftDBClear(syncReq.object, syncReq.accessLevel, syncReq.type)
        elseif syncReq.reqType == crud.SetBatch then
            -- 验证字段完整性
            if not syncReq.data or type(syncReq.data) ~= "table" then
                Log:PrintError(createFormatLog("NetSyncHandle: 批量设置请求数据无效"))
                return
            end
            local success, error = swiftDBSetBatch(syncReq.object, syncReq.accessLevel, syncReq.data)
            if not success and UDK_Property.SyncConf.Status.DebugPrint then
                print(string.format("批量设置%s权威数据失败: %s", event.envName or "Unknown", error or "未知错误"))
            elseif UDK_Property.SyncConf.Status.DebugPrint then
                local propertyCount = 0
                for _, typeData in pairs(syncReq.data) do
                    for _ in pairs(typeData) do
                        propertyCount = propertyCount + 1
                    end
                end
                print(string.format("已接收并应用%s批量权威数据，共 %d 个属性",
                    event.envName or "Unknown", propertyCount))
            end
        elseif syncReq.reqType == crud.Sync then
            -- 处理权威数据同步请求
            if syncReq.object == "FULL_DATA_SYNC" then
                -- 全量数据同步
                if syncReq.data and type(syncReq.data) == "table" then
                    -- 清理当前所有Public数据
                    for objectId, _ in pairs(dataStore.data) do
                        swiftDBClear(objectId, UDK_Property.AccessLevel.Public)
                    end

                    -- 重新设置所有接收到的数据
                    for objectId, objectData in pairs(syncReq.data) do
                        if type(objectData) == "table" then
                            for accessLevel, levelData in pairs(objectData) do
                                if accessLevel == UDK_Property.AccessLevel.Public and type(levelData) == "table" then
                                    for propertyType, typeData in pairs(levelData) do
                                        if type(typeData) == "table" then
                                            for propertyName, propertyValue in pairs(typeData) do
                                                swiftDBSet(objectId, accessLevel, propertyType, propertyName,
                                                    propertyValue)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if UDK_Property.SyncConf.Status.DebugPrint then
                        print(string.format("已接收并应用%s全量权威数据同步", event.envName or "Unknown"))
                    end
                else
                    Log:PrintError(createFormatLog("NetSyncHandle: 全量数据同步请求数据无效"))
                end
            else
                -- 单个属性同步
                if not syncReq.type or not syncReq.name or syncReq.data == nil then
                    Log:PrintError(createFormatLog("NetSyncHandle: 单个属性同步请求缺少必需字段"))
                    return
                end

                swiftDBSet(syncReq.object, syncReq.accessLevel, syncReq.type, syncReq.name, syncReq.data)
                if UDK_Property.SyncConf.Status.DebugPrint then
                    print(string.format("已接收并应用%s单个属性权威数据同步，对象 %s，类型 %s，名称 %s",
                        event.envName or "Unknown", syncReq.object, syncReq.type, syncReq.name))
                end
            end
        else
            Log:PrintError(createFormatLog("NetSyncHandle: 未知的请求类型: " .. tostring(syncReq.reqType)))
        end
    end
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
            data = dataStructure.Data,
            accessLevel = dataStructure.AccessLevel
        }
    }

    msg.event.crc32 = networkSyncCRC32Generate(msg)

    return msg
end

--- 网络RPC消息发送
--- @param reqType string 请求类型
--- @param object string 对象名称
--- @param propertyType string 属性类型
--- @param propertyName string 属性名称
--- @param propertyValue any 属性值
--- @param accessLevel string 属性访问级别
--- @param playerID number? 玩家ID（可选，不填默认同步给所有玩家）
--- @return boolean isSend 是否成功发送
--- @return string? error 错误信息
local function networkRpcMessageSender(reqType, object, propertyType, propertyName, propertyValue, accessLevel, playerID)
    -- 检查是否处于单元测试模式
    if UDK_Property.SyncConf.Status.UnitTestMode then
        return false, "单元测试模式"
    end

    -- 只有Public级别的属性才需要网络同步
    if accessLevel ~= UDK_Property.AccessLevel.Public then
        return true, "非Public级别，跳过网络同步"
    end

    -- 参数验证
    if not reqType then
        return false, "缺少请求类型参数"
    end

    if not object then
        return false, "缺少对象名称参数"
    end

    -- 验证请求类型
    local crud = UDK_Property.SyncConf.CRUD
    local validReqTypes = {
        [crud.Create] = true,
        [crud.Update] = true,
        [crud.Delete] = true,
        [crud.Clear] = true,
        [crud.SetBatch] = true,
        [crud.Sync] = true
    }
    if not validReqTypes[reqType] then
        return false, "无效的请求类型: " .. tostring(reqType)
    end

    -- 批量操作的特殊验证
    if reqType == crud.SetBatch then
        if not propertyValue or type(propertyValue) ~= "table" then
            return false, "批量操作需要有效的属性表"
        end
    elseif reqType == crud.Sync and object ~= "FULL_DATA_SYNC" then
        -- Sync操作（单个属性）需要验证基本字段
        if not propertyType then
            return false, "缺少属性类型参数"
        end
        if not propertyName then
            return false, "缺少属性名称参数"
        end
    elseif reqType == crud.Sync and object == "FULL_DATA_SYNC" then
        -- Sync操作（全量数据）需要验证数据
        if not propertyValue or type(propertyValue) ~= "table" then
            return false, "全量数据同步需要有效的数据表"
        end
    else
        -- 非批量操作需要验证基本字段
        if not propertyType then
            return false, "缺少属性类型参数"
        end
        if not propertyName then
            return false, "缺少属性名称参数"
        end
    end

    -- 获取当前环境信息并构建数据结构
    local envInfo = envCheck()
    local envType = UDK_Property.SyncConf.EnvType

    local dataStructure
    -- 常规操作的数据结构
    dataStructure = {
        Object = object,
        Type = propertyType or "",
        Name = propertyName or "",
        Data = propertyValue, -- 全量同步时这里会带全数据
        AccessLevel = accessLevel
    }

    -- 服务器环境
    if envInfo.envID == envType.Server.ID or envInfo.isStandalone then
        local netMsgID, netMsgType
        if reqType == crud.Sync then
            netMsgID = UDK_Property.NetMsg.ServerAuthoritySync
            netMsgType = UDK_Property.SyncConf.Type.ServerAuthoritySync
        else
            netMsgID = UDK_Property.NetMsg.ServerSync
            netMsgType = UDK_Property.SyncConf.Type.ServerSync
        end
        local msgStructure = {
            MsgID = netMsgID,
            EventType = netMsgType,
            RequestID = nanoIDGenerate(),
            RequestTimestamp = getTimestamp(),
            EnvType = envInfo.envID,
            EnvName = envInfo.envName,
            ReqType = reqType,
            ProtocolVersion = UDK_Property.SyncConf.Status.ProtocolVersion
        }

        local msg = networkSyncMessageBuild(msgStructure, dataStructure)
        if type(playerID) == "number" and playerID ~= nil then
            System:SendToClient(playerID, msgStructure.MsgID, msg)
        else
            System:SendToAllClients(msgStructure.MsgID, msg)
        end
        return true
    end

    -- 客户端环境
    if envInfo.envID == envType.Client.ID then
        local msgStructure = {
            MsgID = UDK_Property.NetMsg.ClientSync,
            EventType = UDK_Property.SyncConf.Type.ClientSync,
            RequestID = nanoIDGenerate(),
            RequestTimestamp = getTimestamp(),
            EnvType = envInfo.envID,
            EnvName = envInfo.envName,
            ReqType = reqType,
            ProtocolVersion = UDK_Property.SyncConf.Status.ProtocolVersion
        }

        local msg = networkSyncMessageBuild(msgStructure, dataStructure)
        System:SendToServer(msgStructure.MsgID, msg)
        return true
    end

    return false, "未知环境类型"
end

--- 网络RPC消息处理
local function networkRpcMessageHandler()
    return function(_, msg)
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
            Log:PrintWarning(string.format("收到来自%s的请求，但请求已过期: %s (%s, %s) (%s)",
                text, event.reqID, event.reqTimestamp, syncReq.reqType, errorMsg))
        end
    end
end

--- 网络RPC通知初始化
local function networkBindNotifyInit()
    if System:IsServer() then
        System:BindNotify(UDK_Property.NetMsg.ClientSync, networkRpcMessageHandler())
    end

    if System:IsClient() then
        System:BindNotify(UDK_Property.NetMsg.ServerSync, networkRpcMessageHandler())
        System:BindNotify(UDK_Property.NetMsg.ServerAuthoritySync, networkRpcMessageHandler())
    end
end

-- 调用游戏运行事件，进行注册网络消息通知
if not UDK_Property.SyncConf.Status.UnitTestMode then
    System:RegisterEvent(Events.ON_BEGIN_PLAY, networkBindNotifyInit)
end

-- ==================================================
-- * UDK Property Core Functions
-- ==================================================

---|📘- 设置属性数据
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param propertyName string 属性名称
---@param data any 属性数据
---@param accessLevel string? 访问级别，默认为Public
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.SetProperty(object, propertyType, propertyName, data, accessLevel)
    local normalizeID, errorMsg = validatePropertyParams(object, propertyType, propertyName, data, "set")
    local isVaild
    if not normalizeID then
        return false, errorMsg
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return false, "无效的访问级别: " .. tostring(accessLevel)
    end

    -- 验证属性值类型
    isVaild, errorMsg = validatePropertyValue(normalizeID, propertyType, data)
    if not isVaild then
        return false, errorMsg
    end

    -- 检查是否是新属性（用于网络同步）
    local isNewProperty = not swiftDBExists(normalizeID, accessLevel, propertyType, propertyName)

    -- 使用SwiftDB存储数据
    local success, dbError = swiftDBSet(normalizeID, accessLevel, propertyType, propertyName, data)
    if not success then
        return false, dbError
    end

    -- 发送网络RPC消息
    local crudType = isNewProperty and UDK_Property.SyncConf.CRUD.Create or UDK_Property.SyncConf.CRUD.Update
    networkRpcMessageSender(crudType, normalizeID, propertyType, propertyName, data, accessLevel)

    return true
end

---|📘- 批量设置属性数据
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象ID
---@param properties table<string, table<string, any>> 属性表 {propertyType = {propertyName = value}}
---@param accessLevel string? 访问级别，默认为Public
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.SetBatchProperties(object, properties, accessLevel)
    local normalizeID, errorMsg = normalizeObjectID(object)
    local success, isValid
    if not normalizeID then
        return false, errorMsg
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
            isValid, errorMsg = validatePropertyValue(normalizeID, propertyType, value)
            if not isValid then
                return false, string.format("属性验证失败 [%s.%s]: %s", propertyType, propertyName, errorMsg)
            end
        end
    end

    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 使用SwiftDB的批量设置功能
    success, errorMsg = swiftDBSetBatch(normalizeID, accessLevel, properties)
    if not success then
        return false, errorMsg
    end

    local crudType = UDK_Property.SyncConf.CRUD.SetBatch
    -- 发送网络RPC消息（批量操作）
    networkRpcMessageSender(crudType, normalizeID, "", "", properties, accessLevel)

    return true
end

---|📘- 获取属性值
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param propertyName string 属性名称
---@param accessLevel string? 访问级别，默认为Public
---@return any? data 获取到的属性值
---@return string? error 错误信息
function UDK_Property.GetProperty(object, propertyType, propertyName, accessLevel)
    local normalizeID, error = validatePropertyParams(object, propertyType, propertyName, nil, "get")
    if not normalizeID then
        return nil, error
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return nil, "无效的访问级别: " .. tostring(accessLevel)
    end

    -- 使用SwiftDB获取数据
    return swiftDBGet(normalizeID, accessLevel, propertyType, propertyName)
end

---|📘- 获取对象的所有属性
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象名称
---@param accessLevel string? 访问级别，nil表示获取所有级别的属性，默认为nil
---@return table<string, table<string, any>>? properties 属性表 {accessLevel = {propertyType = {propertyName = value}}}
---@return string? error 错误信息
function UDK_Property.GetAllProperties(object, accessLevel)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return nil, error
    end

    -- 如果指定了访问级别，验证其有效性
    if accessLevel and not UDK_Property.AccessLevel[accessLevel] then
        return nil, "无效的访问级别: " .. tostring(accessLevel)
    end

    -- 使用SwiftDB获取所有属性
    return swiftDBGetAll(normalizeID, accessLevel)
end

---|📘- 获取属性类型信息
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param propertyName string 属性名称
---@param accessLevel string? 访问级别，默认为Public
---@return table? data 类型信息 {type: string, isArray: boolean, elementType?: string}
---@return string? error 错误信息
function UDK_Property.GetPropertyTypeInfo(object, propertyType, propertyName, accessLevel)
    local normalizeID, error = validatePropertyParams(object, propertyType, propertyName, nil, "get")
    if not normalizeID then
        return nil, error
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return nil, "无效的访问级别: " .. tostring(accessLevel)
    end

    local value, getError = swiftDBGet(normalizeID, accessLevel, propertyType, propertyName)
    if getError then
        return nil, getError
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

---|📘- 获取对象特定类型的所有属性
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param accessLevel string? 访问级别，默认为Public
---@return table<string, any>? properties 属性表 {propertyName = value}
---@return string? error 错误信息
function UDK_Property.GetPropertiesByType(object, propertyType, accessLevel)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return nil, error
    end

    if not propertyType then
        return nil, "属性类型不能为nil"
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return nil, "无效的访问级别: " .. tostring(accessLevel)
    end

    -- 使用SwiftDB获取特定类型的属性
    return swiftDBGetByType(normalizeID, accessLevel, propertyType)
end

---|📘- 删除属性值
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param propertyName string 属性名称
---@param accessLevel string? 访问级别，默认为Public
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.DeleteProperty(object, propertyType, propertyName, accessLevel)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return false, error
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return false, "无效的访问级别: " .. tostring(accessLevel)
    end

    local crudType = UDK_Property.SyncConf.CRUD.Delete
    networkRpcMessageSender(crudType, normalizeID, propertyType, propertyName, "", accessLevel)

    -- 使用SwiftDB删除属性
    return swiftDBDelete(normalizeID, accessLevel, propertyType, propertyName)
end

---|📘- 删除对象下面所有对应类型的属性
---
---| 支持类型 `Boolean` | `Number` |  `String` | `Array` | `Vector` | `Color` | `Map` | `Any`
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param accessLevel string? 访问级别，默认为Public
---@return boolean success 是否成功
---@return string? error 错误信息
function UDK_Property.ClearProperty(object, propertyType, accessLevel)
    local normalizeID, error = normalizeObjectID(object)
    if not normalizeID then
        return false, error
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return false, "无效的访问级别: " .. tostring(accessLevel)
    end

    local crudType = UDK_Property.SyncConf.CRUD.Clear
    networkRpcMessageSender(crudType, normalizeID, propertyType, "", "", accessLevel)

    -- 使用SwiftDB清理属性
    return swiftDBClear(normalizeID, accessLevel, propertyType)
end

---|📘- 获取统计数据
---@return table info  统计信息
function UDK_Property.GetStats()
    -- 使用SwiftDB获取统计信息
    return swiftDBGetStats()
end

---|📘- 检查值是否为数组类型
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
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param propertyName string 属性名称
---@param accessLevel string? 访问级别，默认为Public
---@return boolean exists 是否存在
function UDK_Property.CheckPropertyHasExist(object, propertyType, propertyName, accessLevel)
    local normalizeID = normalizeObjectID(object)
    if not normalizeID or not propertyType or not propertyName then
        return false
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return false
    end

    -- 使用SwiftDB检查属性是否存在
    return swiftDBExists(normalizeID, accessLevel, propertyType, propertyName)
end

---|📘- 获取属性的完整元数据
---
---| 获取属性的完整信息，包括值、创建时间、更新时间
---@param object string | number | {id: string | number} 对象名称
---@param propertyType SupportType | string 属性类型
---@param propertyName string 属性名称
---@param accessLevel string? 访问级别，默认为Public
---@return table? propertyData 属性完整数据 {value, createdAt, updatedAt}
---@return string? error 错误信息
function UDK_Property.GetPropertyData(object, propertyType, propertyName, accessLevel)
    local normalizeID, error = validatePropertyParams(object, propertyType, propertyName, nil, "get")
    if not normalizeID then
        return nil, error
    end

    -- 默认为公开
    accessLevel = accessLevel or UDK_Property.AccessLevel.Public

    -- 验证访问级别
    if not UDK_Property.AccessLevel[accessLevel] then
        return nil, "无效的访问级别: " .. tostring(accessLevel)
    end

    -- 使用SwiftDB获取完整属性数据
    return swiftDBGetPropertyData(normalizeID, accessLevel, propertyType, propertyName)
end

---|📘- 同步服务器权威数据
---
---| `范围`: `服务端`
---
---| `该功能用于在极端情况下客户端数据不同步时，强制同步服务器权威数据`
---@param playerID number? 玩家ID（客户端ID，可选，不填时同步所有玩家）
---@param syncData {object: string | number | {id: string|number}, propertyType: string, propertyName: string, data: any} 同步对象（可选，仅适用于同步单个数据）
function UDK_Property.SyncAuthorityData(playerID, syncData)
    -- 检查是否处于单元测试模式
    if UDK_Property.SyncConf.Status.UnitTestMode then
        if UDK_Property.SyncConf.Status.DebugPrint then
            print("单元测试模式下跳过权威数据同步")
        end
        return
    end

    -- 获取当前环境信息
    local envInfo = envCheck()
    local envType = UDK_Property.SyncConf.EnvType

    -- 仅允许服务器或单机模式下调用
    if envInfo.envID ~= envType.Server.ID and not envInfo.isStandalone then
        if UDK_Property.SyncConf.Status.DebugPrint then
            print("客户端无法调用权威数据同步接口，请在服务器端调用")
        end
        return
    end

    -- 如果提供了syncData，则同步单个属性
    if syncData and syncData.object and syncData.propertyType and syncData.propertyName and syncData.data then
        local normalizeID, errorMsg = validatePropertyParams(syncData.object)
        if not normalizeID then
            return false, errorMsg
        end
        -- 发送网络RPC消息
        local crudType = UDK_Property.SyncConf.CRUD.Sync
        networkRpcMessageSender(crudType, normalizeID, syncData.propertyType,
            syncData.propertyName, syncData.data, UDK_Property.AccessLevel.Public, playerID)
        return
    end

    -- 如果没有提供syncData，则同步所有Public级别的数据
    -- 构建完整数据结构
    local fullData = {}

    -- 遍历所有对象
    for objectId, objectData in pairs(dataStore.data) do
        fullData[objectId] = {}

        -- 遍历所有访问级别
        for accessLevel, levelData in pairs(objectData) do
            -- 只同步Public级别的数据
            if accessLevel == UDK_Property.AccessLevel.Public then
                fullData[objectId][accessLevel] = {}

                -- 遍历所有属性类型
                for propertyType, typeData in pairs(levelData) do
                    fullData[objectId][accessLevel][propertyType] = {}

                    -- 遍历所有属性
                    for propertyName, propertyData in pairs(typeData) do
                        fullData[objectId][accessLevel][propertyType][propertyName] = propertyData.value
                    end
                end
            end
        end

        -- 如果对象没有Public数据，则移除该对象条目
        if next(fullData[objectId]) == nil then
            fullData[objectId] = nil
        end
    end

    -- 发送完整数据同步消息
    local crudType = UDK_Property.SyncConf.CRUD.Sync
    networkRpcMessageSender(crudType, "FULL_DATA_SYNC", "", "", fullData, UDK_Property.AccessLevel.Public, playerID)
end

return UDK_Property
