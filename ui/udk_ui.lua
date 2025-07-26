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

-- 检查是否是客户端
local function checkIsClient(apiName)
    if not System:IsClient() then
        local logOutput = string.format("[UDK:System] 接口 %s 仅允许在客户端侧调用", apiName)
        ULogPrint("ERROR", logOutput)
        return
    end
end

---|📘- 自动按钮处理器
---@param buttonData table 按钮数据
---@param event string 事件类型（Pressed/Released/Moved/Clicked）
local function AutoButtonHandler(buttonData, event, actMap)
    local ActMapping = actMap -- 加载配置

    if not ActMapping then
        --local logOutput = "[UDK:UI] ButtonEvent按钮自动处理失败，请检查按钮ID配置"
        --ULogPrint("ERROR", logOutput)
        return
    end

    if ActMapping[buttonData.BtnID] and ActMapping[buttonData.BtnID][event] then
        ActMapping[buttonData.BtnID][event](buttonData.BtnID, buttonData.PressX, buttonData.PressY) -- 执行对应事件处理
    end
end

---|📘- 设置UI可见性
---<br>
---| `范围`：`客户端`
---@param showWidgetIDs any | any[] 要显示的控件ID列表
---@param hideWidgetIDs any | any[] 要隐藏的控件ID列表
function UDK_UI.SetUIVisibility(showWidgetIDs, hideWidgetIDs)
    checkIsClient("UDK.UI.SetUIVisibility")
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
    checkIsClient("UDK.UI.SetUISize")
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
    checkIsClient("UDK.UI.SetUIPostion")
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
    checkIsClient("UDK.UI.SetUIPositionByAnchor")
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
    checkIsClient("UDK.UI.SetUITransparency")
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
    checkIsClient("UDK.UI.SetUIText")
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
    checkIsClient("UDK.UI.SetUITextColor")
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
    checkIsClient("UDK.UI.SetUITextSize")
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
    checkIsClient("UDK.UI.SetUIImage")
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
    checkIsClient("UDK.UI.SetUIImageColor")
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
    checkIsClient("UDK.UI.SetUIProgressMaxValue")
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
    checkIsClient("UDK.UI.SetUIProgressCurrentValue")
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
    checkIsClient("UDK.UI.SetUIProgressBackgroundImage")
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
    checkIsClient("UDK.UI.SetPlayerIconAndName")
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
    checkIsClient("UDK.UI.GetUISize")
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
    checkIsClient("UDK.UI.GetUIPosition")
    return UI:GetPosition(widgetID)
end

---|📘- 获取UI控件以锚点为参考的位置,不同锚点使用的值不同，不使用的属性默认为0
---<br>
---| `范围`：`客户端`
---@param widgetID any | any[] 要获取尺寸的控件ID
---@return  number[] table  返回以锚点为参考的位置数据{X,Y,Left,Right,Bottom,Top}
function UDK_UI.GetUIAnchoredPosition(widgetID)
    checkIsClient("UDK.UI.GetUIAnchoredPosition")
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
    checkIsClient("UDK.UI.SetNativeInterfaceVisible")
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
    checkIsClient("UDK.UI.ShowMessageTip")
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

---|📘- 注册按钮事件
---<br>
---| `范围`：`客户端`
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/)
---@param buttonID number|number[] 按钮ID（可以使用数组批量注册）
---@param callbackActMap table? 按钮点击回调函数
---| `回调ActMap参数`
---| `Pressed`: 按钮按下事件
---| `Released`: 按钮弹起事件
---| `Moved`: 当按钮被拖动事件，要在按钮UI打开“允许拖动”
---| `Clicked`: 按钮点击事件（此事件不支持传参X, Y轴数据使用会返回0）
function UDK_UI.RegisterButtonEvent(buttonID, callbackActMap)
    checkIsClient("UDK.UI.RegisterButtonEvent")
    local logOutput
    local ItemList = {}
    if buttonID == nil then
        logOutput = "[UDK:UI] RegisterButtonEvent: 参数缺失, ButtonID 不能为空"
        ULogPrint("ERROR", logOutput)
        return
    end
    if type(buttonID) ~= "table" and type(buttonID) == "number" then
        table.insert(ItemList, buttonID)
    elseif type(buttonID) == "table" then
        ItemList = buttonID
    end
    for _, v in ipairs(ItemList) do
        UI:RegisterPressed(v, function(ItemUID, PosX, PosY)
            --print("ButtonPress")
            local data = {
                BtnID = ItemUID,
                PressX = PosX,
                PressY = PosY,
            }
            AutoButtonHandler(data, "Pressed", callbackActMap)
        end)
        UI:RegisterReleased(v, function(ItemUID, PosX, PosY)
            --print("ButtonReleased")
            local data = {
                BtnID = ItemUID,
                PressX = PosX,
                PressY = PosY,
            }
            AutoButtonHandler(data, "Released", callbackActMap)
        end)
        UI:RegisterMoved(v, function(ItemUID, PosX, PosY)
            --print("ButtonMoved")
            local data = {
                BtnID = ItemUID,
                PressX = PosX,
                PressY = PosY,
            }
            AutoButtonHandler(data, "Moved", callbackActMap)
        end)
        UI:RegisterClicked(v, function(ItemUID)
            --print("ButtonClicked")
            local data = {
                BtnID = ItemUID,
                PressX = 0,
                PressY = 0,
            }
            AutoButtonHandler(data, "Clicked", callbackActMap)
        end)
    end
end

---|📘- 注销按钮事件
---<br>
---| `范围`：`客户端`
---<br>
---| [API文档](https://wiki.roidmc.com/docs/unix-sdk/)
---@param buttonID number|number[] 要注销的按钮ID（可以使用数组批量注销）
function UDK_UI.UnRegisterButtonEvent(buttonID)
    checkIsClient("UDK.UI.UnRegisterButtonEvent")
    local logOutput
    local ItemList = {}
    if buttonID == nil then
        logOutput = "[UDK:UI] UnRegisterButtonEvent: 参数缺失, ButtonID 不能为空"
        ULogPrint("ERROR", logOutput)
        return
    end
    if type(buttonID) ~= "table" and type(buttonID) == "number" then
        table.insert(ItemList, buttonID)
    elseif type(buttonID) == "table" then
        ItemList = buttonID
    end
    for _, v in ipairs(ItemList) do
        UI:UnRegisterPressed(v)
        UI:UnRegisterReleased(v)
        UI:UnRegisterMoved(v)
        UI:UnRegisterClicked(v)
    end
end

return UDK_UI
