-- ==================================================
-- * UniX SDK Rev 0.0.1
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
-- * 2025 © RoidMC Studios
-- ==================================================

local UDK = {
    -- UDK UI
    UI = require("ui.udk_ui"),
    --Animation = require("ui.udk_animation"),
    -- UDK Utils
    Math = require("utils.udk_math"),
    Array = require("utils.udk_array"),
    Player = require("utils.udk_player"),
    Storage = require("utils.udk_storage"),
    Property = require("utils.udk_property"),
    Composer = require("utils.udk_composer"),
    --Logger = require("utils.udk_logger"),
    TomlUtils = require("utils.udk_toml"),
    Event = require("utils.udk_event"),
    Timer = require("utils.udk_timer"),
    I18N = require("utils.udk_i18n"),
    Sound = require("sound.udk_sound"),
    -- UDK Options Extension
    Extension = require("extends.udk_extends")
}

return UDK
