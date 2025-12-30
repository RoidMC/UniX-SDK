-- ==================================================
-- * UniX SDK - Test Unit (Array Utils)
-- * KV键值对数组测试单元
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
-- * 2025-2026 © RoidMC Studios
-- ==================================================
local UDK_Array = require("Public.unix-sdk.utils.udk_array")

-- 测试代码
local testTable = {}

-- 测试 AddValueByEnum 函数
UDK_Array.AddValueByEnum(testTable, "testKey1", "testValue1")
UDK_Array.AddValueByEnum(testTable, "testKey2", 123)

-- 测试 GetValueByEnum 函数
print(UDK_Array.GetValueByEnum(testTable, "testKey1"))       -- 应输出 "testValue1"
print(UDK_Array.GetValueByEnum(testTable, 123))              -- 应输出 "testKey2"
print(UDK_Array.GetValueByEnum(testTable, "nonExistentKey")) -- 应输出 nil

-- 测试 RemoveValueByEnum 函数
UDK_Array.RemoveValueByEnum(testTable, "testKey1")
print(UDK_Array.GetValueByEnum(testTable, "testKey1")) -- 应输出 nil

UDK_Array.RemoveValueByEnum(testTable, 123)
print(UDK_Array.GetValueByEnum(testTable, "testKey2")) -- 应输出 nil
print(UDK_Array.GetValueByEnum(testTable, 123))        -- 应输出 nil

-- 测试 ReplaceValueByEnum 函数
UDK_Array.AddValueByEnum(testTable, "testKey3", "testValue3")
UDK_Array.AddValueByEnum(testTable, "testKey4", 456)

-- 替换 Key
UDK_Array.ReplaceValueByEnum(testTable, "testKey3", "newTestValue3")
print(UDK_Array.GetValueByEnum(testTable, "testKey3")) -- 应输出 "newTestValue3"

-- 替换 Value
UDK_Array.ReplaceValueByEnum(testTable, 456, "newTestValue4")
print(UDK_Array.GetValueByEnum(testTable, "testKey4")) -- 应输出 "newTestValue4"

-- 测试函数
local myTable = {
    abc = "value1",
    ABC = "value2",
    xyz = "value3",
    ABCD = "11value4"
}

local filteredTable = UDK_Array.ForKeyToValueRegX(myTable, "ABCD")

-- 打印新的表的内容
for key, value in pairs(filteredTable) do
    print(key, value)
end