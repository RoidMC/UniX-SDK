-- ==================================================
-- * UniX SDK - Test Unit (Property Utils)
-- * UniX Property属性系统单元测试，
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

-- 使用局部变量保存原始函数，避免修改全局环境
local originalRequire = require

-- 创建一个自定义的 require 函数，用于在加载模块时注入测试配置
local function testRequire(moduleName)
    if moduleName == "src.Public/unix-sdk/utils/udk_property" then
        -- 临时修改包加载路径，加载模块但不执行
        local modulePath = package.searchpath(moduleName, package.path)
        if not modulePath then
            error("无法找到模块: " .. moduleName)
        end

        -- 读取模块文件内容
        local file = io.open(modulePath, "r")
        if not file then
            error("无法读取模块文件: " .. modulePath)
        end
        local content = file:read("*all")
        file:close()

        -- 创建一个隔离的环境来执行模块
        local env = setmetatable({
            -- 提供测试需要的模拟对象
            System = {
                IsStandalone = function() return true end,
                IsServer = function() return false end,
                IsClient = function() return false end,
                SendToAllClients = function() end,
                SendToServer = function() end,
                SendToClient = function() end,
                BindNotify = function() end,
                RegisterEvent = function() end
            },
            MiscService = {
                GetServerTimeToTime = function() return "2025-01-01 00:00:00" end,
                DateYMDHMSToTime = function() return os.time() end
            },
            Log = {
                PrintError = function(msg) print("ERROR: " .. tostring(msg)) end,
                PrintLog = function(msg) print("LOG: " .. tostring(msg)) end,
                PrintWarning = function(msg) print("WARNING: " .. tostring(msg)) end
            },
            Events = {
                ON_BEGIN_PLAY = "ON_BEGIN_PLAY"
            },
            -- 复制所有必要的全局函数
            setmetatable = setmetatable,
            getmetatable = getmetatable,
            pairs = pairs,
            ipairs = ipairs,
            next = next,
            type = type,
            tostring = tostring,
            tonumber = tonumber,
            string = string,
            table = table,
            math = math,
            print = print,
            error = error,
            pcall = pcall,
            xpcall = xpcall,
            select = select,
            unpack = table.unpack,
            rawget = rawget,
            rawset = rawset,
            rawequal = rawequal,
            os = {
                time = os.time,
                date = os.date
            }
        }, {
            __index = function(t, k)
                -- 对于未定义的全局变量，返回nil而不是报错
                return nil
            end
        })

        -- 在隔离环境中执行模块
        local func, err = load(content, "=" .. moduleName, "t", env)
        if not func then
            error("加载模块失败: " .. err)
        end

        -- 执行模块并获取返回值
        local module = func()

        -- 设置测试模式
        if module.SyncConf and module.SyncConf.Status then
            module.SyncConf.Status.UnitTestMode = true
        end

        return module
    else
        -- 对于其他模块，使用原始的require
        return originalRequire(moduleName)
    end
end

-- 使用自定义的require加载模块
local UDK_Property = testRequire("src.Public/unix-sdk/utils/udk_property")

-- 测试辅助函数
local function assert_equal(expected, actual, message)
    if expected ~= actual then
        error(string.format("%s: 期望 %s，实际为 %s", message or "断言失败", tostring(expected), tostring(actual)))
    end
end

local function assert_table_equal(expected, actual, message)
    if type(expected) ~= "table" or type(actual) ~= "table" then
        error(string.format("%s: 两个参数都必须是table类型", message or "断言失败"))
    end

    for k, v in pairs(expected) do
        if type(v) == "table" then
            assert_table_equal(v, actual[k], string.format("%s[%s]", message or "断言失败", tostring(k)))
        else
            assert_equal(v, actual[k], string.format("%s[%s]", message or "断言失败", tostring(k)))
        end
    end

    for k, _ in pairs(actual) do
        if expected[k] == nil then
            error(string.format("%s: 实际表中存在多余的键 %s", message or "断言失败", tostring(k)))
        end
    end
end

-- 测试套件
local tests = {}

-- 1. 基础功能测试
tests.test_basic_operations = function()
    print("测试基础操作...")

    -- 测试设置和获取属性
    local success = UDK_Property.SetProperty("player1", "Number", "level", 10)
    assert_equal(true, success, "设置数值属性")

    local value = UDK_Property.GetProperty("player1", "Number", "level")
    assert_equal(10, value, "获取数值属性")

    -- 测试更新属性
    success = UDK_Property.SetProperty("player1", "Number", "level", 20)
    assert_equal(true, success, "更新数值属性")

    value = UDK_Property.GetProperty("player1", "Number", "level")
    assert_equal(20, value, "获取更新后的数值属性")

    -- 测试删除属性
    success = UDK_Property.DeleteProperty("player1", "Number", "level")
    assert_equal(true, success, "删除属性")

    local exists = UDK_Property.CheckPropertyHasExist("player1", "Number", "level")
    assert_equal(false, exists, "检查属性是否已删除")
end

-- 2. 类型系统测试
tests.test_type_system = function()
    print("测试类型系统...")

    -- 测试布尔值
    local success = UDK_Property.SetProperty("obj1", "Boolean", "flag", true)
    assert_equal(true, success, "设置布尔值")

    -- 测试数值
    success = UDK_Property.SetProperty("obj1", "Number", "count", 42)
    assert_equal(true, success, "设置数值")

    -- 测试字符串
    success = UDK_Property.SetProperty("obj1", "String", "name", "测试对象")
    assert_equal(true, success, "设置字符串")

    -- 测试Vector
    local success = UDK_Property.SetProperty("obj1", "Vector", "position", { X = 1, Y = 2, Z = 3 })
    assert_equal(true, success, "设置Vector")

    -- 测试Color
    success = UDK_Property.SetProperty("obj1", "Color", "color", "#FF0000")
    assert_equal(true, success, "设置Color")

    -- 测试数组
    success = UDK_Property.SetProperty("obj1", "Array", "numbers", { 1, 2, 3, 4, 5 })
    assert_equal(true, success, "设置数组")

    -- 测试Map类型
    success = UDK_Property.SetProperty("obj1", "Map", "metadata", { author = "test", version = "1.0" })
    assert_equal(true, success, "设置Map")

    -- 测试类型验证错误
    local success, errorMsg = UDK_Property.SetProperty("obj1", "Number", "invalid", "not a number")
    assert_equal(false, success, "设置无效类型应该失败")
end

-- 3. 批量操作测试
tests.test_batch_operations = function()
    print("测试批量操作...")

    local properties = {
        Number = {
            health = 100,
            mana = 50
        },
        String = {
            name = "测试角色",
            title = "勇士"
        },
        Boolean = {
            isActive = true,
            isAlive = true
        },
        Map = {
            stats = { strength = 10, agility = 15 }
        }
    }

    local success = UDK_Property.SetBatchProperties("character1", properties)
    assert_equal(true, success, "批量设置属性")

    local allProps = UDK_Property.GetAllProperties("character1")
    assert_table_equal(properties, allProps, "验证批量设置的属性")

    -- 测试按类型获取属性
    local numberProps = UDK_Property.GetPropertiesByType("character1", "Number")
    assert_table_equal(properties.Number, numberProps, "验证按类型获取的属性")
end

-- 4. 数组类型测试
tests.test_array_support = function()
    print("测试数组支持...")

    -- 测试基础类型数组
    local success = UDK_Property.SetProperty("obj2", "Number", "scores", { 95, 87, 92 })
    assert_equal(true, success, "设置数值数组")

    success = UDK_Property.SetProperty("obj2", "String", "tags", { "tag1", "tag2", "tag3" })
    assert_equal(true, success, "设置字符串数组")

    -- 测试复杂类型数组
    local success = UDK_Property.SetProperty("obj2", "Vector", "positions", {
        { X = 1, Y = 1, Z = 1 },
        { X = 2, Y = 2, Z = 2 }
    })
    assert_equal(true, success, "设置Vector数组")

    -- 测试数组验证
    local isArray, errorMsg = UDK_Property.IsArray({ 1, 2, 3 }, "Number")
    assert_equal(true, isArray, "验证数值数组")
end

-- 完全清空数据存储的函数
local function clearAllData()
    -- 清理所有已知的测试对象
    UDK_Property.ClearProperty("player1", nil)
    UDK_Property.ClearProperty("obj1", nil)
    UDK_Property.ClearProperty("character1", nil)
    UDK_Property.ClearProperty("obj2", nil)
    UDK_Property.ClearProperty("obj3", nil)
    UDK_Property.ClearProperty("obj4", nil)
    UDK_Property.ClearProperty("mapObj", nil)
    UDK_Property.ClearProperty("statsObj1", nil)
    UDK_Property.ClearProperty("statsObj2", nil)
    UDK_Property.ClearProperty("typeInfoObj", nil)
    
    -- 通过访问内部数据存储来强制清空（通过设置一个空对象然后清除）
    UDK_Property.SetProperty("_temp", "Number", "_temp", 1)
    UDK_Property.DeleteProperty("_temp", "Number", "_temp")
end

-- 5. 统计功能详细测试
tests.test_stats_detailed = function()
    print("测试统计功能详细...")

    -- 完全清空数据存储
    clearAllData()

    -- 1. 初始状态测试
    local stats = UDK_Property.GetStats()
    assert_equal(0, stats.totalCount, "初始总数应该为0")
    assert_equal(0, (stats.typeCount.Number or 0), "初始Number类型计数应该为0")

    -- 2. 添加属性测试
    print("  测试添加属性统计...")

    -- 添加Number类型属性
    UDK_Property.SetProperty("statsObj1", "Number", "value1", 42)
    stats = UDK_Property.GetStats()
    assert_equal(1, stats.totalCount, "添加一个属性后总数应该为1")
    assert_equal(1, stats.typeCount.Number, "Number类型计数应该为1")

    -- 添加String类型属性
    UDK_Property.SetProperty("statsObj1", "String", "name", "test")
    stats = UDK_Property.GetStats()
    assert_equal(2, stats.totalCount, "添加两个属性后总数应该为2")
    assert_equal(1, stats.typeCount.String, "String类型计数应该为1")

    -- 3. 更新属性测试
    print("  测试更新属性统计...")

    -- 更新已存在的属性
    UDK_Property.SetProperty("statsObj1", "Number", "value1", 100)
    stats = UDK_Property.GetStats()
    assert_equal(2, stats.totalCount, "更新属性后总数应该保持不变")
    assert_equal(1, stats.typeCount.Number, "更新属性后Number类型计数应该保持不变")

    -- 4. 删除属性测试
    print("  测试删除属性统计...")

    -- 删除一个属性
    UDK_Property.DeleteProperty("statsObj1", "Number", "value1")
    stats = UDK_Property.GetStats()
    assert_equal(1, stats.totalCount, "删除一个属性后总数应该为1")
    assert_equal(0, (stats.typeCount.Number or 0), "删除后Number类型计数应该为0")

    -- 5. 批量操作测试
    print("  测试批量操作统计...")

    -- 批量添加属性
    UDK_Property.SetBatchProperties("statsObj2", {
        Number = {
            value1 = 1,
            value2 = 2
        },
        Boolean = {
            flag1 = true,
            flag2 = false
        }
    })

    stats = UDK_Property.GetStats()
    assert_equal(5, stats.totalCount, "批量添加后总数应该正确")
    assert_equal(2, stats.typeCount.Number, "批量添加后Number类型计数应该正确")
    assert_equal(2, stats.typeCount.Boolean, "批量添加后Boolean类型计数应该正确")

    -- 6. 清除属性测试
    print("  测试清除属性统计...")

    -- 清除特定类型的属性
    UDK_Property.ClearProperty("statsObj2", "Number")
    stats = UDK_Property.GetStats()
    assert_equal(3, stats.totalCount, "清除特定类型后总数应该正确")
    assert_equal(0, (stats.typeCount.Number or 0), "清除后Number类型计数应该为0")
    assert_equal(2, stats.typeCount.Boolean, "其他类型计数应该保持不变")

    -- 清除所有属性
    UDK_Property.ClearProperty("statsObj2", nil)
    stats = UDK_Property.GetStats()
    assert_equal(1, stats.totalCount, "清除所有属性后总数应该正确")
    assert_equal(0, (stats.typeCount.Boolean or 0), "清除后Boolean类型计数应该为0")
end

-- 6. 类型信息测试
tests.test_type_info = function()
    print("测试类型信息...")

    -- 设置一些测试数据
    UDK_Property.SetProperty("typeInfoObj", "Number", "value", 42)
    UDK_Property.SetProperty("typeInfoObj", "Array", "list", { 1, 2, 3 })
    UDK_Property.SetProperty("typeInfoObj", "Vector", "pos", { X = 1, Y = 2, Z = 3 })

    -- 测试数组类型信息
    local typeInfo = UDK_Property.GetPropertyTypeInfo("typeInfoObj", "Array", "list")
    assert_equal(true, typeInfo.isArray, "验证数组类型信息")
    assert_equal("Number", typeInfo.elementType, "验证数组元素类型")

    -- 测试Vector类型信息
    typeInfo = UDK_Property.GetPropertyTypeInfo("typeInfoObj", "Vector", "pos")
    assert_equal(false, typeInfo.isArray, "验证Vector非数组类型")

    -- 测试混合类型数组
    UDK_Property.SetProperty("typeInfoObj", "Array", "mixed", { 1, "string", true })
    typeInfo = UDK_Property.GetPropertyTypeInfo("typeInfoObj", "Array", "mixed")
    assert_equal(true, typeInfo.isArray, "验证混合数组类型")
    assert_equal("Any", typeInfo.elementType, "验证混合数组元素类型为Any")
end

-- 6. Map类型测试
tests.test_map_type = function()
    print("测试Map类型...")

    -- 测试设置Map类型
    local success = UDK_Property.SetProperty("mapObj", "Map", "config", {
        debug = true,
        maxPlayers = 100,
        settings = {
            sound = true,
            graphics = "high"
        }
    })
    assert_equal(true, success, "设置Map类型")

    -- 测试获取Map类型
    local config = UDK_Property.GetProperty("mapObj", "Map", "config")
    assert_equal(true, config.debug, "获取Map类型")
    assert_equal(100, config.maxPlayers, "获取Map类型数值")

    -- 测试Map类型的嵌套结构
    success = UDK_Property.SetProperty("mapObj", "Map", "nested", {
        level1 = {
            level2 = {
                value = "deep"
            }
        }
    })
    assert_equal(true, success, "设置嵌套Map")

    -- 测试无效的Map（非字符串键）
    local success, errorMsg = UDK_Property.SetProperty("mapObj", "Map", "invalid",
        { [1] = "numeric key", valid = "string key" })
    assert_equal(false, success, "设置无效Map应该失败")

    -- 测试有效的Map（全部字符串键）
    success = UDK_Property.SetProperty("mapObj", "Map", "valid", { key1 = "value1", key2 = "value2" })
    assert_equal(true, success, "设置有效Map应该成功")
end

-- 7. 错误处理测试
tests.test_error_handling = function()
    print("测试错误处理...")

    -- 测试无效参数
    local success, errorMsg = UDK_Property.SetProperty(nil, "Number", "value", 42)
    assert_equal(false, success, "设置nil对象应该失败")

    -- 测试无效类型
    success, errorMsg = UDK_Property.SetProperty("obj4", "InvalidType", "value", 42)
    assert_equal(false, success, "设置无效类型应该失败")

    -- 测试无效值
    success, errorMsg = UDK_Property.SetProperty("obj4", "Number", "value", "not a number")
    assert_equal(false, success, "设置类型不匹配的值应该失败")
end

-- 运行所有测试
local function run_all_tests()
    print("开始运行UDK_Property模块测试...")
    print("----------------------------------------")

    local totalTests = 0
    local passedTests = 0

    for name, test in pairs(tests) do
        totalTests = totalTests + 1
        local success, errorMsg = pcall(test)
        if success then
            print(string.format("✅ %s 通过", name))
            passedTests = passedTests + 1
        else
            print(string.format("❌ %s 失败: %s", name, errorMsg))
        end
        print("----------------------------------------")
    end

    print(string.format("测试完成: %d/%d 通过", passedTests, totalTests))
    return passedTests == totalTests
end

-- 清理函数
local function cleanup()
    -- 清理所有测试数据
    UDK_Property.ClearProperty("player1", nil)
    UDK_Property.ClearProperty("obj1", nil)
    UDK_Property.ClearProperty("character1", nil)
    UDK_Property.ClearProperty("obj2", nil)
    UDK_Property.ClearProperty("obj3", nil)
    UDK_Property.ClearProperty("obj4", nil)
    UDK_Property.ClearProperty("mapObj", nil)
    UDK_Property.ClearProperty("statsObj1", nil)
    UDK_Property.ClearProperty("statsObj2", nil)
    UDK_Property.ClearProperty("typeInfoObj", nil)
end

-- 运行测试并清理
local success = run_all_tests()
cleanup()

return success
