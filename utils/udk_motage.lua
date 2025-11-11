-- ==================================================
-- * UniX SDK - Motage Nex Animation
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

local UDK_Motage = {}

UDK_Motage.NetMsg = {
    ServerSendAnimReq = 200200
}

local Conf = {
    EnvType = {
        Standalone = { ID = 0, Name = "Standalone" },
        Server = { ID = 1, Name = "Server" },
        Client = { ID = 2, Name = "Client" }
    }
}

---返回当前环境状态
---@return table {
---     envID: number,       -- 环境ID（Server=1, Client=2, Standalone=0）
---     envName: string,     -- 环境名称（"Server", "Client", "Standalone"）
---     isStandalone: boolean -- 是否为单机模式
---}
local function envCheck()
    local isStandalone = System:IsStandalone()
    local envType = isStandalone and Conf.EnvType.Standalone or
        (System:IsServer() and Conf.EnvType.Server or Conf.EnvType.Client)

    return {
        envID = envType.ID,
        envName = envType.Name,
        isStandalone = isStandalone
    }
end

local function clientAnimHandler(_msgID, msg)
    --Log:PrintTable(msg)
   --Log:PrintLog(Animation.PLAYER_TYPE.Character)
    if msg.AnimType == "PlayAnim" then
        Animation:PlayAnim(msg.TargetType, msg.TargetID, msg.AnimName, msg.PartName)
    elseif msg.AnimType == "StopAnim" then
        Animation:StopAnim(msg.TargetType, msg.TargetID, msg.AnimName, msg.PartName, msg.BleedOutTime)
    elseif msg.AnimType == "PlayAnimAIGC" then
        Animation:PlayAnimAI(msg.TargetType, msg.TargetID, msg.AnimIndex, msg.IsLoop)
    elseif msg.AnimType == "StopAnimAIGC" then
        Animation:StopAnimAI(msg.TargetType, msg.TargetID)
    elseif msg.AnimType == "PlayAnimSplice" then
        Animation:PlayAnimSplice(msg.TargetType, msg.TargetID, msg.AnimIndex, msg.IsLoop)
    elseif msg.AnimType == "StopAnimSplice" then
        Animation:StopAnimSplice(msg.TargetType, msg.TargetID)
    end
end

local function serverAnimPacketBuilder(MsgStructure)
    System:SendToAllClients(UDK_Motage.NetMsg.ServerSendAnimReq, MsgStructure)
end

local function networkBindNotifyInit()
    if System:IsClient() then
        System:BindNotify(UDK_Motage.NetMsg.ServerSendAnimReq, clientAnimHandler)
    end
end

-- 调用游戏运行事件，进行注册网络消息通知
System:RegisterEvent(Events.ON_BEGIN_PLAY, networkBindNotifyInit)

---|📘 让目标对象播放动作
---@param targetType string 目标对象类型（玩家 | 生物）[API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationplayer_type)
---@param targetID number 目标对象ID
---@param animName string 动画名称
---@param partName string? 动画播放类型（默认为FullBody） [API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationpart_name)
function UDK_Motage.PlayAnim(targetType, targetID, animName, partName)
    local envInfo = envCheck()
    -- 如果环境是服务端环境，则发送网络消息给客户端，客户端收到消息后调用clientAnimHandler函数处理
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            AnimType = "PlayAnim",
            AnimName = animName,
            PartName = partName,
            TargetType = targetType,
            TargetID = targetID
        }
        serverAnimPacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Animation:PlayAnim(targetType, targetID, animName, partName)
    end
end

---|📘 让目标对象停止播放动作
---@param targetType string 目标对象类型（玩家 | 生物）[API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationplayer_type)
---@param targetID number 目标对象ID
---@param animName string 动画名称
---@param partName string 动画播放类型（默认为FullBody）  [API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationpart_name)
---@param bleedOutTime number 动画混合时间（默认0.2）
function UDK_Motage.StopAnim(targetType, targetID, animName, partName, bleedOutTime)
    local envInfo = envCheck()
    -- 如果环境是服务端环境，则发送网络消息给客户端，客户端收到消息后调用clientAnimHandler函数处理
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            AnimType = "StopAnim",
            AnimName = animName,
            BleedOutTime = bleedOutTime,
            PartName = partName,
            TargetType = targetType,
            TargetID = targetID
        }
        serverAnimPacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Animation:StopAnim(targetType, targetID, animName, partName, bleedOutTime)
    end
end

---|📘 让目标对象播放视频动作
---@param targetType string 目标对象类型（玩家 | 生物）[API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationplayer_type)
---@param targetID number 目标对象ID
---@param animIndex number 生成的视频动作id按顺序依次为：1、2、3.
---@param isLoop boolean 是否循环播放
function UDK_Motage.PlayAnimAIGC(targetType, targetID, animIndex, isLoop)
    local envInfo = envCheck()
    -- 如果环境是服务端环境，则发送网络消息给客户端，客户端收到消息后调用clientAnimHandler函数处理
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            AnimType = "PlayAnimAIGC",
            AnimIndex = animIndex,
            IsLoop = isLoop,
            TargetType = targetType,
            TargetID = targetID
        }
        serverAnimPacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Animation:PlayAnimAIGC(targetType, targetID, animIndex, isLoop)
    end
end

---|📘 让目标对象停止播放视频动作
---@param targetType string 目标对象类型（玩家 | 生物）[API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationplayer_type)
---@param targetID number 目标对象ID
function UDK_Motage.StopAnimAIGC(targetType, targetID)
    local envInfo = envCheck()
    -- 如果环境是服务端环境，则发送网络消息给客户端，客户端收到消息后调用clientAnimHandler函数处理
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            AnimType = "StopAnimAIGC",
            TargetType = targetType,
            TargetID = targetID
        }
        serverAnimPacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Animation:StopAnimAIGC(targetType, targetID)
    end
end

---|📘 让目标对象播放拼接动作动作
---@param targetType string 目标对象类型（玩家 | 生物）[API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationplayer_type)
---@param targetID number 目标对象ID
---@param animIndex number 拼接动作id按顺序依次为：1、2、3.
---@param isLoop boolean 是否循环播放
function UDK_Motage.PlayAnimSplice(targetType, targetID, animIndex, isLoop)
    local envInfo = envCheck()
    -- 如果环境是服务端环境，则发送网络消息给客户端，客户端收到消息后调用clientAnimHandler函数处理
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            AnimType = "PlayAnimSplice",
            AnimIndex = animIndex,
            IsLoop = isLoop,
            TargetType = targetType,
            TargetID = targetID
        }
        serverAnimPacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Animation:PlayAnimSplice(targetType, targetID, animIndex, isLoop)
    end
end

---|📘 让目标对象停止播放拼接动作动作
---@param targetType string 目标对象类型（玩家 | 生物）[API枚举](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/animation/index.html#animationplayer_type)
---@param targetID number 目标对象ID
function UDK_Motage.StopAnimSplice(targetType, targetID)
    local envInfo = envCheck()
    -- 如果环境是服务端环境，则发送网络消息给客户端，客户端收到消息后调用clientAnimHandler函数处理
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            AnimType = "StopAnimSplice",
            TargetType = targetType,
            TargetID = targetID
        }
        serverAnimPacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Animation:StopAnimSplice(targetType, targetID)
    end
end

return UDK_Motage
