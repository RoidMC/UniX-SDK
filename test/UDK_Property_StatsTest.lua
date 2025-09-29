-- ==================================================
-- * UniX SDK - Test Unit (Property Stats)
-- * UniX Property属性系统统计功能单元测试，
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
            next = next, -- 添加缺失的next函数
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

print("开始测试 GetStats 功能...")

-- 1. 初始状态测试
local stats = UDK_Property.GetStats()
assert_equal(0, stats.totalCount, "初始总数应该为0")
assert_equal(0, (stats.typeCount.Number or 0), "初始Number类型计数应该为0")

-- 2. 添加属性测试
print("\n测试添加属性...")

-- 添加Number类型属性
UDK_Property.SetProperty("obj1", "Number", "value1", 42)
stats = UDK_Property.GetStats()
assert_equal(1, stats.totalCount, "添加一个属性后总数应该为1")
assert_equal(1, stats.typeCount.Number, "Number类型计数应该为1")

-- 添加String类型属性
UDK_Property.SetProperty("obj1", "String", "name", "test")
stats = UDK_Property.GetStats()
assert_equal(2, stats.totalCount, "添加两个属性后总数应该为2")
assert_equal(1, stats.typeCount.String, "String类型计数应该为1")

-- 3. 更新属性测试
print("\n测试更新属性...")

-- 更新已存在的属性
UDK_Property.SetProperty("obj1", "Number", "value1", 100)
stats = UDK_Property.GetStats()
assert_equal(2, stats.totalCount, "更新属性后总数应该保持不变")
assert_equal(1, stats.typeCount.Number, "更新属性后Number类型计数应该保持不变")

-- 4. 删除属性测试
print("\n测试删除属性...")

-- 删除一个属性
UDK_Property.DeleteProperty("obj1", "Number", "value1")
stats = UDK_Property.GetStats()
assert_equal(1, stats.totalCount, "删除一个属性后总数应该为1")
assert_equal(0, (stats.typeCount.Number or 0), "删除后Number类型计数应该为0")

-- 5. 批量操作测试
print("\n测试批量操作...")

-- 批量添加属性
UDK_Property.SetBatchProperties("obj2", {
    Number = {
        value1 = 1,
        value2 = 2
    },
    Boolean = {
        flag1 = true,
        flag2 = false
    }
}) -- 添加true参数跳过同步

stats = UDK_Property.GetStats()
assert_equal(5, stats.totalCount, "批量添加后总数应该正确")
assert_equal(2, stats.typeCount.Number, "批量添加后Number类型计数应该正确")
assert_equal(2, stats.typeCount.Boolean, "批量添加后Boolean类型计数应该正确")

-- 6. 清除属性测试
print("\n测试清除属性...")

-- 清除特定类型的属性
UDK_Property.ClearProperty("obj2", "Number")
stats = UDK_Property.GetStats()
assert_equal(3, stats.totalCount, "清除特定类型后总数应该正确")
assert_equal(0, (stats.typeCount.Number or 0), "清除后Number类型计数应该为0")
assert_equal(2, stats.typeCount.Boolean, "其他类型计数应该保持不变")

-- 清除所有属性
UDK_Property.ClearProperty("obj2", nil)
stats = UDK_Property.GetStats()
assert_equal(1, stats.totalCount, "清除所有属性后总数应该正确")
assert_equal(0, (stats.typeCount.Boolean or 0), "清除后Boolean类型计数应该为0")

print("\n所有测试通过！✅")

-- 清理测试数据
UDK_Property.ClearProperty("obj1", nil)
UDK_Property.ClearProperty("obj2", nil)
