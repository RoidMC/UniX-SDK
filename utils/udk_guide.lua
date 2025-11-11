-- ==================================================
-- * UniX SDK - Guide System
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

local UDK_Guide = {}

UDK_Guide.NetMsg = {
    ServerSendGuideReq = 200300
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

local function clientGuideHandler(_msgID, msg)
    Log:PrintTable(msg)
    if msg.Type == "SetGuidePicture" then
        Guide:SetGuidePicture(msg.GuideID, msg.PictureID, msg.Color, msg.Transparency, msg.IsCustomImage)
    elseif msg.Type == "SetGuideVisible" then
        Guide:SetGuideVisible(msg.GuideID, msg.IsVisible)
    elseif msg.Type == "SetGuideShowLimit" then
        Guide:SetGuideShowLimit(msg.MaxLimit)
    elseif msg.Type == "SetGuideImageSize" then
        Guide:SetGuideImageSize(msg.GuideID, msg.ImageSize)
    elseif msg.Type == "SetGuideLabelText" then
        Guide:SetGuideLabelText(msg.GuideID, msg.LabelText)
    elseif msg.Type == "SetGuideShowTextOnly" then
        Guide:SetGuideShowTextOnly(msg.GuideID, msg.IsShowTextOnly)
    end
end

local function serverGuidePacketBuilder(MsgStructure)
    System:SendToAllClients(UDK_Guide.NetMsg.ServerSendGuideReq, MsgStructure)
end

local function networkBindNotifyInit()
    if System:IsClient() then
        System:BindNotify(UDK_Guide.NetMsg.ServerSendGuideReq, clientGuideHandler)
    end
end

-- 调用游戏运行事件，进行注册网络消息通知
System:RegisterEvent(Events.ON_BEGIN_PLAY, networkBindNotifyInit)

---|📘 设置目标指引器图案
---@param guideID number 目标指引器元件ID
---@param pictureID number 图片ID [官方图片ID](https://creator.ymzx.qq.com/dream_helper/dist/script_helper/apis/tables/imageid/index.html)
---@param color string 16进制颜色值，默认#FFFFFF
---@param transparency number 透明度 0-1
---@param isCustomImage boolean? 是否使用自定义图片（默认为false）
function UDK_Guide.SetGuidePicture(guideID, pictureID, color, transparency, isCustomImage)
    local envInfo = envCheck()
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            Type = "SetGuidePicture",
            GuideID = guideID,
            PictureID = pictureID,
            Color = color,
            Transparency = transparency,
            IsCustomImage = isCustomImage
        }
        serverGuidePacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Guide:SetGuidePicture(guideID, pictureID, color, transparency, isCustomImage)
    end
end

---|📘 设置目标指引器可见性
---@param guideID number 目标指引器元件ID
---@param isVisible boolean 是否可见
function UDK_Guide.SetGuideVisible(guideID, isVisible)
    local envInfo = envCheck()
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            Type = "SetGuideVisible",
            GuideID = guideID,
            IsVisible = isVisible
        }
        serverGuidePacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Guide:SetGuideVisible(guideID, isVisible)
    end
end

---|📘 设置目标指引器游戏内同时显示的最大数量
---@param maxLimit number 最大数量（上限为5,0为关闭显示）
function UDK_Guide.SetGuideShowLimit(maxLimit)
    local envInfo = envCheck()
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            Type = "SetGuideShowLimit",
            MaxLimit = maxLimit
        }
        serverGuidePacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Guide:SetGuideShowLimit(maxLimit)
    end
end

---|📘 设置目标指引器图案大小
---@param guideID number 目标指引器元件ID
---@param imageSize number 显示的图案大小
function UDK_Guide.SetGuideImageSize(guideID, imageSize)
    local envInfo = envCheck()
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            Type = "SetGuideImageSize",
            GuideID = guideID,
            ImageSize = imageSize
        }
        serverGuidePacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Guide:SetGuideImageSize(guideID, imageSize)
    end
end

---|📘 设置目标指引器图案提示文本
---<br>
---| `说明`：`最多七个字`
---@param guideID number 目标指引器元件ID
---@param labelText string 提示文本
function UDK_Guide.SetGuideLabelText(guideID, labelText)
    local envInfo = envCheck()
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            Type = "SetGuideLabelText",
            GuideID = guideID,
            LabelText = labelText
        }
        serverGuidePacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Guide:SetGuideLabelText(guideID, labelText)
    end
end

---|📘 设置目标指引器图案是否只显示文本
---@param guideID number 目标指引器元件ID
---@param isShowTextOnly boolean 是否只显示文本
function UDK_Guide.SetGuideShowTextOnly(guideID, isShowTextOnly)
    local envInfo = envCheck()
    if envInfo.envID == Conf.EnvType.Server.ID then
        local msg = {
            Type = "SetGuideShowTextOnly",
            GuideID = guideID,
            IsShowTextOnly = isShowTextOnly
        }
        serverGuidePacketBuilder(msg)
    elseif envInfo.envID == Conf.EnvType.Client.ID or envInfo.isStandalone then
        Guide:SetGuideShowTextOnly(guideID, isShowTextOnly)
    end
end

return UDK_Guide
