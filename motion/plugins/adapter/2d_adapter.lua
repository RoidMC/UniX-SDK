-- ==================================================
-- * UniX SDK - Animator Adapter - 2D  (Built-in)
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

local UAnimatorAdapter_2D = {}

-- 2D 适配器支持的动画类型
UAnimatorAdapter_2D.SupportType = {
    Fade = "Fade",
    Move = "Move",
    Scale = "Scale",
    Rotate = "Rotate",
    Opacity = "Opacity",
    Size = "Size",
    Color = "Color",
    TextColor = "TextColor",
}

-- 统一的数组归一化函数
local function normalizeWidgetId(widgetID)
    if type(widgetID) == "table" then
        return widgetID
    end
    return { widgetID }
end

-- 2D 适配器支持的动画动作
UAnimatorAdapter_2D.Actions = {
    Fade = function(widgetID, value)
        UI:SetTransparency(normalizeWidgetId(widgetID), value)
    end,
    Move = function(widgetID, value)
        UI:SetPosition(normalizeWidgetId(widgetID), value.x, value.y)
    end,
    Scale = function(widgetID, value)
        local ids = normalizeWidgetId(widgetID)
        for _, v in ipairs(ids) do
            UI:SetRenderScale(v, value.x, value.y)
        end
    end,
    Rotate = function(widgetID, value)
        UI:SetAngle(normalizeWidgetId(widgetID), value)
    end,
    Opacity = function(widgetID, value)
        UI:SetTransparency(normalizeWidgetId(widgetID), value)
    end,
    Size = function(widgetID, value)
        UI:SetSize(normalizeWidgetId(widgetID), value.width, value.height)
    end,
    Color = function(widgetID, value)
        UI:SetImageColor(normalizeWidgetId(widgetID), value)
    end,
    TextColor = function(widgetID, value)
        UI:SetTextColor(normalizeWidgetId(widgetID), value)
    end,
}

-- 2D 适配器获取初始值
function UAnimatorAdapter_2D.GetInitialValue(step, target, targetType)
    -- 根据动画类型获取初始值
    if step.type == "Fade" and targetType == "UI" then
        return 1
    elseif step.type == "Move" and targetType == "UI" then
        return UI:GetPosition(target.id) or { x = 0, y = 0 }
    elseif step.type == "Scale" and targetType == "UI" then
        return { x = 1, y = 1 }
    elseif step.type == "Rotate" and targetType == "UI" then
        return UI:GetAngle(target.id) or 0
    elseif step.type == "Size" and targetType == "UI" then
        local size = UI:GetSize(target.id)
        return size or { width = 100, height = 100 }
    end

    return nil
end

return UAnimatorAdapter_2D
