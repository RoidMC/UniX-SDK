-- ==================================================
-- * UniX SDK - Math
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

local UDK_Math = {}

-- 私有辅助函数：参数验证
local function validateNumber(value, paramName)
    if type(value) ~= "number" then
        error("[UDK:Math] Invalid parameter: " .. paramName .. " must be a number")
    end
end

local function validateNonNegativeNumber(value, paramName)
    validateNumber(value, paramName)
    if value < 0 then
        error("[UDK:Math] Invalid parameter: " .. paramName .. " must be non-negative")
    end
end

local function validatePositiveNumber(value, paramName)
    validateNumber(value, paramName)
    if value <= 0 then
        error("[UDK:Math] Invalid parameter: " .. paramName .. " must be positive")
    end
end

-- 私有辅助函数：格式化结果
local function formatResult(value, format)
    if format ~= nil then
        if type(format) == "boolean" and format then
            -- 默认保留适当位数小数
            return tonumber(string.format("%.5f", value))
        elseif type(format) == "number" and format >= 0 then
            -- 自定义小数位数
            return tonumber(string.format("%." .. math.floor(format) .. "f", value))
        end
    end
    return value
end

-- 获取时间戳
local function getTimeStamp()
    local serverTime = MiscService:GetServerTimeToTime()
    local timeStamp = MiscService:DateYMDHMSToTime(serverTime) --1702594800
    return math.floor(timeStamp * 1000)
end

---|📘- 将数值转换为百分比
---<br>
---| 当只传入一个参数时，将其视为0-100范围内的百分比值
---<br>
---| 当传入两个参数时，计算part在total中的百分比
---@param value number 部分值或百分比值
---@param total number? 总值（可选）
---@param format boolean|number? 是否格式化结果，当为数字时表示保留的小数位数
---@return number result 计算后的百分比值
function UDK_Math.Percentage(value, total, format)
    validateNumber(value, "value")

    local percentage
    if total == nil then
        -- 单参数情况：视为0-100范围内的百分比值
        percentage = value
    else
        -- 双参数情况：计算part在total中的百分比
        validateNumber(total, "total")
        if total == 0 then
            return 0
        end
        percentage = (value / total) * 100
    end

    return formatResult(percentage, format)
end

---|📘- 将秒数转换为小时、分钟、秒的格式
---@param seconds number 当前秒数
---@param displayFormat string? 显示格式，可选值：'hms'、'hm'、'ms'、'h'、'm'、's'，默认为'hms'
---@return string formatted_time 格式化后的时间字符串
function UDK_Math.ConvertSecondsToHMS(seconds, displayFormat)
    validateNonNegativeNumber(seconds, "seconds")

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local formatted_time

    -- 格式化输出，确保分钟和秒都是两位数
    if displayFormat == 'hms' then
        formatted_time = string.format("%02d:%02d:%02d", hours, minutes, secs)
    elseif displayFormat == 'hm' then
        formatted_time = string.format("%02d:%02d", hours, minutes)
    elseif displayFormat == 'ms' then
        formatted_time = string.format("%02d:%02d", minutes, secs)
    elseif displayFormat == 'h' then
        formatted_time = string.format("%02d", hours)
    elseif displayFormat == 'm' then
        formatted_time = string.format("%02d", minutes)
    elseif displayFormat == 's' then
        formatted_time = string.format("%02d", secs)
    else
        formatted_time = string.format("%02d:%02d:%02d", hours, minutes, secs) -- 默认输出 hms 格式
    end

    return formatted_time
end

---|📘- 计算两个点之间的距离
---@param x1 number 第一个点的X坐标
---@param y1 number 第一个点的Y坐标
---@param x2 number 第二个点的X坐标
---@param y2 number 第二个点的Y坐标
---@return number distance 两点之间的距离
function UDK_Math.CalcDistance(x1, y1, x2, y2)
    validateNumber(x1, "x1")
    validateNumber(y1, "y1")
    validateNumber(x2, "x2")
    validateNumber(y2, "y2")

    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

---|📘- 计算经验需求值
---@param baseExp number 基础经验
---@param ratio number 倍率系数
---@param currentLevel number 当前等级
---@param returnMode string? 数值返回模式，可选值："ceil" | "floor" | "float"，默认为"ceil"
---@return number result 计算后的经验需求
function UDK_Math.CalcExpRequirement(baseExp, ratio, currentLevel, returnMode)
    -- 参数有效性校验
    validatePositiveNumber(ratio, "ratio")
    validateNonNegativeNumber(currentLevel, "currentLevel")
    validateNumber(baseExp, "baseExp")

    local sqrt_ratio = math.sqrt(ratio)
    local result_base_exp = baseExp * sqrt_ratio * currentLevel
    local result

    -- 统一处理返回模式
    if returnMode == "ceil" then
        result = math.ceil(result_base_exp)
    elseif returnMode == "floor" then
        result = math.floor(result_base_exp)
    elseif returnMode == "float" then
        result = result_base_exp
    else
        -- 默认使用ceil并提示
        result = math.ceil(result_base_exp)
    end

    return result
end

---|📘- Snowflake算法生成唯一ID
---@return number id 生成的唯一ID
function UDK_Math.SnowflakeGenerateID()
    -- Snowflake算法参数
    local snowflakeEpoch = 1609459200000 -- Snowflake算法的起始时间戳（例如：2021-01-01 00:00:00）
    local datacenterIdBits = 5           -- 数据中心ID占用的位数
    local workerIdBits = 5               -- 机器ID占用的位数
    local sequenceBits = 12              -- 序列号占用的位数

    local maxDatacenterId = 2 ^ datacenterIdBits - 1
    local maxWorkerId = 2 ^ workerIdBits - 1
    local sequenceMask = 2 ^ sequenceBits - 1

    local datacenterId = 0   -- 数据中心ID
    local workerId = 0       -- 机器ID
    local sequence = 0       -- 序列号
    local lastTimestamp = -1 -- 上一次生成ID的时间戳

    -- 等待下一个毫秒
    local function waitNextMillis(lastTimestamp)
        local timestamp = getTimeStamp()
        while timestamp <= lastTimestamp do
            timestamp = getTimeStamp()
        end
        return timestamp
    end

    local timestamp =getTimeStamp()

    if timestamp < lastTimestamp then
        Log:PrintWarning("[UDK:Math] SnowflakeGenerateID: Clock moved backwards. Refusing to generate id.")
        --error("Clock moved backwards. Refusing to generate id.")
    end

    if timestamp == lastTimestamp then
        sequence = (sequence + 1) & sequenceMask
        if sequence == 0 then
            timestamp = waitNextMillis(lastTimestamp)
        end
    else
        sequence = 0
    end

    lastTimestamp = timestamp

    local id = ((timestamp - snowflakeEpoch) << (datacenterIdBits + workerIdBits + sequenceBits)) |
        (datacenterId << (workerIdBits + sequenceBits)) |
        (workerId << sequenceBits) |
        sequence

    return id
end

---|📘- 生成NanoID
--- @param size number ID长度，默认21
--- @return string id 生成的NanoID
function UDK_Math.NanoIDGenerate(size)
    validateNonNegativeNumber(size or 21, "size")

    math.randomseed(getTimeStamp()) -- 初始化随机种子
    size = size or 21
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    local id = ""
    for _ = 1, size do
        local idx = math.random(1, #chars)
        id = id .. chars:sub(idx, idx)
    end
    return id
end

---|📘- 62进制编码
---<br>
---| 编码函数：将数字转换为10位62进制字符串
---@param value number 要编码的数值
---@return string uid 10位62进制字符串
function UDK_Math.EncodeToUID(value)
    validateNonNegativeNumber(value, "value")

    local result = ""
    local charset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local num = tonumber(value)

    -- 特殊情况处理
    if num == 0 then
        return string.rep("0", 10)
    end

    -- 转换为62进制
    while num > 0 do
        local mod = num % 62
        result = string.sub(charset, mod + 1, mod + 1) .. result
        num = math.floor(num / 62)
    end

    -- 补足10位长度
    while string.len(result) < 10 do
        result = "0" .. result
    end

    return result
end

---|📘- 62进制解码
---<br>
---| 解码函数：将10位62进制字符串转换为数字
---@param uid string 10位62进制字符串
---@return number value 解码后的数字
function UDK_Math.DecodeFromUID(uid)
    if type(uid) ~= "string" then
        error("[UDK:Math] Invalid parameter: uid must be a string")
    end

    local result = 0
    local charset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

    -- 校验长度
    if string.len(uid) ~= 10 then
        error("Invalid UID length")
    end

    -- 逐位转换
    for i = 1, 10 do
        local char = string.sub(uid, i, i)
        local pos = string.find(charset, char, 1, true)

        if not pos then
            error("Invalid character in UID: " .. char)
        end

        result = result * 62 + (pos - 1)
    end

    return result
end

---|📘- 获取当前时间戳
---<br>
---| `更新频率`：`秒`
---@return number timestamp 当前时间戳（毫秒）
function UDK_Math.GetTimestamp()
    return getTimeStamp()
end

---|📘- 线性增长算法
---@param baseValue number 基础值（次数0时的默认值）
---@param incrementStep number 每次递增值（正数）
---@param occurrenceCount number 出现次数（≥0）
---@param alignMode string? 对齐模式: "round"|"ceil"|"floor"|"none"，默认为"none"
---@return number result 对齐后的计算结果
function UDK_Math.LinearGrowth(baseValue, incrementStep, occurrenceCount, alignMode)
    -- 参数校验
    validateNumber(baseValue, "baseValue")
    validateNonNegativeNumber(incrementStep, "incrementStep")
    validateNonNegativeNumber(occurrenceCount, "occurrenceCount")

    -- 默认值处理
    if occurrenceCount == 0 then
        return baseValue
    end

    local raw_result = baseValue + incrementStep * occurrenceCount

    -- 对齐处理
    if alignMode == "round" then
        return math.floor(raw_result + 0.5) -- 四舍五入
    elseif alignMode == "ceil" then
        return math.ceil(raw_result)
    elseif alignMode == "floor" then
        return math.floor(raw_result)
    else
        return raw_result -- 原始值输出
    end
end

return UDK_Math
