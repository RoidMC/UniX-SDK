-- ==================================================
-- * UniX SDK - Composer
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

-- 本地化常用函数以提高访问速度
local type = type
local error = error
local pairs = pairs
local ipairs = ipairs
local next = next
local table_insert = table.insert
local table_concat = table.concat
local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local string_pack = string.pack
local string_unpack = string.unpack
local string_format = string.format
local math_type = math.type
local math_floor = math.floor

-- 创建模块表
local UDK_Composer = {}

-- 定义类型标识
local TYPE_INT = 0x00       -- 整数类型标识符
local TYPE_FLOAT = 0x01     -- 浮点数类型标识符
local TYPE_DECIMAL = 0x02   -- 十进制类型标识符
local TYPE_STRING = 0x03    -- 字符串类型标识符
local TYPE_TABLE = 0x04     -- 表类型标识符
local TYPE_TABLE_END = 0x05 -- 表结束标识符

-- 定义希腊字母映射
local greek_letters = {
    [0] = "Α",
    [1] = "Β",
    [2] = "Γ",
    [3] = "Δ",
    [4] = "Ε",
    [5] = "Ζ",
    [6] = "Η",
    [7] = "Θ",
    [8] = "Ι",
    [9] = "Κ",
    [10] = "Λ",
    [11] = "Μ",
    [12] = "Ν",
    [13] = "Ξ",
    [14] = "Ο",
    [15] = "Π",
    [16] = "Ρ",
    [17] = "Σ",
    [18] = "Τ",
    [19] = "Υ",
    [20] = "Φ",
    [21] = "Χ",
    [22] = "Ψ",
    [23] = "Ω",
    [24] = "α",
    [25] = "β",
    [26] = "γ",
    [27] = "δ",
    [28] = "ε",
    [29] = "ζ",
    [30] = "η",
    [31] = "θ",
    [32] = "ι",
    [33] = "κ",
    [34] = "λ",
    [35] = "μ",
    [36] = "ν",
    [37] = "ξ",
    [38] = "ο",
    [39] = "π",
    [40] = "ρ",
    [41] = "σ",
    [42] = "τ",
    [43] = "υ",
    [44] = "φ",
    [45] = "χ",
    [46] = "ψ",
    [47] = "ω",
    [48] = "ς",
    [49] = "Α",
    [50] = "Β",
    [51] = "Γ",
    [52] = "Δ",
    [53] = "Ε",
    [54] = "Ζ",
    [55] = "Η",
    [56] = "Θ",
    [57] = "Ι",
    [58] = "Κ",
    [59] = "Λ",
    [60] = "Μ",
    [61] = "Ν",
    [62] = "Ξ",
    [63] = "Ο",
    [64] = "Π",
    [65] = "Ρ",
    [66] = "Σ",
    [67] = "Τ",
    [68] = "Υ",
    [69] = "Φ",
    [70] = "Χ",
    [71] = "Ψ",
    [72] = "Ω",
    [73] = "α",
    [74] = "β",
    [75] = "γ",
    [76] = "δ",
    [77] = "ε",
    [78] = "ζ",
    [79] = "η",
    [80] = "θ",
    [81] = "ι",
    [82] = "κ",
    [83] = "λ",
    [84] = "μ",
    [85] = "ν",
    [86] = "ξ",
    [87] = "ο",
    [88] = "π",
    [89] = "ρ",
    [90] = "σ",
    [91] = "τ",
    [92] = "υ",
    [93] = "φ",
    [94] = "χ",
    [95] = "ψ",
    [96] = "ω",
    [97] = "Α",
    [98] = "Β",
    [99] = "Γ",
    [100] = "Δ",
    [101] = "Ε",
    [102] = "Ζ",
    [103] = "Η",
    [104] = "Θ",
    [105] = "Ι",
    [106] = "Κ",
    [107] = "Λ",
    [108] = "Μ",
    [109] = "Ν",
    [110] = "Ξ",
    [111] = "Ο",
    [112] = "Π",
    [113] = "Ρ",
    [114] = "Σ",
    [115] = "Τ",
    [116] = "Υ",
    [117] = "Φ",
    [118] = "Χ",
    [119] = "Ψ",
    [120] = "Ω",
    [121] = "α",
    [122] = "β",
    [123] = "γ",
    [124] = "δ",
    [125] = "ε",
    [126] = "ζ",
    [127] = "η",
    [128] = "θ",
    [129] = "ι",
    [130] = "κ",
    [131] = "λ",
    [132] = "μ",
    [133] = "ν",
    [134] = "ξ",
    [135] = "ο",
    [136] = "π",
    [137] = "ρ",
    [138] = "σ",
    [139] = "τ",
    [140] = "υ",
    [141] = "φ",
    [142] = "χ",
    [143] = "ψ",
    [144] = "ω",
    [145] = "Α",
    [146] = "Β",
    [147] = "Γ",
    [148] = "Δ",
    [149] = "Ε",
    [150] = "Ζ",
    [151] = "Η",
    [152] = "Θ",
    [153] = "Ι",
    [154] = "Κ",
    [155] = "Λ",
    [156] = "Μ",
    [157] = "Ν",
    [158] = "Ξ",
    [159] = "Ο",
    [160] = "Π",
    [161] = "Ρ",
    [162] = "Σ",
    [163] = "Τ",
    [164] = "Υ",
    [165] = "Φ",
    [166] = "Χ",
    [167] = "Ψ",
    [168] = "Ω",
    [169] = "α",
    [170] = "β",
    [171] = "γ",
    [172] = "δ",
    [173] = "ε",
    [174] = "ζ",
    [175] = "η",
    [176] = "θ",
    [177] = "ι",
    [178] = "κ",
    [179] = "λ",
    [180] = "μ",
    [181] = "ν",
    [182] = "ξ",
    [183] = "ο",
    [184] = "π",
    [185] = "ρ",
    [186] = "σ",
    [187] = "τ",
    [188] = "υ",
    [189] = "φ",
    [190] = "χ",
    [191] = "ψ",
    [192] = "ω",
    [193] = "Α",
    [194] = "Β",
    [195] = "Γ",
    [196] = "Δ",
    [197] = "Ε",
    [198] = "Ζ",
    [199] = "Η",
    [200] = "Θ",
    [201] = "Ι",
    [202] = "Κ",
    [203] = "Λ",
    [204] = "Μ",
    [205] = "Ν",
    [206] = "Ξ",
    [207] = "Ο",
    [208] = "Π",
    [209] = "Ρ",
    [210] = "Σ",
    [211] = "Τ",
    [212] = "Υ",
    [213] = "Φ",
    [214] = "Χ",
    [215] = "Ψ",
    [216] = "Ω",
    [217] = "α",
    [218] = "β",
    [219] = "γ",
    [220] = "δ",
    [221] = "ε",
    [222] = "ζ",
    [223] = "η",
    [224] = "θ",
    [225] = "ι",
    [226] = "κ",
    [227] = "λ",
    [228] = "μ",
    [229] = "ν",
    [230] = "ξ",
    [231] = "ο",
    [232] = "π",
    [233] = "ρ",
    [234] = "σ",
    [235] = "τ",
    [236] = "υ",
    [237] = "φ",
    [238] = "χ",
    [239] = "ψ",
    [240] = "ω",
    [241] = "Α",
    [242] = "Β",
    [243] = "Γ",
    [244] = "Δ",
    [245] = "Ε",
    [246] = "Ζ",
    [247] = "Η",
    [248] = "Θ",
    [249] = "Ι",
    [250] = "Κ",
    [251] = "Λ",
    [252] = "Μ",
    [253] = "Ν",
    [254] = "Ξ",
    [255] = "Ο"
}

-- 预分配一个固定大小的表用于bytes_to_greek函数
local result_buffer = {}

-- 将bytes转换为希腊字母（未使用）
local function bytes_to_greek(bytes)
    local len = #bytes
    for i = 1, len do
        result_buffer[i] = greek_letters[string_byte(bytes, i)] or string_char(string_byte(bytes, i))
    end
    return table_concat(result_buffer, "", 1, len)
end

-- 检查字符串长度是否足够进行解码操作
local function check_length(str, required_len, operation)
    if #str < required_len then
        error(string_format("[UDK:Composer] Data string too short for %s operation. Required: %d, Got: %d",
            operation or "unknown", required_len, #str))
    end
    return true
end

---|📘- 编码数据
---@param value number|string|table 要编码的数据
function UDK_Composer.Encode(value)
    local val_type = type(value)

    if val_type == "number" then
        if math_type and math_type(value) == "integer" then
            -- 整数编码
            return string_char(TYPE_INT) .. string_pack(">i8", value)
        else
            -- 浮点数编码
            return string_char(TYPE_FLOAT) .. string_pack(">d", value)
        end
    elseif val_type == "string" then
        local value_str = value
        if value_str:match("^%d+%.%d+$") or value_str:match("^%d+$") then
            -- Decimal编码
            local precision = 0
            local dot_pos = value_str:find("%.")
            if dot_pos then
                precision = #value_str - dot_pos
            end
            return string_char(TYPE_DECIMAL) .. string_char(precision) .. value_str
        else
            -- 字符串编码
            return string_char(TYPE_STRING) .. string_pack(">I4", #value_str) .. value_str
        end
    elseif val_type == "table" then
        -- 表编码
        local result = string_char(TYPE_TABLE)

        -- 编码数组部分（连续整数键）
        for i, v in ipairs(value) do
            -- 编码键（整数）
            result = result .. string_char(TYPE_INT) .. string_pack(">i8", i)
            -- 编码值（递归）
            result = result .. UDK_Composer.Encode(v)
        end

        -- 编码哈希部分（非连续整数键）
        for k, v in pairs(value) do
            if type(k) ~= "number" or k <= 0 or k > #value or math_floor(k) ~= k then
                -- 编码键
                result = result .. UDK_Composer.Encode(k)
                -- 编码值
                result = result .. UDK_Composer.Encode(v)
            end
        end

        -- 表结束标记
        result = result .. string_char(TYPE_TABLE_END)
        return result
    else
        error("[UDK:Composer] Unsupported type: " .. val_type .. ". Must be a number, string, or table.")
    end
end

---|📘- 解码数据
---@param encoded_value string 编码后的数据
---@param start_pos number? 开始解码的位置（默认1，可选）
function UDK_Composer.Decode(encoded_value, start_pos)
    start_pos = start_pos or 1

    -- 确保至少有一个字节用于类型
    check_length(encoded_value, start_pos, "type detection")

    local type_byte = string_byte(encoded_value, start_pos)
    local value, next_pos

    if type_byte == TYPE_INT then
        -- 整数解码
        check_length(encoded_value, start_pos + 8, "integer decode")
        value = string_unpack(">i8", string_sub(encoded_value, start_pos + 1, start_pos + 8))
        next_pos = start_pos + 9
    elseif type_byte == TYPE_FLOAT then
        -- 浮点数解码
        check_length(encoded_value, start_pos + 8, "float decode")
        value = string_unpack(">d", string_sub(encoded_value, start_pos + 1, start_pos + 8))
        next_pos = start_pos + 9
    elseif type_byte == TYPE_DECIMAL then
        -- Decimal解码
        check_length(encoded_value, start_pos + 1, "decimal decode")
        -- 获取剩余的字符串
        value = string_sub(encoded_value, start_pos + 2)
        next_pos = start_pos + 2 + #value
    elseif type_byte == TYPE_STRING then
        -- 字符串解码
        check_length(encoded_value, start_pos + 4, "string length decode")
        local length = string_unpack(">I4", string_sub(encoded_value, start_pos + 1, start_pos + 4))
        check_length(encoded_value, start_pos + 4 + length, "string content decode")
        value = string_sub(encoded_value, start_pos + 5, start_pos + 4 + length)
        next_pos = start_pos + 5 + length
    elseif type_byte == TYPE_TABLE then
        -- 表解码
        value = {}
        next_pos = start_pos + 1

        -- 循环解码表中的键值对，直到遇到表结束标记
        while next_pos <= #encoded_value do
            -- 检查是否到达表结束标记
            if string_byte(encoded_value, next_pos) == TYPE_TABLE_END then
                next_pos = next_pos + 1
                break
            end

            -- 解码键
            local key, key_next_pos = UDK_Composer.Decode(encoded_value, next_pos)
            if not key then
                error("[UDK:Composer] Failed to decode table key")
            end
            next_pos = key_next_pos

            -- 解码值
            local val, val_next_pos = UDK_Composer.Decode(encoded_value, next_pos)
            if not val then
                error("[UDK:Composer] Failed to decode table value for key: " .. tostring(key))
            end
            next_pos = val_next_pos

            -- 存储键值对
            value[key] = val
        end
    else
        error(string_format("[UDK:Composer] Unsupported type byte: %02x", type_byte))
    end

    return value, next_pos
end

-- 预分配缓冲区用于encode_with_delimiter
local encode_buffer = {}

---|📘- 编码数据，并使用分隔符连接
---@param values table 要编码的值列表
---@param delimiter string 分隔符，默认为0xFE
function UDK_Composer.EncodeWithDelimiter(values, delimiter)
    delimiter = delimiter or string_char(0xFE)
    local count = #values
    if count == 0 then
        return ""
    end

    -- 重置缓冲区并编码值
    for i = 1, count do
        encode_buffer[i] = UDK_Composer.Encode(values[i])
    end

    return table_concat(encode_buffer, delimiter, 1, count)
end

---|📘- 解码数据，并使用分隔符连接
---@param encoded_bytes string 要解码的数据
---@param delimiter string 分隔符，默认为0xFE
function UDK_Composer.DecodeWithDelimiter(encoded_bytes, delimiter)
    delimiter = delimiter or string_char(0xFE)
    local values = {}
    local start = 1
    local len = #encoded_bytes

    while start <= len do
        local end_pos = encoded_bytes:find(delimiter, start, true)
        if not end_pos then
            if start <= len then
                local chunk = string_sub(encoded_bytes, start)
                if #chunk > 0 then
                    -- 直接调用解码函数，不使用pcall
                    local result = UDK_Composer.Decode(chunk)
                    if result ~= nil then
                        table_insert(values, result)
                    end
                end
            end
            break
        end

        if end_pos > start then
            local chunk = string_sub(encoded_bytes, start, end_pos - 1)
            if #chunk > 0 then
                -- 直接调用解码函数，不使用pcall
                local result = UDK_Composer.Decode(chunk)
                if result ~= nil then
                    table_insert(values, result)
                end
            end
        end
        start = end_pos + 1
    end

    return values
end

return UDK_Composer
