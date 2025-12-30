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
-- * 2025-2026 © RoidMC Studios
-- ==================================================

---@class UDK.Sound
local UDK_Sound = {}

---|📘- 元件音效-2D
---
---| `范围`：`客户端`
---@param sound_id number 音效ID
---@param volume number 音量 （默认大小0，最小值为0，最大值为100）
---@param duration number 持续时间（单位s，0为播放默认时长）
---@param tune number 音调 （有效范围最小值为-48，最大值为48）
function UDK_Sound.Play2DAudio(sound_id, volume, duration, tune)
    local soundID = Audio:PlaySFXAudio2D(sound_id, duration, volume, tune)
    if soundID == -1 then
        Log:PrintError("[UDK:Sound] 2D音效播放失败，音效ID：" .. sound_id)
    end
end

return UDK_Sound
