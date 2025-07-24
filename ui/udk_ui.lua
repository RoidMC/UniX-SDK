-- ==================================================
-- * UniX SDK - UI Utils
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

local UDK_UI = {}

-- 枚举映射表，仅在Lua调试使用，实际游戏内调用SDK不需要该枚举
--local UI = {
--    UIType = {
--        Promotion = 0,         -- 竞速的晋级界面
--        Countdown = 1,         -- 竞速的倒计时界面
--        TargetPoints = 2,      -- 竞速目标积分
--        CampPoints = 3,        -- 竞速双阵营积分
--        PersonalPoints = 4,    -- 竞速个人积分
--        Leaderboard = 5,       --竞速排行榜
--        HealthBar = 6,         -- 通用血条
--        Settings = 7,          -- 通用设置
--        RemainingPlayers = 8,  -- FPS剩余人数
--        MapHint = 9,           -- 通用地图提示
--        EmotesAndActions = 10, -- 表情/动作
--        QuickChat = 11,        -- 快速聊天
--    }
--}

-- 日志打印函数
local function ULogPrint(level, message)
    if level == "INFO" then
        Log:PrintLog(message)
    elseif level == "WARNING" then
        Log:PrintWarning(message)
    elseif level == "ERROR" then
        Log:PrintError(message)
    elseif level == "DEBUG" then
        Log:PrintDebug(message)
    else
        print(message)
    end
end

---|📘- 设置UI可见性
---<br>
---| `范围`：`客户端`
---@param showWidgetIDs any | any[] 要显示的控件ID列表
---@param hideWidgetIDs any | any[] 要隐藏的控件ID列表
function UDK_UI.SetUIVisibility(showWidgetIDs, hideWidgetIDs)
    local oneItem
    if type(hideWidgetIDs) == "table" then
        UI:SetVisible(hideWidgetIDs, false)
    else
        oneItem = {}
        table.insert(oneItem, hideWidgetIDs)
        UI:SetVisible(oneItem, false)
    end

    if type(showWidgetIDs) == "table" then
        UI:SetVisible(showWidgetIDs, true)
    else
        oneItem = {}
        table.insert(oneItem, showWidgetIDs)
        UI:SetVisible(oneItem, true)
    end
end

---|📘- 设置UI控件尺寸
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要设置文本的控件ID列表
---@param newWidth number  要设置的宽度
---@param newHeight number 要设置的高度
function UDK_UI.SetUISize(widgetID, newWidth, newHeight)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetSize(widgetID, newWidth, newHeight)
    else
        table.insert(oneItem, widgetID)
        UI:SetSize(oneItem, newWidth, newHeight)
    end
end

---|📘- 设置UI控件位置
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要设置文本的控件ID列表
---@param newX number  要设置的新坐标X
---@param newY number 要设置的新坐标Y
function UDK_UI.SetUIPostion(widgetID, newX, newY)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetPosition(widgetID, newX, newY)
    else
        table.insert(oneItem, widgetID)
        UI:SetPosition(oneItem, newX, newY)
    end
end

---|📘- 设置UI控件位置（以锚点为参考）
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要设置文本的控件ID列表
---@param data any 需要变更的数据{X,Y,Left,Right,Bottom,Top}
function UDK_UI.SetUIPositionByAnchor(widgetID, data)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetPositionByAnchor(widgetID, data)
    else
        table.insert(oneItem, widgetID)
        UI:SetPositionByAnchor(oneItem, data)
    end
end

---|📘- 设置UI控件不透明度
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要设置文本的控件ID列表
---@param newOpacity number  要设置的不透明度（范围：0-1，使用小数点）
function UDK_UI.SetUITransparency(widgetID, newOpacity)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetTransparency(widgetID, newOpacity)
    else
        table.insert(oneItem, widgetID)
        UI:SetTransparency(oneItem, newOpacity)
    end
end

---|📘- 设置UI文本内容
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要设置文本的控件ID列表
---@param content string 要设置的文本内容
function UDK_UI.SetUIText(widgetID, content)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetText(widgetID, content)
    else
        table.insert(oneItem, widgetID)
        UI:SetText(oneItem, content)
    end
end

---|📘- 设置UI文本颜色
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要设置文本的控件ID列表
---@param hexColor string 要设置的颜色（Hex 颜色码 - 例如：#FFFFFF）
function UDK_UI.SetUITextColor(widgetID, hexColor)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetTextColor(widgetID, hexColor)
    else
        table.insert(oneItem, widgetID)
        UI:SetTextColor(oneItem, hexColor)
    end
end

---|📘- 设置UI文本大小
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要设置文本的控件ID列表
---@param content number 要设置的大小（范围：15-100）
function UDK_UI.SetUITextSize(widgetID, content)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetTextSize(widgetID, content)
    else
        table.insert(oneItem, widgetID)
        UI:SetTextSize(oneItem, content)
    end
end

---|📘- 设置UI控件底图
---<br>
---| `范围`：`客户端`
---@param imageID any 要设置的图片ID
---@param widgetID any | any[] 要设置底图的控件ID列表
function UDK_UI.SetUIImage(widgetID, imageID)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetImage(widgetID, imageID)
    else
        table.insert(oneItem, widgetID)
        UI:SetImage(oneItem, imageID)
    end
end

---|📘- 设置UI控件地图颜色
---<br>
---| `范围`：`客户端`
---@param hexColor string 要设置的颜色（Hex 颜色码 - 例如：#FFFFFF）
---@param widgetID any | any[] 要设置文本的控件ID列表
function UDK_UI.SetUIImageColor(widgetID, hexColor)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetImageColor(widgetID, hexColor)
    else
        table.insert(oneItem, widgetID)
        UI:SetImageColor(oneItem, hexColor)
    end
end

---|📘- 设置UI控件进度条最大值
---<br>
---| `范围`：`客户端`
---@param widgetID any 要设置的控件ID
---@param maxValue number 要设置的最大值（范围：0-100）
function UDK_UI.SetUIProgressMaxValue(widgetID, maxValue)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetProgressMaxValue(widgetID, maxValue)
    else
        table.insert(oneItem, widgetID)
        UI:SetProgressMaxValue(oneItem, maxValue)
    end
end

---|📘- 设置UI控件进度条当前值
---<br>
---| `范围`：`客户端`
---@param widgetID any 要设置的控件ID
---@param currentValue number 要设置的当前值
function UDK_UI.SetUIProgressCurrentValue(widgetID, currentValue)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetProgressCurrentValue(widgetID, currentValue)
    else
        table.insert(oneItem, widgetID)
        UI:SetProgressCurrentValue(oneItem, currentValue)
    end
end

---|📘- 设置UI控件进度条背景底图
---<br>
---| `范围`：`客户端`
---@param widgetID any 要设置的控件ID
---@param imageID any 要设置的图片ID
function UDK_UI.SetUIProgressBackgroundImage(widgetID, imageID)
    local oneItem = {}
    if type(widgetID) == "table" then
        UI:SetProgressBackgroundImage(widgetID, imageID)
    else
        table.insert(oneItem, widgetID)
        UI:SetProgressBackgroundImage(oneItem, imageID)
    end
end

---|📘- 设置UI控件 - 功能/社交/头像昵称控件
---<br>
---| `范围`：`客户端`
---<br>
---| `根据玩家id设置头像昵称框`
---@param widgetID any | any[] 要设置的控件ID
---@param playerID number 要设置的玩家ID
---@param setType string 要设置的类型（Icon：头像，Name：昵称，Both：头像+昵称）
function UDK_UI.SetPlayerIconAndName(widgetID, playerID, setType)
    --功能/社交/头像昵称控件
    local oneItem = {}
    local function getAvatarType(param)
        if param == "Icon" then
            return UI.AvatarType.Icon
        elseif param == "Name" then
            return UI.AvatarType.NickName
        elseif param == "Both" then
            return UI.AvatarType.Both
        else
            return UI.AvatarType.Both
        end
    end
    if type(widgetID) == "table" then
        UI:SetPlayerIconAndName(widgetID, playerID, getAvatarType(setType))
    else
        table.insert(oneItem, widgetID)
        UI:SetPlayerIconAndName(oneItem, playerID, getAvatarType(setType))
    end
end

---|📘- 获取UI控件尺寸
---<br>
---| `范围`：`客户端`
---@param widgetID any 要获取尺寸的控件ID
---@return  number[] table  返回一个包含宽度和高度的数组，返回{X,Y}
function UDK_UI.GetUISize(widgetID)
    return UI:GetSize(widgetID)
end

---|📘- 获取UI控件位置
---<br>
---| `范围`：`客户端`
---<br>
---| `以屏幕中心点为锚点，x的正方向是向右偏移，y的正方向是向下偏移`
---@param widgetID any 要获取尺寸的控件ID
---@return  number[] table  返回一个包含UI控件位置的数组，返回{X,Y}
function UDK_UI.GetUIPosition(widgetID)
    return UI:GetPosition(widgetID)
end

---|📘- 获取UI控件以锚点为参考的位置,不同锚点使用的值不同，不使用的属性默认为0
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要获取尺寸的控件ID
---@return  number[] table  返回以锚点为参考的位置数据{X,Y,Left,Right,Bottom,Top}
function UDK_UI.GetUIAnchoredPosition(widgetID)
    local oneItem = {}
    local returnData
    if type(widgetID) == "table" then
        returnData = UI:GetAnchoredPosition(widgetID)
    else
        table.insert(oneItem, widgetID)
        returnData = UI:GetAnchoredPosition(oneItem)
    end
    return returnData
end

---|📘- 设置原生UI界面的可见性
---<br>
---| `范围`：`客户端`
---<br>
---| 枚举类型：[UI.UIType枚举文档](https://wiki.ymzx.qq.com/dream_helper/dist/script_helper/apis/ui/index.html#%E6%9E%9A%E4%B8%BE%E5%88%97%E8%A1%A8)
---<br>
---| `可使用ID或者是枚举内的成员名称字符串，例如"Promotion"、"Countdown"、"TargetPoints"等`
---@param interfaceType any | any[] 要设置的原生界面ID列表
---@param isVisible boolean 是否可见
function UDK_UI.SetNativeInterfaceVisible(interfaceType, isVisible)
    local nativeInterfaceMap = {
        { id = 0, type = UI.UIType.Promotion, desc = "竞速的晋级界面", match_str = "Promotion" },
        { id = 1, type = UI.UIType.Countdown, desc = "竞速的倒计时界面", match_str = "Countdown" },
        { id = 2, type = UI.UIType.TargetPoints, desc = "竞速目标积分", match_str = "TargetPoints" },
        { id = 3, type = UI.UIType.CampPoints, desc = "竞速双阵营积分", match_str = "CampPoints" },
        { id = 4, type = UI.UIType.PersonalPoints, desc = "竞速个人积分", match_str = "PersonalPoints" },
        { id = 5, type = UI.UIType.Leaderboard, desc = "竞速排行榜", match_str = "Leaderboard" },
        { id = 6, type = UI.UIType.HealthBar, desc = "通用血条", match_str = "HealthBar" },
        { id = 7, type = UI.UIType.Settings, desc = "通用设置", match_str = "Settings" },
        { id = 8, type = UI.UIType.RemainingPlayers, desc = "FPS剩余人数", match_str = "RemainingPlayers" },
        { id = 9, type = UI.UIType.MapHint, desc = "通用地图提示", match_str = "MapHint" },
        { id = 10, type = UI.UIType.EmotesAndActions, desc = "表情/动作", match_str = "EmotesAndActions" },
        { id = 11, type = UI.UIType.QuickChat, desc = "快速聊天", match_str = "QuickChat" },
    }

    local returnMap = {}
    local targetIDs = {}
    local queryType
    local logOutput
    -- 因为Lua的table索引是从1开始的，所以这里需要+1，处理位于遍历代码内，而ID是从0开始的
    -- 仅Number类型的ID需要+1，String类型的ID不需要+1
    local logIndex
    -- 新增参数预处理：将单个参数转换为数组格式
    if type(interfaceType) ~= "table" then
        interfaceType = { interfaceType }
    end

    -- 构建查找表
    for _, v in ipairs(interfaceType) do
        if type(v) == "number" then
            targetIDs[v] = true
            queryType = "Number"
            UI:SetNativeInterfaceVisible(v, isVisible)
            logIndex = v + 1
            logOutput = string.format(
                "[UDK:UI] SetNativeInterfaceVisible: 原生控件 %s (TypeID %s) 可见性已经设置为 %s (QueryType: %s | Param: %s)",
                nativeInterfaceMap[logIndex].desc, nativeInterfaceMap[logIndex].type, isVisible, queryType, v)
            ULogPrint("INFO", logOutput)
        else
            for _, entry in ipairs(nativeInterfaceMap) do
                if entry.match_str == v then
                    targetIDs[entry.id] = true
                    queryType = "String"
                    UI:SetNativeInterfaceVisible(entry.type, isVisible)
                    logOutput = string.format(
                        "[UDK:UI] SetNativeInterfaceVisible: 原生控件 %s (TypeID %s) 可见性已经设置为 %s (QueryType: %s | Param: %s)",
                        entry.desc, entry.type, isVisible, queryType, entry.match_str)
                    ULogPrint("INFO", logOutput)
                    break
                end
            end
        end
    end
    -- 设置可见性并生成返回值
    for _, entry in ipairs(nativeInterfaceMap) do
        if targetIDs[entry.id] then
            returnMap[entry.type] = isVisible
        end
    end

    --UDK_UI.PrintTable("NativeInterfaceResult: ", returnMap)
    return returnMap
end

---|📘- 对玩家屏幕展示信息
---<br>
---| `范围`：`客户端`
---<br>
---| `可用于制作提示弹窗，制作时测试API所在事件是否触发等`
---@param message string 要展示的信息
function UDK_UI.ShowMessageTip(message)
    UI:ShowMessageTip(message)
end

---|📘- 打印表格内容
---@param name string 表格名称
---@param table table 要打印的表格
function UDK_UI.PrintTable(name, table)
    print(name .. " = {")
    for k, v in pairs(table) do
        print("  [" .. tostring(k) .. "] = " .. tostring(v))
    end
    print("}")
end

return UDK_UI
