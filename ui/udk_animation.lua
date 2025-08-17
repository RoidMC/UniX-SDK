-- ==================================================
-- * UniX SDK - Animation
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

local UDK_Animation = {}

-- 存储每个控件的动画状态
local animationStates = {}

-- 默认动画配置
local defaultConfig = {
    change = 0.05,   -- 默认透明度变化率
    interval = 0.01, -- 默认定时器间隔(秒)
}

-- 当前动画配置
local animConfig = {
    change = defaultConfig.change,
    interval = defaultConfig.interval,
}

---|📘- 创建动画元数据
---@param id number 控件ID
---@param timerId number 系统分配的定时器ID
---@param initialTransparency number 初始透明度
local function createAnimationMeta(id, timerId, initialTransparency)
    animationStates[id] = {
        id = timerId,
        transparency = initialTransparency,
        active = true
    }
    return animationStates[id]
end

---|📘- 清理特定UI元素的动画状态
---@param id number UI元素ID
function UDK_Animation.CleanupAnimation(id)
    if animationStates[id] then
        if animationStates[id].id then
            local success, err = pcall(function()
                TimerManager:RemoveTimer(animationStates[id].id)
            end)

            if not success then
                Log:PrintWarning(string.format("[UDK:Animation] 移除定时器失败: %s", err))
            end
        end
        animationStates[id] = nil
    end
end

---|📘- 清理所有动画状态
function UDK_Animation.CleanupAllAnimations()
    for id, state in pairs(animationStates) do
        if state.id then
            local success, err = pcall(function()
                TimerManager:RemoveTimer(state.id)
            end)

            if not success then
                Log:PrintWarning(string.format("[UDK:Animation] 移除定时器失败: %s", err))
            end
        end
    end
    animationStates = {}
end

---|📘- 设置动画配置
---@param config table 配置表
---@return table 当前配置
function UDK_Animation.SetConfig(config)
    if type(config) ~= "table" then
        return animConfig
    end

    if type(config.change) == "number" then
        animConfig.change = config.change
    end

    if type(config.interval) == "number" then
        animConfig.interval = config.interval
    end

    return animConfig
end

---|📘- 重置动画配置为默认值
function UDK_Animation.ResetConfig()
    animConfig.change = defaultConfig.change
    animConfig.interval = defaultConfig.interval
    return animConfig
end

---|📘- 创建淡入淡出动画
---@param id number UI元素ID
---@param fadeType string 淡入或淡出 ("in" 或 "out")
---@param options table? 可选配置参数
local function createFadeAnimation(id, fadeType, options)
    options = options or {}
    local isVisible = fadeType == "in"
    local targetTransparency = isVisible and 1 or 0
    local changeDirection = isVisible and 1 or -1
    local interval = options.interval or animConfig.interval
    local changeRate = options.change or animConfig.change
    local onComplete = options.onComplete

    -- 检查参数类型
    if type(id) ~= "number" then
        local logOutput = string.format("[UDK:Animation] Fade %s Animation: %s",
            fadeType == "in" and "In" or "Out", "ID必须是数字")
        Log:PrintError(logOutput)
        return logOutput
    end

    -- 如果是淡入，确保控件可见
    if isVisible then
        local success, err = pcall(function()
            UI:SetVisible({ id }, true)
        end)

        if not success then
            Log:PrintWarning(string.format("[UDK:Animation] 设置控件可见失败: %s", err))
            return
        end
    end

    -- 停止上一个定时器打断控件之前的渐变
    if animationStates[id] and animationStates[id].id then
        local success, err = pcall(function()
            TimerManager:RemoveTimer(animationStates[id].id)
        end)

        if not success then
            Log:PrintWarning(string.format("[UDK:Animation] 移除定时器失败: %s", err))
        end
    end

    -- 设置初始透明度
    local initialTransparency = isVisible and 0 or 1
    if animationStates[id] then
        initialTransparency = animationStates[id].transparency
    end

    -- 添加一个新的定时器开始渐变
    local timerId, err = TimerManager:AddLoopTimer(interval, function()
        -- 获取当前控件的动画状态
        local state = animationStates[id]
        if not state or not state.active then
            return
        end

        -- 计算透明度并更新状态
        local progress = changeRate

        -- 直接更新透明度
        state.transparency = state.transparency + (progress * changeDirection)

        -- 检查是否达到目标透明度
        if (changeDirection > 0 and state.transparency >= targetTransparency) or
            (changeDirection < 0 and state.transparency <= targetTransparency) then
            state.transparency = targetTransparency

            local success, timerErr = pcall(function()
                TimerManager:RemoveTimer(state.id)
            end)

            if not success then
                Log:PrintWarning(string.format("[UDK:Animation] 移除定时器失败: %s", timerErr))
            end

            state.active = false

            -- 如果是淡出，完成后隐藏控件
            if not isVisible then
                local success, uiErr = pcall(function()
                    UI:SetVisible({ id }, false)
                end)

                if not success then
                    Log:PrintWarning(string.format("[UDK:Animation] 设置控件不可见失败: %s", uiErr))
                end
            end

            -- 执行完成回调
            if type(onComplete) == "function" then
                local success, cbErr = pcall(onComplete, id)
                if not success then
                    Log:PrintWarning(string.format("[UDK:Animation] 回调执行失败: %s", cbErr))
                end
            end
        end

        -- 应用透明度
        local success, transErr = pcall(function()
            UI:SetTransparency({ id }, state.transparency)
        end)

        if not success then
            Log:PrintWarning(string.format("[UDK:Animation] 设置透明度失败: %s", transErr))
        end
    end)

    if not timerId then
        Log:PrintError(string.format("[UDK:Animation] 创建定时器失败: %s", err or "未知错误"))
        return
    end

    -- 创建或更新动画元数据
    return createAnimationMeta(id, timerId, initialTransparency)
end

---|📘- 动画效果 | 淡入
---<br>
---| `范围`：`客户端`
---@param id number UI元素ID
---@param options table? 可选配置参数
function UDK_Animation.FadeIn(id, options)
    return createFadeAnimation(id, "in", options)
end

---|📘- 动画效果 | 淡出
---<br>
---| `范围`：`客户端`
---@param id number UI元素ID
---@param options table? 可选配置参数
function UDK_Animation.FadeOut(id, options)
    return createFadeAnimation(id, "out", options)
end

return UDK_Animation
