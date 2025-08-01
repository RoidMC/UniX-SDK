-- ==================================================
-- * UniX SDK - Event
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

local UDK_Event = {}

---|📘- 发送信号
---<br>
---| `范围`：`服务端`、`客户端`
---<br>
---| [元梦API文档](https://wiki.ymzx.qq.com/dream_helper/dist/script_helper/apis/system/index.html#firesignevent)
---@param eventName string 事件名称
---@param playerID number | table? 	在哪些玩家端触发信号; 不传时只会在当前端触发; 如果需要通知多个玩家触发，则需要在服务端进行调用，并传入需要触发信号的玩家id数组
function UDK_Event.FireSignEvent(eventName, playerID)
    -- 如果playerID为nil，使用空表触发当前端
    -- 如果playerID已经是表，直接使用
    -- 如果playerID是数字，将其转换为单元素表
    local targets = (playerID == nil) and {}
        or (type(playerID) == "table") and playerID
        or { playerID }

    -- 判断targets是否为空表
    local isEmpty = next(targets) == nil

    -- 根据targets是否为空表执行不同的FireSignEvent
    if isEmpty then
        -- 空表情况，不传targets参数
        System:FireSignEvent(eventName)
    else
        -- 非空表情况，传递targets参数
        System:FireSignEvent(eventName, targets)
    end
end

return UDK_Event
