-- ==================================================
-- * UniX SDK - Player Utils
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

local UDK_Player = {}

---|📘- 获取服务器上所有玩家ID（真人玩家和机器人玩家）
---<br>
---| `范围`：`服务端`、`客户端`
---@return table returnData 所有玩家ID
function UDK_Player.GetAllPlayers()
    local players = Character:GetAllPlayerIds()
    return players
end

---|📘- 获取房主玩家ID
---<br>
---| `范围`：`服务端`
---@return number returnData 房主玩家ID
function UDK_Player.GetHomeowner()
    local returnData = MiscService:GetHomeOwner()
    return returnData
end

---|📘- 获取当前游戏中的玩家人数
---<br>
---| `范围`：`服务端`、`客户端`
---@return number returnData 玩家人数
function UDK_Player.GetTotalPlayerCount()
    local returnData = Character:GetTotalPlayerCount()
    return returnData
end

---|📘- 获取本地客户端玩家ID
---<br>
---| `范围`：`客户端`
---@return number returnData 本地玩家ID
function UDK_Player.GetLocalPlayerID()
    local returnData = Character:GetLocalPlayerId()
    return returnData
end

---|📘- 获取玩家昵称
---<br>
---| `范围`：`服务端`、`客户端`
---@param player number 玩家ID
---@return string returnData 玩家昵称
function UDK_Player.GetPlayerNickName(player)
    local returnData = Chat:GetCustomName(player)
    return returnData
end

---|📘- 获取玩家头像
---<br>
---| `范围`：`服务端`、`客户端`
---@param player number 玩家ID
---@return string returnData 玩家头像
function UDK_Player.GetPlayerHeadIcon(player)
    local returnData = Chat:GetCustomHeadIcon(player)
    return returnData
end

---|📘- 根据ID获取阵营内的所有玩家
---<br>
---| `范围`：`服务端`、`客户端`
---@param teamId number 阵营ID
---@return table returnData  阵营内玩家数组ID
function UDK_Player.GetTeamPlayers(teamId)
    local returnData = Team:GetTeamPlayerArray(teamId)
    return returnData
end

return UDK_Player
