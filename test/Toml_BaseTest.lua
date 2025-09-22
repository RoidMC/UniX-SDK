-- ==================================================
-- * UniX SDK - Test Unit (Toml Utils)
-- * 基础测试
-- *
-- * Warning:
-- * 测试单元必须在标准Lua环境下运行
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
local UDK_Toml_Lib = require("src.Public.unix-sdk.utils.udk_toml")

-- 测试输出函数
local function test_output(name, value)
    print("\n=== Test:", name, "===")
    if type(value) == "string" then
        print(string.format("Raw string length: %d", #value))
        print(string.format("Content: [%s]", value))
        -- 显示转义字符
        local escaped = value:gsub("[\r\n\t\f\b]", {
            ["\r"] = "\\r",
            ["\n"] = "\\n",
            ["\t"] = "\\t",
            ["\f"] = "\\f",
            ["\b"] = "\\b"
        })
        print(string.format("With visible escapes: [%s]", escaped))
    else
        print(string.format("Value: %s", tostring(value)))
    end
end

-- 测试用例
local toml_string = [[
title = "Example"

basic_string = "Hello, World!"
escaped_string = "Tab:\tNewline:\nQuote:\""

[owner]
name = "Tom Preston-Werner"
dob = 1979-05-27T07:32:00Z  # First class dates

[database]
server = "192.168.1.1"
ports = [ 8000, 8001, 8002 ]
connection_max = 5000
enabled = true

[servers.alpha]
ip = "10.0.0.1"
dc = "eqdc10"

[servers.beta]
ip = "10.0.0.2"
dc = "eqdc10"

[dates]
local_date = 2023-10-05
local_time = 14:30:00
local_datetime = 2023-10-05T14:30:00
offset_datetime = 2023-10-05T14:30:00+02:00
hex_int = 0x1A
oct_int = 0o32
bin_int = 0b11010
byte_str = "normal string #TEST"
byte_str2 = 'single quoted string'
byte_str3 = ""normal string 2""

[nested_tables]
nested = { key = "value" }

# 测试用例：数组中的混合类型
[mixed_array]
values = [ 1, 2.5, "string", true, false, 0x1F, 0o37, 0b11111 ]

# 测试用例：内联表
[inline_tables]
inline = { key1 = "value1", key2 = 42, key3 = [1, 2, 3] }

# 测试用例：嵌套数组和内联表
[nested_arrays]
nested = [ [1, 2], [3, 4], { key = "value" } ]

# 测试用例：注释
[comments]
# 这是一个注释
value = "with a comment"

# 测试用例：嵌套表
[nested_tables.nested]
key = "value"
another_key = "another_value"

# 测试用例：多行字符串
[multiline_strings]
text1 = """
This is a multiline string
with multiple lines
and "quotes" are allowed
"""

text2 = '''
This is also a multiline string
with 'single quotes'
and multiple lines
'''

# 测试用例：转义字符
[escape_sequences]
basic = "Line1\nLine2\tTabbed\rCarriage Return"
quotes = "Contains \"double quotes\" and \'single quotes\'"
unicode = "Unicode: \u0041\u0042\u0043"
backslash = "Backslash: \\"

# 测试用例：混合多行和转义
[mixed_content]
complex = """
Line1 with \t tab
Line2 with \n newline
Line3 with \u0041 unicode
"""
]]

local data = UDK_Toml_Lib.Parse(toml_string)

-- 打印解析结果
local function print_table(t, indent)
    indent = indent or ""
    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent .. k .. " = {")
            print_table(v, indent .. "  ")
            print(indent .. "}")
        else
            print(indent .. k .. " = " .. tostring(v))
        end
    end
end

print("=== Basic Tests ===")
print_table(data)

--[[]]
print("\n=== Multiline String Tests ===")
print("Text1:")
print(data.multiline_strings.text1)
print("\nText2:")
print(data.multiline_strings.text2)

print("\n=== Escape Sequence Tests ===")
print("Basic escapes:", data.escape_sequences.basic)
print("Quoted escapes:", data.escape_sequences.quotes)
print("Unicode escapes:", data.escape_sequences.unicode)
print("Backslash:", data.escape_sequences.backslash)

print("\n=== Mixed Content Test ===")
print("Complex multiline with escapes:")
print(data.mixed_content.complex)

-- 验证其他功能是否正常工作
print("\n=== Original Functionality Tests ===")
print("Owner name:", data.owner.name)
print("Database server:", data.database.server)
print("Database port 2:", data.database.ports[2])
print("Servers alpha IP:", data.servers.alpha.ip)

print("Local date:", data.dates.local_date)
print("Local time:", data.dates.local_time)
print("Local datetime:", data.dates.local_datetime)
print("Offset datetime:", data.dates.offset_datetime)
print("Hex int:", data.dates.hex_int)
print("Oct int:", data.dates.oct_int)
print("Bin int:", data.dates.bin_int)
print("Byte string:", data.dates.byte_str)
print("Byte string 2:", data.dates.byte_str2)
print("Byte string 3:", data.dates.byte_str3)

print("\n=== Array and Table Tests ===")
print("Mixed array value 1:", data.mixed_array.values[1])
print("Mixed array value 3:", data.mixed_array.values[3])
print("Inline table key1:", data.inline_tables.inline.key1)
print("Nested array value:", data.nested_arrays.nested[1][1])
print("Nested table value:", data.nested_tables.nested.key)


-- 测试基本字符串
test_output("Basic string", data.basic_string)
test_output("Escaped string", data.escaped_string)

-- 测试多行字符串
print("\n=== Multiline String Tests ===")
test_output("Text1", data.multiline_strings.text1)
test_output("Text2", data.multiline_strings.text2)

-- 测试转义序列
print("\n=== Escape Sequence Tests ===")
test_output("Basic escapes", data.escape_sequences.basic)
test_output("Quoted escapes", data.escape_sequences.quotes)
test_output("Backslash", data.escape_sequences.backslash)

-- 测试混合内容
print("\n=== Mixed Content Test ===")
test_output("Complex multiline", data.mixed_content.complex)