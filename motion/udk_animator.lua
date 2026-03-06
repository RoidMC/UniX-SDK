-- ==================================================
-- * UniX SDK - Animator
-- * Version: 0.0.4
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

---@class UDK.Animator
local UDK_Animator = {}
local Tween = require("Public.UniX-SDK.lib.tween")
local UAnimator_2DAdapter = require("Public.UniX-SDK.motion.plugins.adapter.2d_adapter") -- 内置2D适配器
local UAnimator_3DAdapter = require("Public.UniX-SDK.motion.plugins.adapter.3d_adapter") -- 内置3D适配器

-- UDK Animator 配置
UDK_Animator.Config = {
    MAX_NESTING_DEPTH = 2,     -- 最大嵌套深度
    DEBUG = false,             -- 是否启用调试日志
    AUTO_STOP_CONFLICT = true, -- 是否自动停止冲突动画
    TickFPS = 60,              -- 动画更新频率（FPS），优先级高于TickDeltaTime
    TickDeltaTime = nil,       -- 可选：直接指定时间间隔（秒），TickFPS 未设置时使用
}

UDK_Animator.Actions = {}     -- 内置动画行为
UDK_Animator.UserActions = {} -- 用户自定义动画行为
-- 获取Action类型
UDK_Animator.ActionType = {
    Both = "Both",       -- 内置和用户自定义
    BuiltIn = "BuiltIn", -- 内置
    User = "User",       -- 用户自定义
}

-- 动画类型
UDK_Animator.AnimType = {}
-- 从适配器中复制支持的动画类型
local function collectSupportTypes()
    -- 从2D适配器中复制
    for key, value in pairs(UAnimator_2DAdapter.SupportType) do
        UDK_Animator.AnimType[key] = value
    end
    -- 从3D适配器中复制（未来扩展用）
    for key, value in pairs(UAnimator_3DAdapter.SupportType) do
        UDK_Animator.AnimType[key] = value
    end
end

-- 初始化收集支持的动画类型
collectSupportTypes()

-- 动画控制器类型
UDK_Animator.AnimControllerType = {
    Sequence = "Sequence", -- 顺序执行
    Parallel = "Parallel", -- 并行执行
}

-- 动画循环类型
UDK_Animator.AnimLoopType = {
    None = 0,     -- 不循环
    Loop = 1,     -- 循环
    PingPong = 2, -- 往返循环
}

-- 动画预设（WIP）
UDK_Animator.AnimPreset = {
}

-- 动画步骤状态
local stepStatus = {
    Idel = "Idel",
    Pending = "Pending",
    Running = "Running",
    Completed = "Completed",
    Cancelled = "Cancelled",
}

-- ==================================================
-- * UDK Animator Utils Code
-- ==================================================

-- 统一日志函数
local function uniLog(type, msg)
    -- 只有 Error 和 Warn 级别，或者 DEBUG 模式开启时才输出 Info 日志
    if type == "Info" and not UDK_Animator.Config.DEBUG then
        return
    end
    local msgTemplate = string.format("[UDK:Animator] %s: %s", type, msg)
    print(msgTemplate)
end

-- 获取当前时间戳
local function getTimeStamp()
    return MiscService:GetServerTimestamp()
end

-- 依赖库检查
if not Tween then
    uniLog("Error", "缺少Tween库，请确保已正确导入Tween库！")
    uniLog("Error", "加载中断，根据SDK实际路径调整Tween库的引入路径！")
    return
end

-- ==================================================
-- * UDK Animator BuiltIn Actions / Init
-- ==================================================
local builtinActionsConfig = {
    UAnimator_2DAdapter.Actions,
    UAnimator_3DAdapter.Actions,
    -- 这里可以添加自定义的硬编码动画行为
    -- CustomFade = function(widgetID, value)
    --     UI:SetTransparency(normalizeWidgetId(widgetID), value)
    -- end,
}

-- 从适配器中注册内置动画行为
local function registerBuiltinActions()
    for _, adapterActions in ipairs(builtinActionsConfig) do
        for name, handler in pairs(adapterActions) do
            UDK_Animator.Actions[name] = handler
        end
    end
    -- 注册硬编码的自定义动画行为
    for name, handler in pairs(builtinActionsConfig) do
        if type(handler) == "function" then
            UDK_Animator.Actions[name] = handler
        end
    end
end

-- 初始化注册内置动画行为
registerBuiltinActions()

-- ==================================================
-- * UDK Animator Swift Database
-- * 基于UDK Proprety Swift DB定制修改
-- ==================================================

local animDataStore = {
    -- 主数据存储 {animId -> {dataType -> {key -> {value, createdAt, updatedAt, isObject}}}}
    data = {},
    -- 统计信息
    stats = {
        totalCount = 0,
        dataTypeCount = {},
        objectCount = 0
    }
}

--- 设置动画数据
---@param animId string 动画实例ID
---@param dataType string 数据类型
---@param key string 键名
---@param data any 数据值
---@param isObject boolean? 是否为对象引用（不进行深度处理）
---@return boolean success 是否成功
local function animDBSet(animId, dataType, key, data, isObject)
    -- 初始化多级存储结构
    animDataStore.data[animId] = animDataStore.data[animId] or {}
    animDataStore.data[animId][dataType] = animDataStore.data[animId][dataType] or {}

    -- 检查是否是新属性
    local isNewProperty = animDataStore.data[animId][dataType][key] == nil

    -- 获取当前时间戳
    local currentTime = getTimeStamp()

    -- 存储完整的数据结构
    if isNewProperty then
        animDataStore.data[animId][dataType][key] = {
            value = data,
            createdAt = currentTime,
            updatedAt = currentTime,
            isObject = isObject or false
        }

        -- 更新统计信息
        animDataStore.stats.totalCount = animDataStore.stats.totalCount + 1
        animDataStore.stats.dataTypeCount[dataType] = (animDataStore.stats.dataTypeCount[dataType] or 0) + 1
        if isObject then
            animDataStore.stats.objectCount = animDataStore.stats.objectCount + 1
        end
    else
        -- 更新现有属性
        local existingData = animDataStore.data[animId][dataType][key]
        existingData.value = data
        existingData.updatedAt = currentTime
        existingData.isObject = isObject or false
    end

    return true
end

--- 批量设置动画数据
---@param animId string 动画实例ID
---@param dataType string 数据类型
---@param dataMap table<string, any> 数据表 {key = value}
---@param isObject boolean? 是否为对象引用
---@return boolean success 是否成功
local function animDBSetBatch(animId, dataType, dataMap, isObject)
    if not dataMap or type(dataMap) ~= "table" then
        return false
    end

    for key, value in pairs(dataMap) do
        animDBSet(animId, dataType, key, value, isObject)
    end

    return true
end

--- 获取动画数据
---@param animId string 动画实例ID
---@param dataType string 数据类型
---@param key string 键名
---@return any? data 数据值
local function animDBGet(animId, dataType, key)
    if animDataStore.data[animId] == nil or
        animDataStore.data[animId][dataType] == nil or
        animDataStore.data[animId][dataType][key] == nil then
        return nil
    end

    return animDataStore.data[animId][dataType][key].value
end

--- 获取动画实例的所有数据
---@param animId string 动画实例ID
---@param dataType string? 数据类型，nil表示获取所有类型
---@return table data 数据表
local function animDBGetAll(animId, dataType)
    if not animDataStore.data[animId] then
        return {}
    end

    local result = {}

    if dataType then
        if animDataStore.data[animId][dataType] then
            for key, data in pairs(animDataStore.data[animId][dataType]) do
                result[key] = data.value
            end
        end
    else
        for dType, dTypeData in pairs(animDataStore.data[animId]) do
            result[dType] = {}
            for key, data in pairs(dTypeData) do
                result[dType][key] = data.value
            end
        end
    end

    return result
end

--- 检查数据是否存在
---@param animId string 动画实例ID
---@param dataType string 数据类型
---@param key string 键名
---@return boolean exists 是否存在
local function animDBExists(animId, dataType, key)
    return animDataStore.data[animId] ~= nil and
        animDataStore.data[animId][dataType] ~= nil and
        animDataStore.data[animId][dataType][key] ~= nil
end

--- 删除动画数据
---@param animId string 动画实例ID
---@param dataType string 数据类型
---@param key string 键名
---@return boolean success 是否成功
local function animDBDelete(animId, dataType, key)
    if not animDataStore.data[animId] or
        not animDataStore.data[animId][dataType] or
        not animDataStore.data[animId][dataType][key] then
        return false
    end

    -- 更新统计信息
    animDataStore.stats.totalCount = animDataStore.stats.totalCount - 1
    animDataStore.stats.dataTypeCount[dataType] = (animDataStore.stats.dataTypeCount[dataType] or 0) - 1
    if animDataStore.data[animId][dataType][key].isObject then
        animDataStore.stats.objectCount = animDataStore.stats.objectCount - 1
    end

    -- 删除数据
    animDataStore.data[animId][dataType][key] = nil

    -- 清理空表
    if next(animDataStore.data[animId][dataType]) == nil then
        animDataStore.data[animId][dataType] = nil
        if next(animDataStore.data[animId]) == nil then
            animDataStore.data[animId] = nil
        end
    end

    return true
end

--- 清理动画实例数据
---@param animId string 动画实例ID
---@param dataType string? 数据类型，nil表示清理所有类型
local function animDBClear(animId, dataType)
    if not animDataStore.data[animId] then
        return
    end

    if dataType then
        if animDataStore.data[animId][dataType] then
            for key, data in pairs(animDataStore.data[animId][dataType]) do
                animDataStore.stats.totalCount = animDataStore.stats.totalCount - 1
                animDataStore.stats.dataTypeCount[dataType] = (animDataStore.stats.dataTypeCount[dataType] or 0) - 1
                if data.isObject then
                    animDataStore.stats.objectCount = animDataStore.stats.objectCount - 1
                end
            end
            animDataStore.data[animId][dataType] = nil

            if next(animDataStore.data[animId]) == nil then
                animDataStore.data[animId] = nil
            end
        end
    else
        for dType, dTypeData in pairs(animDataStore.data[animId]) do
            for key, data in pairs(dTypeData) do
                animDataStore.stats.totalCount = animDataStore.stats.totalCount - 1
                animDataStore.stats.dataTypeCount[dType] = (animDataStore.stats.dataTypeCount[dType] or 0) - 1
                if data.isObject then
                    animDataStore.stats.objectCount = animDataStore.stats.objectCount - 1
                end
            end
        end
        animDataStore.data[animId] = nil
    end
end

--- 获取统计信息
---@return table info 统计信息
local function animDBGetStats()
    return {
        totalCount = animDataStore.stats.totalCount,
        dataTypeCount = animDataStore.stats.dataTypeCount,
        objectCount = animDataStore.stats.objectCount
    }
end

-- ==================================================
-- * UDK Animator Core - Adapter
-- ==================================================

--- 获取动画属性的初始值
---@param step table 动画步骤
---@param targets table 目标列表
---@return any value 初始值
local function getInitialValue(step, targets)
    local target = targets[1]
    if not target then return nil end

    -- 优先使用 target.type，其次使用 targetType，默认 UI
    local targetType = target.type or step.targetType or "UI"

    -- 根据动画类型获取初始值
    local initialValue = UAnimator_2DAdapter.GetInitialValue(step, target, targetType)

    return nil or initialValue
end

-- ==================================================
-- * UDK Animator Core - TimelineBuilder
-- ==================================================

--- 构建时间轴
--- @param steps table 动画步骤列表
--- @param baseTime number 基础时间（用于嵌套序列）
--- @param parentStepID string? 父步骤ID
--- @param mode string? 执行模式: "Sequence" 或 "Parallel"
--- @param parentStepCounter number? 父级步骤计数器（用于生成嵌套轨道ID）
--- @param nestingDepth number? 嵌套深度（用于警告）
--- @return table timeline 构建的时间轴对象
local function buildTimeline(steps, baseTime, parentStepID, mode, parentStepCounter, nestingDepth)
    uniLog("Info", string.format("buildTimeline调用: mode参数=%s", mode))
    mode = mode or "Sequence" -- 默认为序列执行
    uniLog("Info", string.format("buildTimeline: 处理后mode=%s", mode))

    -- 检查嵌套深度
    local currentDepth = (nestingDepth or 0) + 1
    if currentDepth > UDK_Animator.Config.MAX_NESTING_DEPTH then
        uniLog("Warn", string.format(
            "嵌套深度超过建议值：%d（最大建议：%d），可能导致调试困难和性能问题",
            currentDepth, UDK_Animator.Config.MAX_NESTING_DEPTH))
    end

    local currentTime = baseTime
    local timeline = {
        tracks = {},     -- 轨道列表
        events = {},     -- 时间轴事件
        duration = 0,    -- 总时长
        rootStepID = nil -- 根步骤ID
    }

    if not steps or #steps == 0 then
        return timeline
    end

    local stepCounter = 0
    local processStep

    processStep = function(step, stepParentID, offsetTime)
        stepCounter = stepCounter + 1
        -- 根据是否有父级步骤计数器来生成不同的 stepID 格式
        local stepID
        if parentStepCounter then
            -- 嵌套轨道：step_父级_子级
            stepID = string.format("step_%d_%d", parentStepCounter, stepCounter)
        else
            -- 顶级轨道：step_序号
            stepID = string.format("step_%d", stepCounter)
        end

        if not timeline.rootStepID then
            timeline.rootStepID = stepID
        end

        -- 嵌套steps的处理
        if step.steps then
            local nestedMode = step.mode or mode -- 使用嵌套steps的mode或继承父级mode
            -- 传入当前的 stepCounter 作为父级计数器和当前嵌套深度
            local nestedTimeline = buildTimeline(step.steps, offsetTime, stepID, nestedMode, stepCounter, currentDepth)
            for _, track in ipairs(nestedTimeline.tracks) do
                table.insert(timeline.tracks, track)
            end
            for _, event in ipairs(nestedTimeline.events) do
                table.insert(timeline.events, event)
            end
            if nestedTimeline.duration > timeline.duration then
                timeline.duration = nestedTimeline.duration
            end
            return offsetTime
        end

        -- 正常动画步骤处理
        if step.type and step.duration then
            -- 处理playRange参数：[delayStart, totalAxisLength]
            local playRange = step.timeline and step.timeline.playRange
            local delayStart = 0
            local totalAxisLength = step.duration

            if playRange then
                if type(playRange) == "number" then
                    -- playRange 是单个数字：总轴长度
                    totalAxisLength = playRange
                elseif type(playRange) == "table" and #playRange >= 2 then
                    -- playRange 是数组：[delayStart, totalAxisLength]
                    delayStart = playRange[1] or 0
                    totalAxisLength = playRange[2] or step.duration
                end
            end

            uniLog("Info",
                string.format(
                    "  处理step: type=%s, offsetTime=%.2f, delayStart=%.2f, totalAxisLength=%.2f, animDuration=%.2f, mode=%s",
                    step.type, offsetTime, delayStart, totalAxisLength, step.duration, mode))

            -- 计算开始时间和结束时间
            -- Parallel 模式下忽略 delayStart，所有动画从 offsetTime 开始
            local startTime = offsetTime
            if mode == "Parallel" then
                startTime = offsetTime
            else
                startTime = offsetTime + delayStart
            end
            local endTime = startTime + totalAxisLength

            if endTime > timeline.duration then
                timeline.duration = endTime
            end

            -- 创建轨道
            local track = {
                trackId = stepID,
                parentStepID = stepParentID,
                type = step.type,
                targets = step.targets or {},
                targetType = step.targetType or "UI",
                from = step.from,
                to = step.to,
                animDuration = step.duration,      -- 单次动画的实际时长
                totalAxisLength = totalAxisLength, -- 时间轴内的总长度
                startTime = startTime,
                endTime = endTime,
                easing = step.easing or "linear",
                timeline = step.timeline or {},
                callbacks = step.callbacks or {},
                -- animRepeat 配置
                animRepeat = step.timeline and step.timeline.animRepeat
            }

            table.insert(timeline.tracks, track)

            -- 注册回调事件
            if step.callbacks then
                if step.callbacks.onStart then
                    table.insert(timeline.events, {
                        time = startTime,
                        eventId = stepID .. "_onStart",
                        callback = step.callbacks.onStart
                    })
                end
                if step.callbacks.onComplete then
                    table.insert(timeline.events, {
                        time = endTime,
                        eventId = stepID .. "_onComplete",
                        callback = step.callbacks.onComplete
                    })
                end
            end

            -- 返回下一个步骤的开始时间
            if mode == "Parallel" then
                -- 并行模式：所有轨道在同一时间开始
                return offsetTime
            else
                -- 序列模式：下一个轨道在当前轨道结束后开始
                return endTime
            end
        end

        return offsetTime
    end

    -- 处理所有步骤
    uniLog("Info", string.format("处理步骤前: mode=%s, steps数量=%d", mode, #steps))
    if mode == "Parallel" then
        -- 并行模式：所有步骤从同一时间开始
        uniLog("Info", "进入Parallel模式")
        for _, step in ipairs(steps) do
            processStep(step, parentStepID, baseTime)
        end
    else
        -- 序列模式：步骤按顺序执行
        uniLog("Info", string.format("进入Sequence模式, mode=%s", mode))
        for _, step in ipairs(steps) do
            currentTime = processStep(step, parentStepID, currentTime)
        end
    end

    -- 调试：打印timeline信息
    uniLog("Info",
        string.format("Timeline构建完成: mode=%s, 总时长=%.2f, 轨道数=%d", mode or "Sequence", timeline.duration, #timeline.tracks))
    for i, track in ipairs(timeline.tracks) do
        uniLog("Info",
            string.format("  轨道%d: type=%s, startTime=%.2f, endTime=%.2f", i, track.type, track.startTime, track.endTime))
    end

    return timeline
end

-- ==================================================
-- * UDK Animator Core - StepScheduler
-- ==================================================

local activeSchedulers = {} -- {animId -> scheduler}
local schedulerTimer = nil

--- 创建调度器
--- @param animID string 动画ID
--- @param timeline table 时间轴对象
--- @return table scheduler 调度器对象
local function createScheduler(animID, timeline)
    return {
        animId = animID,
        timeline = timeline,
        currentTime = 0,
        playhead = 0,
        speed = 1.0,
        status = stepStatus.Idel,
        paused = false,
        activeTracks = {},    -- 当前活跃的轨道 {trackId -> trackState}
        triggeredEvents = {}, -- 已触发的事件索引
        onComplete = nil      -- 整体完成回调
    }
end

--- 启动调度器
--- @param scheduler table 调度器对象
local function startScheduler(scheduler)
    scheduler.status = stepStatus.Running
    scheduler.paused = false
    scheduler.currentTime = 0
    scheduler.playhead = 0
    scheduler.activeTracks = {}
    scheduler.triggeredEvents = {}

    -- 初始化所有轨道状态
    for _, track in ipairs(scheduler.timeline.tracks) do
        scheduler.activeTracks[track.trackId] = {
            track = track,
            started = false,
            completed = false,
            currentValue = nil,
            repeatCount = 0,
            currentDirection = 1,
            cycleStartTime = nil,
            cycleEndTime = nil,
            waitingForDelay = false,
            animCompleted = false -- 标记动画播放是否完成（即使总轴还在计时）
        }
    end
end

--- 暂停调度器
--- @param scheduler table 调度器对象
local function pauseScheduler(scheduler)
    if scheduler.status == stepStatus.Running then
        scheduler.paused = true
        scheduler.status = stepStatus.Pending
    end
end

--- 恢复调度器
--- @param scheduler table 调度器对象
local function resumeScheduler(scheduler)
    if scheduler.status == stepStatus.Pending then
        scheduler.paused = false
        scheduler.status = stepStatus.Running
    end
end

--- 停止调度器
--- @param scheduler table 调度器对象
local function stopScheduler(scheduler)
    scheduler.status = stepStatus.Completed
    scheduler.paused = false
    scheduler.activeTracks = {}

    -- 触发完成回调
    if scheduler.onComplete then
        scheduler.onComplete()
    end
end

--- 应用缓动函数
--- @param currentTime number 当前时间
--- @param duration number 持续时间
--- @param easing string 缓动函数名称
--- @return number t 归一化时间 [0, 1]
local function getNormalizedTime(currentTime, duration, easing)
    if duration <= 0 then
        return 1
    end

    local t = currentTime / duration
    t = math.max(0, math.min(1, t))

    return t
end

--- 值插值
--- @param from any 起始值
--- @param to any 目标值
--- @param currentTime number 当前时间
--- @param duration number 持续时间
--- @param easing string 缓动函数名称
--- @return any interpolatedValue 插值结果
local function interpolateValue(from, to, currentTime, duration, easing)
    -- 缓动函数别名映射（兼容常见的命名习惯）
    local easingAliasMap = {
        ["easeOutQuad"] = "outQuad",
        ["easeInQuad"] = "inQuad",
        ["easeInOutQuad"] = "inOutQuad",
        ["easeOutCubic"] = "outCubic",
        ["easeInCubic"] = "inCubic",
        ["easeInOutCubic"] = "inOutCubic",
        ["easeOutQuart"] = "outQuart",
        ["easeInQuart"] = "inQuart",
        ["easeInOutQuart"] = "inOutQuart",
        ["easeOutQuint"] = "outQuint",
        ["easeInQuint"] = "inQuint",
        ["easeInOutQuint"] = "inOutQuint",
        ["easeOutSine"] = "outSine",
        ["easeInSine"] = "inSine",
        ["easeInOutSine"] = "inOutSine",
        ["easeOutExpo"] = "outExpo",
        ["easeInExpo"] = "inExpo",
        ["easeInOutExpo"] = "inOutExpo",
        ["easeOutCirc"] = "outCirc",
        ["easeInCirc"] = "inCirc",
        ["easeInOutCirc"] = "inOutCirc",
        ["easeOutElastic"] = "outElastic",
        ["easeInElastic"] = "inElastic",
        ["easeInOutElastic"] = "inOutElastic",
        ["easeOutBack"] = "outBack",
        ["easeInBack"] = "inBack",
        ["easeInOutBack"] = "inOutBack",
        ["easeOutBounce"] = "outBounce",
        ["easeInBounce"] = "inBounce",
        ["easeInOutBounce"] = "inOutBounce",
        ["linear"] = "linear"
    }

    -- 获取缓动函数
    local easingFunc
    if type(easing) == "string" then
        -- 先尝试直接获取
        easingFunc = Tween.easing and Tween.easing[easing]
        -- 如果失败，尝试别名映射
        if not easingFunc then
            local mappedName = easingAliasMap[easing]
            easingFunc = Tween.easing and Tween.easing[mappedName]
        end
    elseif type(easing) == "function" then
        easingFunc = easing
    end

    -- 如果没有缓动函数，使用线性
    if not easingFunc then
        easingFunc = Tween.easing and Tween.easing.linear
    end

    -- Hex 颜色插值
    if type(from) == "string" and type(to) == "string" then
        -- 简单的 Hex 颜色插值（格式: #RRGGBB）
        local function hexToRgb(hex)
            hex = string.lower(string.gsub(hex, "#", ""))
            local r = tonumber(string.sub(hex, 1, 2), 16)
            local g = tonumber(string.sub(hex, 3, 4), 16)
            local b = tonumber(string.sub(hex, 5, 6), 16)
            return { r = r, g = g, b = b }
        end

        local function rgbToHex(rgb)
            return string.format("#%02x%02x%02x", rgb.r, rgb.g, rgb.b)
        end

        local fromRgb = hexToRgb(from)
        local toRgb = hexToRgb(to)

        local t = getNormalizedTime(currentTime, duration, easing)
        local result = {
            r = fromRgb.r + (toRgb.r - fromRgb.r) * t,
            g = fromRgb.g + (toRgb.g - fromRgb.g) * t,
            b = fromRgb.b + (toRgb.b - fromRgb.b) * t
        }

        return rgbToHex({
            r = math.floor(result.r + 0.5),
            g = math.floor(result.g + 0.5),
            b = math.floor(result.b + 0.5)
        })
    end

    if type(from) == "number" and type(to) == "number" then
        if easingFunc then
            local result = easingFunc(currentTime, from, to - from, duration)
            return result
        else
            local t = getNormalizedTime(currentTime, duration, easing)
            return from + (to - from) * t
        end
    elseif type(from) == "table" and type(to) == "table" then
        local result = {}
        for k, v in pairs(to) do
            if type(from[k]) == "number" then
                if easingFunc then
                    result[k] = easingFunc(currentTime, from[k], v - from[k], duration)
                else
                    local t = getNormalizedTime(currentTime, duration, easing)
                    result[k] = from[k] + (v - from[k]) * t
                end
            else
                result[k] = v
            end
        end
        return result
    end

    return to
end

--- 应用轨道值到目标
--- @param track table 轨道对象
--- @param value any 值
local function applyTrackValue(track, value)
    local actionHandler = UDK_Animator.Actions[track.type]

    if not actionHandler then
        actionHandler = UDK_Animator.UserActions[track.type]
    end

    if actionHandler then
        for _, target in ipairs(track.targets) do
            actionHandler(target.id, value)
        end
    end
end

--- 将轨道重置为默认状态
--- @param track table 轨道对象
local function resetTrackToDefault(track)
    local defaultValue = getInitialValue(track, track.targets)
    if defaultValue ~= nil then
        for _, target in ipairs(track.targets) do
            applyTrackValue(track, defaultValue)
        end
    end
end

--- 更新单个轨道
--- @param scheduler table 调度器对象
--- @param track table 轨道对象
--- @param trackState table 轨道状态
--- @param currentTime number 当前时间
local function updateTrack(scheduler, track, trackState, currentTime)
    if trackState.completed then
        return
    end

    -- 检查轨道是否开始
    if not trackState.started then
        if currentTime >= track.startTime then
            trackState.started = true

            -- 初始化循环状态
            trackState.repeatCount = 0
            trackState.currentDirection = 1
            trackState.cycleStartTime = track.startTime
            trackState.cycleEndTime = track.startTime + track.animDuration

            uniLog("Info",
                string.format("轨道 %s 开始, totalAxisLength=%.2f, animDuration=%.2f", track.trackId, track.totalAxisLength,
                    track.animDuration))

            -- 安全触发onStart回调
            if track.callbacks.onStart then
                local success, err = xpcall(track.callbacks.onStart, function(err)
                    uniLog("Error", string.format("轨道 %s 的 onStart 回调出错: %s", track.trackId, err))
                end)
                if not success then
                    trackState.completed = true
                    return
                end
            end
        else
            return
        end
    end

    -- 检查是否超过总轴长度（仅对无限循环模式有效）
    if currentTime >= track.endTime and track.animRepeat and track.animRepeat.mode == UDK_Animator.AnimLoopType.Loop then
        trackState.completed = true

        -- 应用目标值作为最终值（兜底）
        local success, err = xpcall(function()
            applyTrackValue(track, track.to or trackState.currentValue)
        end, function(err)
            uniLog("Error", string.format("轨道 %s playRange强制停止出错: %s", track.trackId, err))
        end)

        -- 无限循环模式：到达总轴长度时调用 onComplete（兜底）
        if track.callbacks.onComplete then
            uniLog("Info", string.format("轨道 %s 无限循环到达总轴长度,调用 onComplete (兜底)", track.trackId))
            local success, err = xpcall(track.callbacks.onComplete, function(err)
                uniLog("Error", string.format("轨道 %s playRange停止回调出错: %s", track.trackId, err))
            end)
        end

        uniLog("Info", string.format("轨道 %s 到达总轴长度,强制结束", track.trackId))
        return
    end

    -- 检查是否在循环延迟等待中
    if trackState.waitingForDelay then
        if currentTime >= trackState.cycleStartTime then
            -- 延迟结束,开始新的循环
            trackState.waitingForDelay = false
            trackState.cycleStartTime = currentTime
            trackState.cycleEndTime = currentTime + track.animDuration

            uniLog("Info", string.format("轨道 %s 开始第%d次循环 (延迟后)", track.trackId, trackState.repeatCount + 1))
        else
            -- 还在等待延迟中
            return
        end
    end

    -- 检查当前动画周期是否完成
    if currentTime >= trackState.cycleEndTime then
        local animRepeat = track.animRepeat

        -- 每次周期完成都调用一次 onComplete
        if track.callbacks.onComplete then
            local success, err = xpcall(track.callbacks.onComplete, function(err)
                uniLog("Error", string.format("轨道 %s 的 onComplete 回调出错: %s", track.trackId, err))
            end)
        end

        -- 检查是否需要循环
        local shouldLoop = animRepeat and (
            animRepeat.mode == UDK_Animator.AnimLoopType.Loop or
            (animRepeat.count > 0 and trackState.repeatCount < animRepeat.count)
        )

        if shouldLoop then
            -- 循环模式：继续下一轮
            trackState.repeatCount = trackState.repeatCount + 1

            -- PingPong 模式反转方向
            if animRepeat.mode == UDK_Animator.AnimLoopType.PingPong then
                trackState.currentDirection = -trackState.currentDirection
            end

            -- 进入延迟等待
            local delay = animRepeat.delay or 0
            if delay > 0 then
                trackState.waitingForDelay = true
                trackState.cycleStartTime = currentTime + delay
                uniLog("Info", string.format("轨道 %s 完成第%d次循环,延迟%.2f秒", track.trackId, trackState.repeatCount, delay))
                return
            else
                -- 无延迟,立即开始新周期
                trackState.cycleStartTime = currentTime
                trackState.cycleEndTime = currentTime + track.animDuration
                uniLog("Info", string.format("轨道 %s 完成第%d次循环,立即开始下一轮", track.trackId, trackState.repeatCount))
            end
        else
            -- 没有循环配置或循环次数已用完,整个序列完成
            trackState.completed = true -- 直接标记为完成，不需要等待总轴长度
            return
        end
    end

    -- 如果轨道已完成，跳过后续处理
    if trackState.completed then
        return
    end

    -- 计算当前周期的相对时间
    local relativeTime = currentTime - trackState.cycleStartTime

    -- 获取初始值
    local fromValue = track.from
    if fromValue == nil then
        fromValue = getInitialValue(track, track.targets)
        if fromValue ~= nil then
            trackState.currentValue = fromValue
        end
    end

    if fromValue and track.to then
        -- PingPong 模式: 反向时交换 from 和 to
        local effectiveFrom = fromValue
        local effectiveTo = track.to

        if trackState.currentDirection < 0 then
            effectiveFrom = track.to
            effectiveTo = fromValue
        end

        -- 插值计算当前值
        trackState.currentValue = interpolateValue(effectiveFrom, effectiveTo, relativeTime, track.animDuration,
            track.easing)

        -- 安全应用值到目标
        local success, err = xpcall(function()
            applyTrackValue(track, trackState.currentValue)
        end, function(err)
            uniLog("Error", string.format("轨道 %s 应用值出错: %s", track.trackId, err))
        end)
        if not success then
            trackState.completed = true
            return
        end

        -- 安全触发onUpdate回调
        local progress = relativeTime / track.animDuration
        progress = math.max(0, math.min(1, progress))
        if track.callbacks.onUpdate then
            local success, err = xpcall(function()
                track.callbacks.onUpdate(progress, trackState.currentValue)
            end, function(err)
                uniLog("Error", string.format("轨道 %s 的 onUpdate 回调出错: %s", track.trackId, err))
            end)
        end
    end
end

--- 更新调度器
--- @param scheduler table 调度器对象
--- @param deltaTime number 时间增量(秒)
local function updateScheduler(scheduler, deltaTime)
    if scheduler.paused or scheduler.status ~= stepStatus.Running then
        return
    end

    -- 更新播放头
    scheduler.currentTime = scheduler.currentTime + deltaTime * scheduler.speed
    scheduler.playhead = scheduler.currentTime

    -- 安全更新所有轨道
    local allTracksCompleted = true
    local updateSuccess, updateErr = xpcall(function()
        for _, track in ipairs(scheduler.timeline.tracks) do
            local trackState = scheduler.activeTracks[track.trackId]
            if trackState then
                updateTrack(scheduler, track, trackState, scheduler.currentTime)
                if not trackState.completed then
                    allTracksCompleted = false
                end
            end
        end
    end, function(err)
        uniLog("Error", string.format("动画 %s 更新轨道时出错: %s", scheduler.animId, err))
    end)

    if not updateSuccess then
        stopScheduler(scheduler)
        return
    end

    -- 检查是否完成（所有轨道完成或时间轴时长已到）
    if allTracksCompleted or scheduler.currentTime >= scheduler.timeline.duration then
        stopScheduler(scheduler)
        return
    end
end

--- 启动或停止全局定时器
local updateLock = false  -- 防止递归调用
local lastFrameTime = 0   -- 上一帧时间戳（毫秒）
local timeAccumulator = 0 -- 时间累积器
local function updateGlobalTimer()
    if schedulerTimer then
        TimerManager:RemoveTimer(schedulerTimer)
        schedulerTimer = nil
    end

    if next(activeSchedulers) ~= nil then
        -- 重置时间状态
        timeAccumulator = 0
        lastFrameTime = getTimeStamp()

        schedulerTimer = TimerManager:AddLoopFrame(1, function()
            -- Lock 防止递归调用
            if updateLock then
                return
            end

            updateLock = true

            -- 计算实际帧时间（毫秒 -> 秒）
            local currentTime = getTimeStamp()
            local deltaTime = (currentTime - lastFrameTime) / 1000
            lastFrameTime = currentTime

            -- 限制最大 deltaTime 防止卡顿跳跃
            deltaTime = math.min(deltaTime, 0.1)

            -- 时间累积控制
            timeAccumulator = timeAccumulator + deltaTime
            local fixedDt = (UDK_Animator.Config.TickDeltaTime or (1 / UDK_Animator.Config.TickFPS))

            while timeAccumulator >= fixedDt do
                local animIdsToRemove = {}

                -- 安全遍历所有调度器
                for animId, scheduler in pairs(activeSchedulers) do
                    if scheduler.status == stepStatus.Completed then
                        table.insert(animIdsToRemove, animId)
                    else
                        -- 单个调度器的更新出错不影响其他调度器
                        local success, err = xpcall(function()
                            updateScheduler(scheduler, fixedDt)
                        end, function(err)
                            uniLog("Error", string.format("动画调度器 %s 出错: %s，自动停止该动画", animId, err))
                        end)

                        if not success then
                            -- 出错的调度器标记为移除
                            table.insert(animIdsToRemove, animId)
                        end
                    end
                end

                -- 清理完成的或出错的调度器
                for _, animId in ipairs(animIdsToRemove) do
                    activeSchedulers[animId] = nil
                end

                -- 减去固定步长
                timeAccumulator = timeAccumulator - fixedDt
            end

            updateLock = false

            -- 如果没有活动的调度器，停止全局定时器
            if next(activeSchedulers) == nil then
                timeAccumulator = 0
                updateGlobalTimer()
            end
        end)
    end
end

-- ==================================================
-- * UDK Animator Core
-- ==================================================

local function generateAnimId()
    return string.format("anim_%d_%d", getTimeStamp(), math.random(10000, 99999))
end

--- 运行动画
--- @param animId string 动画ID
--- @param animSequence table 动画序列配置
--- @return boolean success 是否成功
local function run(animId, animSequence)
    -- 构建时间轴
    local mode = animSequence.mode or "Sequence"
    uniLog("Info", string.format("run函数: 接收到的mode=%s", mode))
    local timeline = buildTimeline(animSequence.steps, 0, nil, mode)

    -- 创建调度器
    local scheduler = createScheduler(animId, timeline)

    -- 存储到数据库
    animDBSet(animId, "Scheduler", "data", scheduler, true)
    animDBSet(animId, "Timeline", "data", timeline, true)

    -- 启动调度器
    startScheduler(scheduler)

    -- 注册到活动调度器列表
    activeSchedulers[animId] = scheduler

    -- 启动全局定时器
    updateGlobalTimer()

    return true
end

---|📘- 动画构建器
---@param animSequence table 动画序列
function UDK_Animator.AnimBuilder(animSequence)
    if not animSequence then
        uniLog("Error", "动画序列不能为空")
        return false
    end
end

---|📘- 动画播放
---@param animSequence table 动画序列
---@return string animId 动画实例ID
function UDK_Animator.AnimPlay(animSequence)
    if not animSequence then
        uniLog("Error", "动画序列不能为空")
        return nil
    end

    uniLog("Info", string.format("AnimPlay: animSequence.mode=%s", animSequence.mode))

    -- 检测并停止冲突动画
    if UDK_Animator.Config.AUTO_STOP_CONFLICT and animSequence.tracks then
        local stoppedAnimIds = {}
        for _, track in ipairs(animSequence.tracks) do
            for _, target in ipairs(track.targets) do
                -- 检查所有正在运行的动画，查找冲突
                for animId, scheduler in pairs(activeSchedulers) do
                    if scheduler.timeline then
                        for _, runningTrack in ipairs(scheduler.timeline.tracks) do
                            -- 检查是否冲突：相同目标 + 相同类型
                            for _, runningTarget in ipairs(runningTrack.targets) do
                                if runningTarget.id == target.id and runningTrack.type == track.type then
                                    -- 停止冲突动画
                                    if not stoppedAnimIds[animId] then
                                        uniLog("Info", string.format(
                                            "检测到冲突动画 %s（目标=%s, 类型=%s），停止并重置为默认状态",
                                            animId, target.id, track.type))

                                        -- 重置为默认状态
                                        resetTrackToDefault(runningTrack)

                                        -- 停止动画
                                        UDK_Animator.AnimStop(animId)
                                        stoppedAnimIds[animId] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local animId = generateAnimId()

    -- 使用animDB存储动画配置
    animDBSet(animId, "Config", "sequence", animSequence, true)

    -- 运行动画
    local success = run(animId, animSequence)

    if not success then
        uniLog("Error", string.format("动画 '%s' 启动失败", animId))
        return nil
    end

    return animId
end

---|📘- 停止动画
---@param animId string 动画实例ID
---@return boolean isSuccess 是否成功停止动画
function UDK_Animator.AnimStop(animId)
    -- 检查动画是否存在
    if not animDBExists(animId, "Config", "sequence") then
        uniLog("Error", string.format("动画实例 '%s' 不存在", animId))
        return false
    end

    -- 停止调度器
    local scheduler = activeSchedulers[animId]
    if scheduler then
        stopScheduler(scheduler)
        activeSchedulers[animId] = nil
    end

    -- 更新全局定时器
    updateGlobalTimer()

    -- 清理动画数据
    animDBClear(animId)

    return true
end

---|📘- 暂停动画
---@param animId string 动画实例ID
---@return boolean isSuccess 是否成功暂停动画
function UDK_Animator.AnimPause(animId)
    -- 检查动画是否存在
    if not animDBExists(animId, "Config", "sequence") then
        uniLog("Error", string.format("动画实例 '%s' 不存在", animId))
        return false
    end

    -- 暂停调度器
    local scheduler = activeSchedulers[animId]
    if scheduler then
        pauseScheduler(scheduler)
        return true
    end

    return false
end

---|📘- 恢复动画
---@param animId string 动画实例ID
---@return boolean isSuccess 是否成功恢复动画
function UDK_Animator.AnimResume(animId)
    -- 检查动画是否存在
    if not animDBExists(animId, "Config", "sequence") then
        uniLog("Error", string.format("动画实例 '%s' 不存在", animId))
        return false
    end

    -- 恢复调度器
    local scheduler = activeSchedulers[animId]
    if scheduler then
        resumeScheduler(scheduler)
        return true
    end

    return false
end

---|📘- 重置动画到默认状态
---@param animId string 动画实例ID
---@return boolean isSuccess 是否成功重置动画
function UDK_Animator.AnimReset(animId)
    -- 检查动画是否存在
    if not animDBExists(animId, "Config", "sequence") then
        uniLog("Error", string.format("动画实例 '%s' 不存在", animId))
        return false
    end

    -- 获取原始配置
    local config = animDBGet(animId, "Config", "sequence")

    -- 停止并重新播放
    UDK_Animator.AnimStop(animId)
    local newAnimId = UDK_Animator.AnimPlay(config)

    return newAnimId ~= nil
end

---|📘- 清空动画
---@param animId string 动画实例ID
---@return boolean isSuccess 是否成功清空动画
function UDK_Animator.AnimClear(animId)
    -- 检查动画是否存在
    if not animDBExists(animId, "Config", "sequence") then
        uniLog("Error", string.format("动画实例 '%s' 不存在", animId))
        return false
    end

    -- 停止动画
    UDK_Animator.AnimStop(animId)
    -- 清理动画数据
    animDBClear(animId)

    return true
end

---|📘- 注册动画行为
---@param name string 动画行为名称
---@param handler function 动画行为处理函数
---@param options table? 可选配置参数，支持 force: boolean 强制覆盖内置行为
function UDK_Animator.RegisterAction(name, handler, options)
    options = options or {}

    -- 检查是否覆盖内置 Action
    if UDK_Animator.Actions[name] and not options.force then
        uniLog("Error",
            string.format("无法注册行为 '%s' - 与内置行为冲突，请使用RegisterAction('%s', handler, { force = true })来覆盖", name, name))
        return false
    end

    -- 强制覆盖时警告
    if UDK_Animator.Actions[name] and options.force then
        uniLog("Warn", string.format("您已强制覆盖内置行为 '%s'，这可能会破坏核心功能。", name))
    end

    UDK_Animator.UserActions[name] = handler
    return true
end

---|📘- 注销动画行为
---@param name string 动画行为名称
---@return boolean success 是否成功注销
function UDK_Animator.UnRegisterAction(name)
    -- 不存在用户 Action
    if not UDK_Animator.UserActions[name] then
        -- 尝试注销内置 Action
        if UDK_Animator.Actions[name] then
            uniLog("Error", string.format("无法取消注册内置行为 '%s'，内置行为是只读的！", name))
        else
            uniLog("Error", string.format("无法取消注册行为 '%s'，用户定义行为不存在！", name))
        end
        return false
    end

    UDK_Animator.UserActions[name] = nil
    return true
end

---|📘- 获取动画行为
---@param name string 动画行为名称
---@param actionType string 可选，ActionType.BuiltIn | ActionType.User | ActionType.Both(默认)
---@return function|nil handler 动画行为处理函数
---@return string|nil type 动画行为类型："User" | "BuiltIn" | nil
function UDK_Animator.GetAction(name, actionType)
    actionType = actionType or UDK_Animator.ActionType.Both

    if actionType == UDK_Animator.ActionType.User then
        return UDK_Animator.UserActions[name],
            UDK_Animator.UserActions[name] and "User" or nil
    elseif actionType == UDK_Animator.ActionType.BuiltIn then
        return UDK_Animator.Actions[name],
            UDK_Animator.Actions[name] and "BuiltIn" or nil
    elseif actionType == UDK_Animator.ActionType.Both then
        if UDK_Animator.UserActions[name] then
            return UDK_Animator.UserActions[name], "User"
        elseif UDK_Animator.Actions[name] then
            return UDK_Animator.Actions[name], "BuiltIn"
        end
        return nil, nil
    else
        uniLog("Error",
            string.format("无效的 actionType '%s'，请使用 ActionType.BuiltIn | ActionType.User | ActionType.Both", actionType))
    end
end

---|📘- 检查是否存在动画行为
---@param name string 动画行为名称
---@return boolean hasAction 是否存在动画行为
---@return string|nil type 动画行为类型："User" | "BuiltIn" | nil
function UDK_Animator.HasAction(name)
    if UDK_Animator.UserActions[name] then
        return true, "User"
    elseif UDK_Animator.Actions[name] then
        return true, "BuiltIn"
    end
    return false, nil
end

---|📘- 检查是否为内置动画行为
---@param name string 动画行为名称
---@return boolean isBuiltInAction 是否为内置动画行为
function UDK_Animator.IsBuiltInAction(name)
    return UDK_Animator.Actions[name] ~= nil
end

---|📘- 检查是否为用户动画行为
---@param name string 动画行为名称
---@return boolean isUserAction 是否为用户动画行为
function UDK_Animator.IsUserAction(name)
    return UDK_Animator.UserActions[name] ~= nil
end

return UDK_Animator
