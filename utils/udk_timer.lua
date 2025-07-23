-- ==================================================
-- * UniX SDK - Timer
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

local UDK_Timer = {}

local timer = {} -- 存储用户标签到系统ID的映射 { [label] = {id = system_id, remaining = time, active = bool} }

-- 获取当前时间戳
local function getTimestamp()
    -- Lua2.0用不了os.time()
    -- 换成Lua2.0提供的接口生成需要的时间戳
    local serverTime = MiscService:GetServerTimeToTime()
    local timeStamp = MiscService:DateYMDHMSToTime(serverTime) --1702594800
    return math.floor(timeStamp * 1000)
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

---|📘- 创建定时器元数据
--- @param label any 用户定义的标签
--- @param timerId number 系统分配的定时器ID
--- @param duration_ms number 初始持续时间（毫秒）
--- @param allowOverride boolean 是否允许覆盖现有标签
local function createTimerMeta(label, timerId, duration_ms, allowOverride)
    if timer[label] and allowOverride then
        -- 销毁旧定时器实例
        local oldMeta = timer[label]
        if oldMeta and oldMeta.id then
            TimerManager:RemoveTimer(oldMeta.id)
            print(string.format("[UDK:Timer] Timer [%s] old instance removed", label))
        end
    end

    if timer[label] and not allowOverride then
        local counter = 1
        while timer[label .. "_" .. counter] do
            counter = counter + 1
        end
        label = label .. "_" .. counter
    end

    timer[label] = {
        id = timerId,
        remaining_ms = duration_ms,
        duration_ms = duration_ms,
        active = true
    }
    return label
end

---|📘- 创建正向计时器
---@param label any 用户定义的标签
---@param duration number 时间值
---@param unit string? 时间单位('s'或'ms')
---@param allowOverride boolean? 是否允许覆盖现有标签
---@return string label 定义的标签
function UDK_Timer.StartForwardTimer(label, duration, unit, allowOverride)
    local timeDelta_ms = 100 -- 时间间隔100ms
    local timerId
    label = label or "forward_" .. nanoIDGenerate(8)
    unit = unit or "s" -- 默认单位为秒

    -- 统一转为毫秒存储
    local duration_ms
    if unit == "s" then
        duration_ms = (duration or 1) * 1000
    else
        duration_ms = duration or 1000
    end

    timerId = TimerManager:AddLoopTimer(timeDelta_ms / 1000,
        function()
            local meta = timer[label]
            meta.remaining_ms = math.max(meta.duration_ms, meta.remaining_ms + timeDelta_ms)
            --print(string.format("%.1f", meta.remaining_ms / 1000))
        end
    )

    createTimerMeta(label, timerId, duration_ms, allowOverride)
    return label
end

---|📘- 创建倒数计时器
---@param label any 用户定义的标签
---@param duration number 时间值
---@param isLoop boolean? 是否循环(默认false)
---@param unit string? 时间单位('s'或'ms')
---@param allowOverride boolean? 是否允许覆盖现有标签
---@return string label 定义的标签
function UDK_Timer.StartBackwardTimer(label, duration, isLoop, unit, allowOverride)
    local timeDelta_ms = 100                                   -- 每次减少的时间(毫秒)
    local timerUUID = label or "backward_" .. nanoIDGenerate() -- 生成一个唯一的定时器ID
    local timerId
    isLoop = isLoop or false

    unit = unit or "s" -- 默认单位为秒

    -- 统一转为毫秒存储
    local duration_ms
    if unit == "s" then
        duration_ms = (duration or 1) * 1000
    else
        duration_ms = duration or 1000
    end

    -- 确保duration_ms是timeDelta_ms的整数倍
    duration_ms = math.floor(duration_ms / timeDelta_ms) * timeDelta_ms

    timerId = TimerManager:AddLoopTimer(timeDelta_ms / 1000, -- 转换为秒
        function()
            local meta = timer[timerUUID]
            -- 使用整数毫秒计算
            meta.remaining_ms = math.max(0, meta.remaining_ms - timeDelta_ms)
            local seconds = meta.remaining_ms / 1000

            -- 格式化显示为1位小数
            -- print(string.format("%.1f", seconds))

            if meta.remaining_ms <= 0 then
                if isLoop == false then
                    TimerManager:PauseTimer(timerId)
                    meta.active = false
                    print(string.format("[UDK:Timer] Timer [%s] stopped at zero", timerUUID))
                else
                    meta.remaining_ms = duration_ms
                    print(string.format("[UDK:Timer] Timer [%s] reset for loop", timerUUID))
                end
            end
        end
    )

    createTimerMeta(timerUUID, timerId, duration_ms, allowOverride)
    return timerUUID
end

---|📘- 获取定时器剩余时间
---@param timerID string|number 定时器名称或ID
---@param unit string? 时间单位('s'或'ms')，默认's'
---@return number?  time 剩余时间(根据unit的值，默认s)
---@return string? errorMessage 错误信息
function UDK_Timer.GetTimerTime(timerID, unit)
    unit = unit or "s" -- 默认单位为秒
    if timer[timerID] then
        if unit == "s" then
            return timer[timerID].remaining_ms / 1000
        else
            return timer[timerID].remaining_ms
        end
    end
    return nil, "Timer not found"
end

function UDK_Timer.PauseTimer(timerID)
    local meta = timer[timerID]
    if meta then
        if meta.active then
            TimerManager:PauseTimer(meta.id)
            meta.active = false
            print(string.format("[UDK:Timer] Timer [%s] paused. ID: %d", timerID, meta.id))
        else
            print(string.format("[UDK:Timer] Timer [%s] already paused", timerID))
        end
    else
        print(string.format("[UDK:Timer] Timer [%s] not found", timerID))
    end
end

---|📘- 恢复计时器
---@param timerID string|number 定时器标签
function UDK_Timer.ResumeTimer(timerID)
    local meta = timer[timerID]
    if meta then
        if not meta.active then
            TimerManager:ResumeTimer(meta.id)
            meta.active = true
            print(string.format("[UDK:Timer] Timer [%s] resumed. ID: %d", timerID, meta.id))
        else
            print(string.format("[UDK:Timer] Timer [%s] already running", timerID))
        end
    else
        print(string.format("[UDK:Timer] Timer [%s] not found", timerID))
    end
end

---|📘- 重置定时器
---@param timerID string|number 定时器名称或ID
---@param duration number 新的持续时间值
---@param unit string? 时间单位('s'或'ms')，默认's'
function UDK_Timer.ResetTimer(timerID, duration, unit)
    local meta = timer[timerID]
    if meta then
        -- 默认单位为秒
        unit = unit or "s"

        if duration then
            -- 转换为毫秒存储
            local newDuration_ms
            if unit == "s" then
                newDuration_ms = duration * 1000
            else
                newDuration_ms = duration
            end

            meta.duration_ms = newDuration_ms
        end

        -- 仅重置剩余时间，保留原有ID和active状态
        meta.remaining_ms = meta.duration_ms

        print(string.format("[UDK:Timer] Timer [%s] reset to %.1f seconds", timerID, meta.duration_ms / 1000))
    else
        print(string.format("[UDK:Timer] Timer [%s] not found for reset", timerID))
    end
end

---|📘- 删除定时器
---@param timerID string|number 定时器名称或ID
function UDK_Timer.RemoveTimer(timerID)
    local meta = timer[timerID]
    if meta then
        TimerManager:RemoveTimer(meta.id)
        timer[timerID] = nil
    end
end

return UDK_Timer
