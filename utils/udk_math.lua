-- ==================================================
-- * UniX SDK - Math
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

local UDK_Math = {}

---|📘- 将输入值转换为百分比
---@param value number 当前进度
---@param min_value number 进度条最小值（推荐0）
---@param max_value number 进度条最大值
---@return number percentage 百分比值
function UDK_Math.ConvertToPercentage(value, min_value, max_value)
    -- 确保数据值在最小值和最大值之间
    if value < min_value then
        value = min_value
    end
    if value > max_value then
        value = max_value
    end

    -- 计算百分比
    local percentage = ((value - min_value) / (max_value - min_value)) * 100

    return percentage
end

---|📘- 将秒数转换为小时、分钟、秒的格式
---@param seconds number 当前秒数
---@param display_hms string? 显示格式，可选值：'hms'、'hm'、'ms'、'h'、'm'、's'，默认为'hms'
---@return string formatted_time 格式化后的时间字符串
function UDK_Math.ConvertSecondsTohms(seconds, display_hms)
    local _hours = math.floor(seconds / 3600)
    local _minutes = math.floor((seconds % 3600) / 60)
    local _seconds = math.floor(seconds % 60)
    local formatted_time

    -- 格式化输出，确保分钟和秒都是两位数
    if display_hms == 'hms' then
        formatted_time = string.format("%02d:%02d:%02d", _hours, _minutes, _seconds)
    elseif display_hms == 'hm' then
        formatted_time = string.format("%02d:%02d", _hours, _minutes)
    elseif display_hms == 'ms' then
        formatted_time = string.format("%02d:%02d", _minutes, _seconds)
    elseif display_hms == 'h' then
        formatted_time = string.format("%02d", _hours)
    elseif display_hms == 'm' then
        formatted_time = string.format("%02d", _minutes)
    elseif display_hms == 's' then
        formatted_time = string.format("%02d", _seconds)
    else
        formatted_time = string.format("%02d:%02d:%02d", _hours, _minutes, _seconds) -- 默认输出 hms 格式
    end

    return formatted_time
end

---|📘- 计算两个向量的距离
---@param Pos_X number 向量X坐标
---@param Pos_Y number 向量Y坐标
---@return number math.sqrt 两个向量的距离
function UDK_Math.CalcSqrt(Pos_X, Pos_Y)
    return math.sqrt(Pos_X * Pos_X + Pos_Y * Pos_Y)
end

---|📘- 指数计算经验需求
---@param base_exp number 基础经验
---@param ratio number 倍率系数
---@param current_level number 当前等级
---@param return_mode string? 数值返回模式，可选值："ceil" | "floor" | "float"，填空默认为"ceil"
---@return number result 计算后的经验需求
function UDK_Math.CalcExpRequire(base_exp, ratio, current_level, return_mode)
    -- 参数有效性校验
    if ratio <= 0 or current_level < 0 then
        error("[UDK:Math] Invalid parameters: ratio must be positive and current_level non-negative")
    end

    local sqrt_ratio = math.sqrt(ratio)
    local result_base_exp = base_exp * sqrt_ratio * current_level
    local result

    -- 统一处理返回模式
    if return_mode == "ceil" then
        result = math.ceil(result_base_exp)
    elseif return_mode == "floor" then
        result = math.floor(result_base_exp)
    elseif return_mode == "float" then
        result = result_base_exp
    else
        -- 默认使用ceil并提示
        result = math.ceil(result_base_exp)
    end

    return result
end

---|📘- 计算数值的百分比
---@param value number 数值
---@param percentage number 百分比
---@param format boolean? 是否格式化结果
---@return number result 计算后的百分比值
function UDK_Math.CalcPercentage(value, percentage, format)
    local result = value * (percentage / 100)
    if format then
        result = tonumber(string.format("%.5f", result))
    end
    return result
end

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

-- 获取当前时间戳
local function getTimestamp()
    -- Lua2.0用不了os.time()
    -- 换成Lua2.0提供的接口生成需要的时间戳
    local serverTime = MiscService:GetServerTimeToTime()
    local timeStamp = MiscService:DateYMDHMSToTime(serverTime) --1702594800
    return math.floor(timeStamp * 1000)
end

-- 等待下一个毫秒
local function waitNextMillis(lastTimestamp)
    local timestamp = getTimestamp()
    while timestamp <= lastTimestamp do
        timestamp = getTimestamp()
    end
    return timestamp
end

---|📘- Snowflake算法生成唯一ID
---@return number id 生成的唯一ID
function UDK_Math.SnowflakeGenerateID()
    local timestamp = getTimestamp()

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
--- @param size string ID长度，默认21
--- @return string
function UDK_Math.NanoIDGenerate(size)
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

---|📘- 62进制编码
---<br>
---| 编码函数：将数字转换为10位62进制字符串
---@param param number 要编码的数值
---@return string 10位62进制字符串
function UDK_Math.EncodeToUID(param)
    local result = ""
    local charset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local num = tonumber(param)

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
---@return number return 解码后的数字
function UDK_Math.DecodeFromUID(uid)
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
    local serverTime = MiscService:GetServerTimeToTime()
    local timeStamp = MiscService:DateYMDHMSToTime(serverTime) --1702594800
    return math.floor(timeStamp * 1000)
end

---|📘- 线性增长算法
---@param base_value number 基础值（次数0时的默认值）
---@param increment_step number 每次递增值（正数）
---@param occurrence_count number 出现次数（≥0）
---@param align_mode string 对齐模式: "round"|"ceil"|"floor"|"none"
---@return number 对齐后的计算结果
function UDK_Math.LinearGrowth(base_value, increment_step, occurrence_count, align_mode)
    -- 参数校验
    if increment_step < 0 or occurrence_count < 0 then
        error("[UDK:Math] Invalid parameters: increment_step and occurrence_count must be non-negative")
    end

    -- 默认值处理
    if occurrence_count == 0 then
        return base_value
    end

    local raw_result = base_value + increment_step * occurrence_count

    -- 对齐处理
    if align_mode == "round" then
        return math.floor(raw_result + 0.5) -- 四舍五入
    elseif align_mode == "ceil" then
        return math.ceil(raw_result)
    elseif align_mode == "floor" then
        return math.floor(raw_result)
    else
        return raw_result -- 原始值输出
    end
end

return UDK_Math
