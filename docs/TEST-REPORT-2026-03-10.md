# 内容雷达 v2 全链路测试报告

> 测试时间：2026-03-10 13:35-13:50
> 测试版本：commit 1d4e138（fix: 修复安装脚本）
> 测试视角：纯小白博主（无技术背景）
> 目标编辑器：Qwen Code（千问 3.5）
> 测试执行：Claude Code 模拟 + 待 Qwen Code 最终验证

---

## 测试总结

| 阶段 | 结果 | 严重程度 |
|------|------|----------|
| git clone | PASS | — |
| setup.sh 执行 | PARTIAL | 中 |
| Step 0 工具检测 | PASS | — |
| 工具可用性 | PARTIAL | 中 |
| Skill 文件安装 | PASS | — |
| Qwen Code 最终验证 | 待测 | — |

**整体评估：安装流程可以走通，但有 2 个需要修复的问题和 3 个体验改进建议。**

---

## Phase 1: 环境清理

清理了以下 10 个位置，模拟纯小白电脑：

| 位置 | 操作 | 结果 |
|------|------|------|
| `~/.content-radar/` | 删除 | PASS |
| `~/.claude/skills/content-radar/` | 删除 | PASS |
| `~/.claude/skills/content-breakdown/` | 删除 | PASS |
| `~/.claude/content-pipeline/` | 删除 | PASS |
| xreach-cli (npm) | 卸载 | PASS |
| mcporter (npm) | 卸载 | PASS |
| yt-dlp (brew/pip) | 卸载 | PASS（需手动删除 binary） |
| feedparser (pip) | 卸载 | PASS |
| camoufox (pip) | 卸载 | PASS |
| pyyaml (pip) | 卸载 | PASS |

> **发现 1**：yt-dlp 通过 brew 卸载失败（因为它是 pip 装到 homebrew Python 环境中的），需要手动删除 `/opt/homebrew/bin/yt-dlp`。说明安装方式不统一会导致卸载困难。

---

## Phase 2: git clone

```bash
git clone https://github.com/iamgxd01-lgtm/content-radar.git
```

**结果：PASS**

- Clone 耗时约 2 秒
- 仓库结构清晰，用户能看到 `setup.sh` 和 `README.md`

---

## Phase 3: setup.sh 执行

```bash
cd content-radar && bash setup.sh
```

### 结果明细

| 安装项 | 结果 | 原因 |
|--------|------|------|
| 前置检查（Python3/npm） | PASS | 本机已有 |
| yt-dlp (pip) | FAIL | SSL 证书验证失败 |
| feedparser (pip) | FAIL | SSL 证书验证失败 |
| camoufox (pip) | FAIL | SSL 证书验证失败 |
| pyyaml (pip) | FAIL | SSL 证书验证失败 |
| xreach-cli (npm) | PASS | — |
| mcporter (npm) | PASS | — |
| 创建工作目录 | PASS | — |
| 安装 Skill 到 Claude Code | PASS | — |
| 安装 Skill 到 Qwen Code | PASS | `~/.qwen/skills/` |
| 写入安装标记 | PASS | — |
| 复制配置示例 | PASS | — |

### BUG-1：所有 Python 包安装失败（SSL 证书错误）

**严重程度：中**

**现象**：`pip3 install --user --quiet` 全部失败，错误信息被 `2>/dev/null` 吞掉，用户只看到 ❌ 但不知道为什么。

**根因**：Python 3.14（homebrew）的 SSL 证书未配置。这是 macOS 常见问题，运行 `Install Certificates.command` 或安装 `certifi` 包可以修复。

**影响**：
- yt-dlp 不可用 → YouTube/B站搜索降级为 WebSearch
- feedparser 不可用 → RSS 订阅不可用
- camoufox 不可用 → 网页阅读不可用
- pyyaml 不可用 → 配置文件无法解析（SKILL.md 会用内联默认值）

**建议修复**：
1. setup.sh 中 pip3 失败时，显示具体错误信息（不吞 stderr）
2. 检测 SSL 错误时，给出修复提示：`如果看到 SSL 错误，运行：pip3 install certifi`
3. 考虑 pip3 安装时加 `--trusted-host pypi.org --trusted-host files.pythonhosted.org` 作为备选

### BUG-2：xreach 认证状态无法检查

**严重程度：低**

**现象**：`xreach auth status` 报 `error: unknown command 'status'`。

**影响**：SKILL.md 中如果有检查认证状态的逻辑，会失败。但目前 Step 0 检测脚本不依赖此命令，影响有限。

---

## Phase 4: SKILL.md Step 0 检测脚本

**结果：PASS**

检测脚本输出清晰：

```
XREACH=OK
YTDLP=MISSING
FEEDPARSER=MISSING
PYYAML=MISSING
CAMOUFOX=MISSING
MCPORTER=OK
MCP_SERVICE=MISSING
```

AI 编辑器可以根据这些结果准确生成状态面板。

---

## Phase 5: 工具可用性验证

| 工具 | 安装 | 可调用 | 说明 |
|------|------|--------|------|
| xreach | OK | FAIL | TLS 连接失败（网络/代理问题，非工具本身问题） |
| mcporter | OK | OK（v0.7.3） | 服务未启动，需用户运行 `mcporter` |
| yt-dlp | MISSING | — | pip SSL 问题 |
| feedparser | MISSING | — | pip SSL 问题 |
| camoufox | MISSING | — | pip SSL 问题 |
| pyyaml | MISSING | — | pip SSL 问题 |
| WebSearch | 内置 | OK | 始终可用，不依赖外部工具 |

### Skill 文件验证

| 检查项 | 结果 |
|--------|------|
| Qwen Code SKILL.md 存在 | PASS（`~/.qwen/skills/content-radar/SKILL.md`） |
| 文件与 GitHub 版本一致 | PASS（diff 无差异） |
| 文件大小 | 24,414 bytes |
| 配置示例文件 | PASS（`~/.content-radar/my-radar.yaml.example`） |

---

## Phase 6: 小白用户体验评估

### 用户会卡在哪里？

| # | 卡点 | 严重程度 | 说明 |
|---|------|----------|------|
| 1 | **没有 Python3/Node.js** | 高 | setup.sh 直接退出，README 没有安装前置条件的指引 |
| 2 | **pip3 SSL 错误** | 中 | 4 个包全部失败但不知道原因（stderr 被吞） |
| 3 | **不知道要运行 mcporter** | 中 | 安装后需要在另一个终端运行 mcporter，小白不理解"另一个终端" |
| 4 | **xreach auth 需要翻墙** | 低 | Twitter 认证需要网络代理，setup.sh 没提到 |
| 5 | **首次使用要回答 3 个问题** | 低 | 体验尚可，但问题描述可以更通俗 |

### 小白友好度评分

| 维度 | 评分（1-5） | 说明 |
|------|-------------|------|
| 安装难度 | 3/5 | 一键脚本好，但前置条件和错误提示不够 |
| 错误可读性 | 2/5 | ❌ 标记但不说原因，小白不知道怎么修 |
| 文档完整度 | 3/5 | README 结构清晰，但缺"前置条件"和"卸载指南" |
| 降级体验 | 4/5 | 工具不可用时自动降级到 WebSearch，设计合理 |
| 输出价值 | 待验证 | 需要在 Qwen Code 中实际运行才能评估 |

---

## 改进建议（按优先级排序）

### P0：必须修复

1. **setup.sh 显示 pip3 错误信息**
   - 当前 `2>/dev/null` 吞掉所有错误
   - 改为：失败时输出最后一行错误信息
   - 至少让用户看到 "SSL 证书错误" 这样的关键词

### P1：建议修复

2. **README 添加前置条件说明**
   - 明确告知需要 Python3 和 Node.js
   - 提供 macOS 一键安装命令：`brew install python3 node`

3. **setup.sh 尝试修复常见 pip 问题**
   - 检测 SSL 错误后，自动尝试 `pip3 install certifi`
   - 或加 `--trusted-host` 参数重试

### P2：体验优化

4. **添加卸载指南**
   - README 中添加"如何卸载"章节
   - 或提供 `bash uninstall.sh`

5. **mcporter 启动提示更具体**
   - "另一个终端"改为"打开一个新的终端窗口（Cmd+T），输入 mcporter，保持不关闭"

---

## 待完成：Qwen Code 最终验证

以下步骤需要你在 Qwen Code 中手动执行：

1. 打开终端，运行 `qwen`（或在 VS Code 中打开 Qwen Code）
2. 输入"内容雷达"
3. 观察：
   - [ ] AI 是否执行了 Step 0 检测脚本？
   - [ ] 状态面板是否正确显示？
   - [ ] AI 是否提示运行 setup.sh？
   - [ ] AI 是否询问了 3 个定位问题？
   - [ ] AI 是否成功执行采集（即使是降级到 WebSearch）？
   - [ ] 最终输出是否包含选题推荐？
4. 截图记录每个步骤的输出

---

## 文档溯源

### 生成提示词

```
开始吧，不仅仅能生成测试计划，能真正的帮我做测试，并且能执行完整的测试，最终输出一个完整的测试报告。
```

### 依赖文档

| 文档 | 用途 |
|------|------|
| `setup.sh` | 被测试的安装脚本 |
| `SKILL.md` | 被测试的 AI 指令文件 |
| `README.md` | 被评估的用户文档 |

### 生成信息

- **生成时间**：2026-03-10
- **生成工具**：Claude Code（claude-opus-4-6）
- **数据处理**：实际执行 git clone + setup.sh + 工具检测，记录真实输出
