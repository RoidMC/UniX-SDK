-- ==================================================
-- * UniX SDK - Sound Utils
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

local UDK_Sound = {}

---|📘- 玩家音效-2D
---<br>
---| `范围`：`客户端`
---@param player number 玩家ID
---@param sound_id number 音效ID
---@param volume number 音量 （默认大小0，最小值为-48，最大值为12）
---@param duration number 持续时间（单位s，0为播放默认时长）
---@param tone number 音调 （有效范围最小值为-48，最大值为48）
function UDK_Sound.PlayOnPlayer(player, sound_id, volume, duration, tone)
    local soundID = Audio:PlayAudio(sound_id, Audio.TARGET_TYPE.Character, player, volume, duration)
    Audio:SetTone(soundID, tone)
    if soundID == -1 then
        Log:PrintError("[UDK:Sound] Player播放音效失败，音效ID：" .. sound_id)
    end
end

---|📘- 元件音效-2D
---<br>
---| `范围`：`客户端`
---@param element number  元件ID
---@param sound_id number 音效ID
---@param volume number 音量 （默认大小0，最小值为-48，最大值为12）
---@param duration number 持续时间（单位s，0为播放默认时长）
---@param tone number 音调 （有效范围最小值为-48，最大值为48）
function UDK_Sound.PlayOnElement(element, sound_id, volume, duration, tone)
    local soundID = Audio:PlayAudio(sound_id, Audio.TARGET_TYPE.Element, element, volume, duration)
    Audio:SetTone(soundID, tone)
    if soundID == -1 then
        Log:PrintError("[UDK:Sound] Element播放音效失败，音效ID：" .. sound_id)
    end
end

return UDK_Sound
