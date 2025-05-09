local UDK = require("Floder.SDKPath")

local Lang = [[
    [zh-CN]
    language = "简体中文",
    string = "这是一串测试内容"

    [en-US]
    language = "English",
    string = "This is a test content"
]]

local data = UDK.TomlUtils.Parse(Lang)
local resultCN = UDK.I18N.I18NGetKey("string", "zh-CN", data)
local resultEN = UDK.I18N.I18NGetKey("string", "en-US", data)

-- 打印日志 | Print Log
print(resultCN) -- output: 这是一串测试内容
print(resultEN) -- Output: This is a test content