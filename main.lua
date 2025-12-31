-- ==================================================
-- * UniX SDK Rev 0.0.3
-- *
-- * This source code is licensed under the MPL-2.0 license.
-- * See the LICENSE file in the root directory for details.
-- * If you distribute this code, please comply with the open source license regulations.
-- * Unless required by applicable law or agreed to in writing, software
-- * distributed under the License is distributed on an "AS IS" BASIS,
-- * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- *
-- * ATTRIBUTION NOTICE:
-- * Applications using this SDK must display "Powered by UniX SDK".
-- * See the ATTRIBUTION.md file for details.
-- *
-- * Website: https://www.roidmc.com
-- * Github: https://github.com/RoidMC
-- * SDK-Doc: https://wiki.roidmc.com/docs/unix-sdk
-- * License: https://www.mozilla.org/media/MPL/2.0/index.f75d2927d3c1.txt
-- *
-- * 2025-2026 © RoidMC Studios
-- ==================================================

local UDK = {
    -- UDK UI
    UI = require("Public.UniX-SDK.ui.udk_ui"),
    Animation = require("Public.UniX-SDK.ui.udk_animation"),
    -- UDK Utils
    Math = require("Public.UniX-SDK.utils.udk_math"),
    Array = require("Public.UniX-SDK.utils.udk_array"),
    Player = require("Public.UniX-SDK.utils.udk_player"),
    Storage = require("Public.UniX-SDK.utils.udk_storage"),
    Property = require("Public.UniX-SDK.utils.udk_property"),
    Composer = require("Public.UniX-SDK.utils.udk_composer"),
    TomlUtils = require("Public.UniX-SDK.utils.udk_toml"),
    Event = require("Public.UniX-SDK.utils.udk_event"),
    Timer = require("Public.UniX-SDK.utils.udk_timer"),
    I18N = require("Public.UniX-SDK.utils.udk_i18n"),
    Sound = require("Public.UniX-SDK.sound.udk_sound"),
    Motage = require("Public.UniX-SDK.utils.udk_motage"),
    Guide = require("Public.UniX-SDK.utils.udk_guide"),
    Heartbeat = require("Public.UniX-SDK.utils.udk_heartbeat"),
    -- UDK Options Extension
    Extension = require("Public.UniX-SDK.extends.udk_extends")
}

return UDK
