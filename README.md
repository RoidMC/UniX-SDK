<img src="./docs/imgs/banner.png" alt="Banner" height="200">

# UniX SDK

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/RoidMC/UniX-SDK)
![GitHub License](https://img.shields.io/github/license/RoidMC/UniX-SDK?style=flat-square)
![GitHub Stars](https://img.shields.io/github/stars/RoidMC/UniX-SDK?style=flat-square)
![GitHub Forks](https://img.shields.io/github/forks/RoidMC/UniX-SDK?style=flat-square)
![GitHub Issues](https://img.shields.io/github/issues/RoidMC/UniX-SDK?style=flat-square)
![GitHub Last Updated](https://img.shields.io/github/last-commit/RoidMC/UniX-SDK?style=flat-square)
![SDK Version](https://img.shields.io/badge/version-0.0.4-blue?style=flat-square)

- 🪄 **为元梦之星Lua2.0开发**
- 📚 **包含常用功能封装**
- 📦 **模块化设计**
- 📦 **开箱即用**
- 🚀 **快速开发**

## 🚒 许可证

UniX SDK采用双重许可：

1. **Mozilla Public License 2.0 (MPL-2.0)**
   - 允许将SDK与专有代码结合使用
   - 对SDK的修改必须在相同许可下发布
   - 完整许可证文本请见[LICENSE](./LICENSE)文件

2. **归属要求**
   - 使用UniX SDK的应用必须显示"Powered by UniX SDK"
   - 具体要求请见[ATTRIBUTION](./docs/ATTRIBUTION.md)文件

## 🚀 快速开始

### 在Server目录中添加Unix SDK

> 下载SDK后在根目录下创建`Public`并在内创建`UniX-SDK`文件夹，将SDK文件放入其中

> 您也可以根据项目需求自行选择`SDK`路径，但您需要手动修改[main.lua](./unix-sdk/main.lua)内的引用路径

> 我们推荐您使用`_G`在`GameEntry`下全局注册，这样只需要在`GameEntry`下引用一次即可

```lua
-- GameEntry.lua

-- 加载SDK全部功能
-- 在_G全局变量中注册UDK（SDK推荐注册方法）
_G.UDK = require("Public.UniX-SDK.main")

local Enum_Test_Array = {
    Test="Hello World!",
    Test1="UniX SDK is Awesome!",
    Foo="Foo",
    Bar="Bar"
    }
local Toml_Test_String = [[
[Info]
Name = "Toml Test"
]]

-- 定义Toml解析数据器
local Toml_Parse_Data = UDK.TomlUtils.Parse(Toml_Test_String)
-- 定义UDK.Array.ForKeyToValueRegX引用，如果需要匹配任何字符，请使用"."作为正则表达式
local UDK_Enum_RegX_Test_Array = UDK.Array.ForKeyToValueRegX(Enum_Test_Array, "Test")

-- 使用SDK打印枚举数组数据，输出结果为Hello World!
Log:PrintLog( UDK.Array.GetValueByEnum(Enum_Test_Array, "Test"))
-- 使用SDK正则获取数组内的数据，输出结果为Test*数据（Test/Test1）
for key, value in pairs (UDK_Enum_RegX_Test_Array) do
    Log:PrintLog(value)
end

-- Toml解析测试，输出结果为Toml Test
Log:PrintLog(Toml_Parse_Data.Info.Name)

-- 使用SDK设置原生界面可见性，输出结果为12个原生界面可见
UDK.UI.SetNativeInterfaceVisible({0,1,2,3,4,5,6,7,8,9,10,11}, true)
UDK.UI.SetNativeInterfaceVisible(
    { "Promotion", "Countdown", "TargetPoints", "CampPoints", "PersonalPoints", "Leaderboard", "HealthBar", "Settings",
        "RemainingPlayers", "MapHint", "EmotesAndActions", "QuickChat" }, true)
```

## 🤝 贡献

欢迎贡献代码、报告问题或提出改进建议。请查阅[CONTRIBUTING](./docs/CONTRIBUTING.md)了解如何参与项目开发。

## 📄 归属声明

使用UniX SDK的应用程序必须在用户界面中显示"Powered by UniX SDK"，详细要求请参阅[ATTRIBUTION](./docs/ATTRIBUTION.md)。

> [!IMPORTANT]
> 在使用SDK时请勿占用SDK保留的NetMsg ID，范围200000-250000，占用导致的报错不在我们的处理范围内

---

2025-2026 © [RoidMC Studios](https://www.roidmc.com) | [MPL-2.0 License](./LICENSE)
<!--
Ciallo～(∠・ω )⌒☆
-->