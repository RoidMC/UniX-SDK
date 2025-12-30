-- ==================================================
-- * UniX SDK - Test Unit (Toml Utils)
-- * 多行数组测试
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

-- 直接加载模块文件
local UDK_Toml_Lib = require("src.Public.unix-sdk.utils.udk_toml")

-- 测试多行数组解析
local function test_multiline_arrays()
    print("开始测试多行数组解析...")

    -- 测试用例1: 基本多行数组
    local toml1 = [[
basic_array = [
    1,
    2,
    3
]
]]
    local result1 = UDK_Toml_Lib.Parse(toml1)
    assert(type(result1.basic_array) == "table", "基本多行数组解析失败")
    assert(#result1.basic_array == 3, "基本多行数组长度不正确")
    assert(result1.basic_array[1] == 1, "基本多行数组元素1不正确")
    assert(result1.basic_array[2] == 2, "基本多行数组元素2不正确")
    assert(result1.basic_array[3] == 3, "基本多行数组元素3不正确")
    print("测试用例1通过: 基本多行数组")

    -- 测试用例2: 包含字符串的多行数组
    local toml2 = [[
string_array = [
    "apple",
    "banana",
    "cherry"
]
]]
    local result2 = UDK_Toml_Lib.Parse(toml2)
    assert(type(result2.string_array) == "table", "字符串多行数组解析失败")
    assert(#result2.string_array == 3, "字符串多行数组长度不正确")
    assert(result2.string_array[1] == "apple", "字符串多行数组元素1不正确")
    assert(result2.string_array[2] == "banana", "字符串多行数组元素2不正确")
    assert(result2.string_array[3] == "cherry", "字符串多行数组元素3不正确")
    print("测试用例2通过: 字符串多行数组")

    -- 测试用例3: 嵌套多行数组
    local toml3 = [[
nested_array = [
    [1, 2],
    [3, 4],
    [5, 6]
]
]]
    local result3 = UDK_Toml_Lib.Parse(toml3)
    assert(type(result3.nested_array) == "table", "嵌套多行数组解析失败")
    assert(#result3.nested_array == 3, "嵌套多行数组长度不正确")
    assert(type(result3.nested_array[1]) == "table", "嵌套多行数组元素1类型不正确")
    assert(#result3.nested_array[1] == 2, "嵌套多行数组元素1长度不正确")
    assert(result3.nested_array[1][1] == 1, "嵌套多行数组元素1.1不正确")
    assert(result3.nested_array[1][2] == 2, "嵌套多行数组元素1.2不正确")
    print("测试用例3通过: 嵌套多行数组")

    -- 测试用例4: 混合类型多行数组
    local toml4 = [[
mixed_array = [
    1,
    "string",
    true,
    [1, 2]
]
]]
    local result4 = UDK_Toml_Lib.Parse(toml4)
    assert(type(result4.mixed_array) == "table", "混合类型多行数组解析失败")
    assert(#result4.mixed_array == 4, "混合类型多行数组长度不正确")
    assert(result4.mixed_array[1] == 1, "混合类型多行数组元素1不正确")
    assert(result4.mixed_array[2] == "string", "混合类型多行数组元素2不正确")
    assert(result4.mixed_array[3] == true, "混合类型多行数组元素3不正确")
    assert(type(result4.mixed_array[4]) == "table", "混合类型多行数组元素4类型不正确")
    print("测试用例4通过: 混合类型多行数组")

    -- 测试用例5: 复杂嵌套多行数组
    local toml5 = [[
complex_array = [
    {key1 = "value1", key2 = 42},
    [
        1,
        2,
        [3, 4]
    ],
    "string"
]
]]
    local result5 = UDK_Toml_Lib.Parse(toml5)
    assert(type(result5.complex_array) == "table", "复杂嵌套多行数组解析失败")
    assert(#result5.complex_array == 3, "复杂嵌套多行数组长度不正确")
    assert(type(result5.complex_array[1]) == "table", "复杂嵌套多行数组元素1类型不正确")
    assert(result5.complex_array[1].key1 == "value1", "复杂嵌套多行数组元素1.key1不正确")
    assert(result5.complex_array[1].key2 == 42, "复杂嵌套多行数组元素1.key2不正确")
    assert(type(result5.complex_array[2]) == "table", "复杂嵌套多行数组元素2类型不正确")
    assert(#result5.complex_array[2] == 3, "复杂嵌套多行数组元素2长度不正确")
    assert(result5.complex_array[2][3][1] == 3, "复杂嵌套多行数组元素2.3.1不正确")
    print("测试用例5通过: 复杂嵌套多行数组")

    -- 测试用例6: 带注释的多行数组
    local toml6 = [[
comment_array = [
    # 这是注释
    1,
    2, # 行内注释
    3
]
]]
    local result6 = UDK_Toml_Lib.Parse(toml6)
    assert(type(result6.comment_array) == "table", "带注释的多行数组解析失败")
    assert(#result6.comment_array == 3, "带注释的多行数组长度不正确")
    print("测试用例6通过: 带注释的多行数组")

    print("所有多行数组测试通过!")
end

-- 运行测试
test_multiline_arrays()