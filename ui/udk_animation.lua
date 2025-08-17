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

local change = 0.01

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

---|📘- 动画效果 | 淡入
---<br>
---| `范围`：`客户端`
---@param id number UI元素ID
function UDK_Animation.FadeIn(id)
    -- 检查参数类型
    if type(id) ~= "number" then
        local logOutput = string.format("[UDK:Animation] Fade In Animation: %s", "ID必须是数字")
        Log:PrintError(logOutput)
        return logOutput
    end

    -- 确保控件可见
    UI:SetVisible({ id }, true)

    -- 停止上一个定时器打断控件之前的渐变
    if animationStates[id] then
        TimerManager:RemoveTimer(animationStates[id].id)
    end

    -- 设置初始透明度
    local initialTransparency = 0
    if animationStates[id] then
        initialTransparency = animationStates[id].transparency
    end

    -- 添加一个新的定时器开始渐显
    local timerId = TimerManager:AddLoopTimer(0.01, function()
        -- 获取当前控件的动画状态
        local state = animationStates[id]
        if not state or not state.active then
            return
        end

        -- 透明度增加直到为1时停止
        state.transparency = state.transparency + change
        if state.transparency > 1 then
            state.transparency = 1
            TimerManager:RemoveTimer(state.id)
            state.active = false
        end
        -- 渐变效果
        UI:SetTransparency({ id }, state.transparency) -- 设置控件透明度
    end)

    -- 创建或更新动画元数据
    createAnimationMeta(id, timerId, initialTransparency)
end

---|📘- 动画效果 | 淡出
---<br>
---| `范围`：`客户端`
---@param id number UI元素ID
function UDK_Animation.FadeOut(id)
    -- 检查参数类型
    if type(id) ~= "number" then
        local logOutput = string.format("[UDK:Animation] Fade Out Animation: %s", "ID必须是数字")
        Log:PrintError(logOutput)
        return logOutput
    end

    -- 停止上一个定时器打断控件之前的渐变
    if animationStates[id] then
        TimerManager:RemoveTimer(animationStates[id].id)
    end

    -- 设置初始透明度
    local initialTransparency = 1
    if animationStates[id] then
        initialTransparency = animationStates[id].transparency
    end

    -- 添加一个新的定时器开始渐隐
    local timerId = TimerManager:AddLoopTimer(0.01, function()
        -- 获取当前控件的动画状态
        local state = animationStates[id]
        if not state or not state.active then
            return
        end

        -- 透明度减少直到为0时停止
        state.transparency = state.transparency - change
        if state.transparency < 0 then
            state.transparency = 0
            TimerManager:RemoveTimer(state.id)
            state.active = false
            -- 渐隐完成后隐藏控件
            UI:SetVisible({ id }, false)
        end
        -- 渐变效果
        UI:SetTransparency({ id }, state.transparency) -- 设置控件透明度
    end)

    -- 创建或更新动画元数据
    createAnimationMeta(id, timerId, initialTransparency)
end

return UDK_Animation
