#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
UniX SDK - NetMsg Conflict Checker
Version: 1.0.0

License: MPL-2.0
See LICENSE file for details.

2025 © RoidMC Studios

网络消息ID冲突检测工具

用途：
- 扫描项目中所有Lua文件，提取NetMsg ID定义
- 检测是否有重复的ID，避免网络消息冲突
- 生成报告，显示所有ID的使用情况

使用方法：
- 在命令行中运行此脚本: python netmsg_conflict_checker.py [项目根目录]
- 查看生成的报告文件

注意：
- SDK保留NetMsg ID范围：200000-250000
- 游戏项目应避免使用此范围内的ID
"""

import os
import re
import sys
import json
import argparse
import traceback
import codecs
import logging
from datetime import datetime
from collections import defaultdict
from typing import Dict, List, Set, Tuple, Any, Optional

# 确保正确处理中文
if sys.platform == 'win32':
    # Windows平台特殊处理
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

class NetMsgConflictChecker:
    """网络消息ID冲突检测器"""
    
    def __init__(self, project_root: str):
        """
        初始化检测器
        
        Args:
            project_root: 项目根目录路径
        """
        # 规范化项目根目录路径，确保使用正确的路径分隔符
        self.project_root = os.path.abspath(project_root)
        
        # 检测是否在工具目录下运行，如果是则自动向上查找项目根目录
        tools_dir = os.path.join("src", "Public", "UniX-SDK", "tools")
        if os.path.normpath(self.project_root).endswith(os.path.normpath(tools_dir)):
            # 当前在tools目录下，向上四级找到项目根目录
            self.project_root = os.path.abspath(os.path.join(self.project_root, "..", "..", "..", ".."))
            print(f"检测到在工具目录下运行，已自动调整项目根目录为: {self.project_root}")
        
        # 配置
        self.config = {
            # 扫描目录（相对于项目根目录）
            "scan_dirs": [
                os.path.join("src", "Public"),
                os.path.join("src"),
                # 添加其他需要扫描的目录
            ],
            
            # 文件扩展名过滤
            "file_extensions": [
                ".lua"
            ],
            
            # SDK保留ID范围
            "reserved_ranges": [
                {"name": "UniX SDK", "min": 200000, "max": 250000}
                # 可以添加其他保留范围
            ],
            
            # 输出文件路径（相对于项目根目录）
            "output_path": os.path.join("src", "Public", "UniX-SDK", "tools", "netmsg_report.txt"),
            
            # 输出JSON文件路径（相对于项目根目录）
            "json_output_path": os.path.join("src", "Public", "UniX-SDK", "tools", "netmsg_report.json")
        }
        
        # 确保输出路径是相对于项目根目录的
        tools_dir = os.path.join("src", "Public", "UniX-SDK", "tools")
        if not os.path.exists(os.path.join(self.project_root, tools_dir)):
            print(f"警告: 工具目录不存在，将在当前目录创建报告文件")
            self.config["output_path"] = "netmsg_report.txt"
            self.config["json_output_path"] = "netmsg_report.json"
        
        # 存储发现的所有NetMsg ID
        self.discovered_ids = {}  # {id: [{name, file}, ...]}
        
        # 存储ID冲突信息
        self.conflicts = {}  # {id: [{name, file}, ...]}
        
        # 存储在保留范围内的非SDK ID
        self.reserved_violations = defaultdict(list)  # {range_name: [{name, id, file}, ...]}
        
        # 正则表达式模式 - 使用非贪婪匹配和限制重复次数，防止灾难性回溯
        self.patterns = [
            r'\.NetMsg\s*?=\s*?{([^}]{1,10000})}',      # 标准定义模式，限制内容大小
            r'\.NetMsg\.(\w{1,100})\s*?=\s*?(\d{1,20})', # 单行定义模式，限制标识符和数字长度
            r'NetMsg\s*?=\s*?{([^}]{1,10000})}',        # 局部变量定义模式，限制内容大小
            r'local\s+NetMsg\s*?=\s*?{([^}]{1,10000})}'  # 完整局部变量定义，限制内容大小
        ]
        
        # 键值对模式 - 同样限制标识符和数字长度
        self.key_value_pattern = re.compile(r'(\w{1,100})\s*?=\s*?(\d{1,20})')
    
    def scan_directory(self, dir_path: str) -> List[str]:
        """
        递归扫描目录中的所有文件
        
        Args:
            dir_path: 要扫描的目录路径
            
        Returns:
            符合条件的文件路径列表
        """
        result = []
        # 确保路径分隔符正确
        dir_path = dir_path.replace('/', os.sep)
        abs_dir_path = os.path.join(self.project_root, dir_path)
        
        if not os.path.exists(abs_dir_path):
            print(f"警告: 目录不存在: {abs_dir_path}")
            return result
        
        print(f"正在扫描目录: {dir_path}")
        
        for root, _, files in os.walk(abs_dir_path):
            for file in files:
                # 检查文件扩展名
                if any(file.endswith(ext) for ext in self.config["file_extensions"]):
                    # 获取相对于项目根目录的路径
                    rel_path = os.path.relpath(os.path.join(root, file), self.project_root)
                    # 统一使用系统路径分隔符
                    rel_path = rel_path.replace('\\', os.sep)
                    result.append(rel_path)
        
        return result
    
    def parse_file(self, file_path: str) -> None:
        """
        解析文件中的NetMsg ID定义
        
        Args:
            file_path: 文件路径（相对于项目根目录）
        """
        abs_path = os.path.join(self.project_root, file_path)
        
        # 检查文件是否存在
        if not os.path.exists(abs_path):
            print(f"错误: 文件不存在: {abs_path}")
            return
            
        # 检查文件大小，避免处理过大的文件
        try:
            file_size = os.path.getsize(abs_path)
            if file_size > 10 * 1024 * 1024:  # 10MB
                print(f"警告: 文件过大 ({file_size / 1024 / 1024:.2f} MB)，跳过: {file_path}")
                return
        except OSError as e:
            print(f"无法获取文件大小: {abs_path}, 错误: {e}")
            return
        
        try:
            # 尝试多种编码方式打开文件
            encodings = ['utf-8', 'utf-8-sig', 'gbk', 'gb2312', 'latin1']
            content = None
            
            for encoding in encodings:
                try:
                    with codecs.open(abs_path, 'r', encoding=encoding) as file:
                        # 限制读取大小，避免内存问题
                        content = file.read(5 * 1024 * 1024)  # 最多读取5MB
                    print(f"成功使用 {encoding} 编码打开文件: {file_path}")
                    break
                except UnicodeDecodeError:
                    continue
                except MemoryError:
                    print(f"内存不足，无法处理文件: {file_path}")
                    return
                except Exception as e:
                    print(f"尝试使用 {encoding} 编码打开文件时出错: {e}")
                    continue
            
            if content is None:
                print(f"无法使用任何编码打开文件: {abs_path}")
                return
        except Exception as e:
            print(f"无法打开文件: {abs_path}, 错误: {e}")
            return
        
        # 使用所有模式查找NetMsg定义
        for pattern in self.patterns:
            for match in re.finditer(pattern, content):
                if len(match.groups()) == 1:
                    # 处理块定义 (如 NetMsg = {...})
                    block = match.group(1)
                    self.process_netmsg_block(block, file_path)
                elif len(match.groups()) == 2:
                    # 处理单行定义 (如 NetMsg.Key = Value)
                    key, value = match.groups()
                    try:
                        id_value = int(value)
                        self.register_netmsg_id(key, id_value, file_path)
                    except ValueError:
                        pass
    
    def process_netmsg_block(self, block: str, file_path: str) -> None:
        """
        处理NetMsg定义块
        
        Args:
            block: NetMsg定义块内容
            file_path: 文件路径
        """
        # 查找形如 Key = Value 的定义
        for match in self.key_value_pattern.finditer(block):
            key, value = match.groups()
            try:
                id_value = int(value)
                self.register_netmsg_id(key, id_value, file_path)
            except ValueError:
                pass
    
    def register_netmsg_id(self, name: str, id_value: int, file_path: str) -> None:
        """
        注册发现的NetMsg ID
        
        Args:
            name: ID名称
            id_value: ID值
            file_path: 文件路径
        """
        if id_value not in self.discovered_ids:
            self.discovered_ids[id_value] = []
        
        # 检查是否已经存在相同的定义（相同名称和文件）
        for existing in self.discovered_ids[id_value]:
            if existing["name"] == name and existing["file"] == file_path:
                # 已经存在相同的定义，不重复添加
                return
        
        # 添加新的定义
        self.discovered_ids[id_value].append({
            "name": name,
            "file": file_path
        })
        
        # 检查是否存在真正的冲突（不同名称或不同文件）
        if len(self.discovered_ids[id_value]) > 1:
            # 检查是否有不同的名称或文件
            names_files = set((item["name"], item["file"]) for item in self.discovered_ids[id_value])
            if len(names_files) > 1:
                # 真正的冲突：不同名称或不同文件
                self.conflicts[id_value] = self.discovered_ids[id_value]
        
        # 检查是否违反保留范围
        self.check_reserved_violation(name, id_value, file_path)
    
    def check_reserved_violation(self, name: str, id_value: int, file_path: str) -> None:
        """
        检查是否违反保留范围
        
        Args:
            name: ID名称
            id_value: ID值
            file_path: 文件路径
        """
        for range_info in self.config["reserved_ranges"]:
            if range_info["min"] <= id_value <= range_info["max"]:
                # 检查是否是SDK自己的ID（通过文件路径判断）
                is_sdk = "UniX-SDK" in file_path
                
                if not is_sdk:
                    self.reserved_violations[range_info["name"]].append({
                        "name": name,
                        "id": id_value,
                        "file": file_path
                    })
    
    def run(self) -> None:
        """运行检查"""
        try:
            print("开始检查NetMsg ID冲突...")
            
            # 初始化数据结构
            self.discovered_ids = {}
            self.conflicts = {}
            self.reserved_violations = defaultdict(list)
            
            # 扫描所有配置的目录
            for dir_path in self.config["scan_dirs"]:
                print(f"扫描目录: {dir_path}")
                files = self.scan_directory(dir_path)
                
                if not files:
                    print(f"警告: 在目录 {dir_path} 中未找到任何 {', '.join(self.config['file_extensions'])} 文件")
                    continue
                
                print(f"在 {dir_path} 中找到 {len(files)} 个文件")
                
                for file_path in files:
                    self.parse_file(file_path)
            
            # 生成报告
            self.generate_report()
            
            # 输出统计信息
            print(f"\n检查完成! 统计信息:")
            print(f"- 发现的NetMsg ID总数: {len(self.discovered_ids)}")
            
            # 计算真正的冲突数量
            real_conflict_count = len(self.conflicts)
            if real_conflict_count > 0:
                print(f"- 冲突的ID数量: {real_conflict_count} (不同名称或不同文件的相同ID)")
            else:
                print(f"- 冲突的ID数量: {real_conflict_count}")
                
            # 违反保留范围的ID
            violation_count = sum(len(v) for v in self.reserved_violations.values())
            print(f"- 违反保留范围的ID数量: {violation_count}")
            
        except Exception as e:
            print(f"运行过程中发生错误: {e}")
            print(f"错误详情: {traceback.format_exc()}")
        
        # 生成JSON报告
        self.generate_json_report()
        
        print(f"检查完成，报告已生成: {os.path.join(self.project_root, self.config['output_path'])}")
        print(f"JSON报告已生成: {os.path.join(self.project_root, self.config['json_output_path'])}")
    
    def generate_report(self) -> None:
        """生成报告"""
        # 统计信息
        total_files = sum(len(self.scan_directory(dir_path)) for dir_path in self.config["scan_dirs"])
        
        report = [
            "============================================",
            "  UniX SDK - NetMsg ID 冲突检测报告",
            "============================================",
            "",
            f"检测时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            f"扫描文件总数: {total_files}",
            f"发现的NetMsg ID总数: {len(self.discovered_ids)}",
            f"冲突的ID数量: {len(self.conflicts)}",
            f"违反保留范围的ID数量: {sum(len(v) for v in self.reserved_violations.values())}",
            "",
            "1. ID冲突情况",
            "--------------------------------------------"
        ]
        
        # 添加冲突信息
        if self.conflicts:
            report.append(f"发现 {len(self.conflicts)} 个ID冲突:")
            for id_value, usages in sorted(self.conflicts.items()):
                # 获取不同的名称和文件组合
                names_files = set((item["name"], item["file"]) for item in usages)
                report.append(f"\nID: {id_value} 存在 {len(names_files)} 处不同定义:")
                
                # 按文件分组显示
                files_dict = {}
                for usage in usages:
                    if usage["file"] not in files_dict:
                        files_dict[usage["file"]] = []
                    if usage["name"] not in files_dict[usage["file"]]:
                        files_dict[usage["file"]].append(usage["name"])
                
                # 显示每个文件中的定义
                for file_path, names in sorted(files_dict.items()):
                    if len(names) == 1:
                        report.append(f"  - {names[0]} ({file_path})")
                    else:
                        report.append(f"  - 文件 {file_path} 中有多个定义:")
                        for name in sorted(names):
                            report.append(f"    * {name}")
        else:
            report.append("未发现ID冲突。")
            
        report.append("")
        report.append("2. 保留范围违规情况")
        report.append("--------------------------------------------")
        
        if self.reserved_violations:
            for range_name, violations in self.reserved_violations.items():
                report.append(f"\n范围 \"{range_name}\" 中发现 {len(violations)} 个非授权使用:")
                for v in violations:
                    report.append(f"  - {v['name']} = {v['id']} ({v['file']})")
        else:
            report.append("未发现保留范围违规。")
            
        report.append("")
        report.append("3. 所有发现的NetMsg ID (按ID排序)")
        report.append("--------------------------------------------")
        
        # 按ID排序
        for id_value in sorted(self.discovered_ids.keys()):
            usage = self.discovered_ids[id_value][0]  # 取第一个使用情况
            report.append(f"{id_value}: {usage['name']} ({usage['file']})")
            
        # 添加按名称排序的索引
        report.append("")
        report.append("4. 所有发现的NetMsg ID (按名称排序)")
        report.append("--------------------------------------------")
        
        # 按名称排序
        sorted_by_name = sorted(
            [(usage[0]['name'], id_value, usage[0]['file']) 
             for id_value, usage in self.discovered_ids.items()],
            key=lambda x: x[0].lower()
        )
        
        for name, id_value, file_path in sorted_by_name:
            report.append(f"{name}: {id_value} ({file_path})")
        
        # 写入报告文件
        output_path = os.path.join(self.project_root, self.config["output_path"])
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        try:
            # 使用codecs模块确保正确处理中文
            with codecs.open(output_path, 'w', encoding='utf-8') as file:
                file.write('\n'.join(report))
            print(f"报告已成功写入: {output_path}")
        except Exception as e:
            print(f"无法写入报告文件: {output_path}, 错误: {e}")
            print(f"错误详情: {traceback.format_exc()}")
            # 打印到控制台
            print('\n'.join(report))
    
    def generate_json_report(self) -> None:
        """生成JSON格式的报告"""
        # 处理冲突数据，确保JSON可序列化
        conflicts_json = {}
        for id_value, usages in self.conflicts.items():
            conflicts_json[str(id_value)] = [
                {"name": usage["name"], "file": usage["file"]} 
                for usage in usages
            ]
        
        # 处理发现的ID数据，确保JSON可序列化
        discovered_json = {}
        for id_value, usages in self.discovered_ids.items():
            discovered_json[str(id_value)] = [
                {"name": usage["name"], "file": usage["file"]} 
                for usage in usages
            ]
        
        # 处理违规数据
        violations_json = {}
        for range_name, violations in self.reserved_violations.items():
            violations_json[range_name] = [
                {"name": v["name"], "id": v["id"], "file": v["file"]}
                for v in violations
            ]
        
        report = {
            "timestamp": datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            "conflicts": conflicts_json,
            "reserved_violations": violations_json,
            "discovered_ids": discovered_json,
            "statistics": {
                "total_ids": len(self.discovered_ids),
                "conflict_count": len(self.conflicts),
                "violation_count": sum(len(v) for v in self.reserved_violations.values())
            }
        }
        
        # 写入JSON报告文件
        json_output_path = os.path.join(self.project_root, self.config["json_output_path"])
        os.makedirs(os.path.dirname(json_output_path), exist_ok=True)
        
        try:
            with codecs.open(json_output_path, 'w', encoding='utf-8') as file:
                json.dump(report, file, ensure_ascii=False, indent=2)
            print(f"JSON报告已成功写入: {json_output_path}")
        except Exception as e:
            print(f"无法写入JSON报告文件: {json_output_path}, 错误: {e}")
            print(f"错误详情: {traceback.format_exc()}")


def main():
    """主函数"""
    try:
        # 使用argparse处理命令行参数
        parser = argparse.ArgumentParser(description='UniX SDK - NetMsg ID 冲突检测工具')
        parser.add_argument('project_root', nargs='?', default=os.getcwd(),
                            help='项目根目录路径 (默认: 当前工作目录)')
        parser.add_argument('--verbose', '-v', action='store_true',
                            help='显示详细日志')
        parser.add_argument('--output', '-o', 
                            help='指定输出报告路径')
        parser.add_argument('--auto-detect', '-a', action='store_true',
                            help='自动检测项目根目录 (向上查找直到找到src目录)')
        
        args = parser.parse_args()
        
        # 规范化项目根目录路径
        project_root = os.path.abspath(args.project_root)
        
        # 自动检测项目根目录
        if args.auto_detect:
            current_dir = project_root
            max_levels = 5  # 最多向上查找5级目录
            
            for _ in range(max_levels):
                if os.path.exists(os.path.join(current_dir, "src")):
                    project_root = current_dir
                    print(f"自动检测到项目根目录: {project_root}")
                    break
                
                parent_dir = os.path.dirname(current_dir)
                if parent_dir == current_dir:  # 已经到达根目录
                    break
                current_dir = parent_dir
        
        # 显示基本信息
        print("============================================")
        print("  UniX SDK - NetMsg ID 冲突检测工具")
        print("============================================")
        print(f"Python版本: {sys.version}")
        print(f"操作系统: {sys.platform}")
        print(f"项目根目录: {project_root}")
        print("============================================")
        
        # 检查项目根目录是否存在
        if not os.path.exists(project_root):
            print(f"错误: 项目根目录不存在: {project_root}")
            print(f"当前工作目录: {os.getcwd()}")
            return 1
            
        # 检查路径是否安全
        try:
            project_root = os.path.abspath(project_root)
            if not os.path.isabs(project_root):
                print(f"错误: 项目根目录必须是绝对路径: {project_root}")
                return 1
                
            # 检查路径是否包含可疑字符
            if any(char in project_root for char in ['|', ';', '&', '`', '$', '(', ')', '<', '>']):
                print(f"错误: 项目根目录包含可疑字符: {project_root}")
                return 1
        except Exception as e:
            print(f"验证项目根目录时出错: {e}")
            return 1
        
        # 检查是否是有效的项目目录
        if not os.path.exists(os.path.join(project_root, "src")):
            print(f"警告: 指定的目录可能不是有效的项目根目录，未找到src目录: {project_root}")
            print(f"提示: 请确保指定的是项目根目录，或使用 --auto-detect 参数自动检测")
            
            # 安全地获取用户输入
            try:
                response = input("是否继续? (y/n): ").strip().lower()
                if response != 'y':
                    return 1
            except (EOFError, KeyboardInterrupt):
                print("\n用户取消操作")
                return 1
        
        # 创建检测器并运行
        checker = NetMsgConflictChecker(project_root)
        checker.run()
        
        return 0
    except Exception as e:
        print(f"发生错误: {e}")
        print(f"错误详情: {traceback.format_exc()}")
        return 1


if __name__ == "__main__":
    sys.exit(main())