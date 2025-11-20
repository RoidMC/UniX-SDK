# UniX SDK - NetMsg ID 冲突检测工具

## 简介

这是一个用于检测项目中网络消息ID冲突的工具。它可以扫描项目中的所有Lua文件，提取NetMsg ID定义，并检测是否有重复的ID或违反保留ID范围的情况。

## 功能特点

- 扫描项目中所有Lua文件，提取NetMsg ID定义
- 检测是否有重复的ID，避免网络消息冲突
- 检测是否有非SDK模块使用了SDK保留的ID范围
- 生成详细的报告，显示所有ID的使用情况
- 同时生成文本和JSON格式的报告，方便查看和进一步处理

## 使用方法

### Windows

1. 双击运行 `run_netmsg_checker.bat`
2. 等待检测完成
3. 查看生成的报告文件：
   - 文本报告：`src/Public/UniX-SDK/tools/netmsg_report.txt`
   - JSON报告：`src/Public/UniX-SDK/tools/netmsg_report.json`

### Linux/macOS

1. 打开终端，进入工具所在目录
2. 执行命令：`chmod +x run_netmsg_checker.sh`
3. 执行命令：`./run_netmsg_checker.sh`
4. 等待检测完成
5. 查看生成的报告文件

### 直接使用Python

1. 打开终端，进入工具所在目录
2. 执行命令：`python netmsg_conflict_checker.py [项目根目录]`
   - 如果不提供项目根目录参数，将使用当前工作目录作为项目根目录
3. 等待检测完成
4. 查看生成的报告文件

## 配置说明

工具的配置在Python脚本中的`config`字典中定义，包括：

- `scan_dirs`: 要扫描的目录列表（相对于项目根目录）
- `file_extensions`: 要扫描的文件扩展名列表
- `reserved_ranges`: 保留的ID范围列表
- `output_path`: 文本报告输出路径
- `json_output_path`: JSON报告输出路径

如需修改配置，请编辑`netmsg_conflict_checker.py`文件中的相应部分。

## 注意事项

- SDK保留NetMsg ID范围：200000-250000
- 游戏项目应避免使用此范围内的ID
- 工具需要Python 3.6或更高版本

## 报告内容说明

生成的报告包含以下几个部分：

1. **ID冲突情况**：列出所有在多个地方定义的ID
2. **保留范围违规情况**：列出所有非SDK模块使用了SDK保留ID范围的情况
3. **所有发现的NetMsg ID**：列出所有发现的NetMsg ID及其定义位置

## 常见问题

**Q: 工具无法运行，提示"未检测到Python安装"**

A: 请确保已安装Python 3.6或更高版本，并且已将Python添加到系统PATH中。

**Q: 工具没有扫描到我的文件**

A: 请检查配置中的`scan_dirs`和`file_extensions`是否正确设置。默认只扫描`.lua`文件。

**Q: 如何添加新的保留ID范围？**

A: 在`netmsg_conflict_checker.py`文件中找到`reserved_ranges`配置，按照示例格式添加新的范围。