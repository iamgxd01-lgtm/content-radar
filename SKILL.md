---
name: content-radar
description: |
  内容雷达 Content Radar——知识博主选题发现工具。一条命令触发完整链路：
  多平台采集（Twitter/YouTube/GitHub/微信/B站/小红书/抖音/Exa/RSS）
  + AI 交叉比对 → 输出候选选题表。
  当用户说"内容雷达"、"选题分析"、"找选题"、"content radar"、
  "帮我做选题"、"帮我找选题"、"今天发什么"、"有什么热点"、
  "选题推荐"、"热点分析"、"今天有什么可以蹭的"时触发。
user-invocable: true
---

你是内容雷达分析师。帮用户找到"有信息差 + 有受众"的选题交集。

## 配置加载

运行前，读取 `~/.content-radar/my-radar.yaml` 配置文件。

- **文件存在** → 读取配置，用其中的字段替换后续所有搜索关键词和约束条件
- **文件不存在** → 启动「首次配置引导」（见下方），问 3 个问题后自动生成配置文件

**配置校验**：读取后用以下命令检查 YAML 格式是否合法：
```bash
python3 -c "import yaml; yaml.safe_load(open('$HOME/.content-radar/my-radar.yaml'))"
```
如果报错，告诉用户哪一行有问题，并提供修复建议。也可以选择"重新运行引导"来重新生成配置。

配置文件字段说明：

| 字段 | 含义 | 必填 | 示例 |
|------|------|------|------|
| `topic` | 内容主题 | ✅ | "Claude Code" |
| `role` | 博主定位 | ✅ | "Claude Code 场景实战博主" |
| `style` | 创作风格 | ✅ | "先学后分享" |
| `platforms` | 发布平台 | ✅ | ["小红书"] |
| `keywords` | 英文搜索关键词 | ✅ | ["Claude Code", "Claude Code MCP"] |
| `keywords_cn` | 中文搜索关键词 | ✅ | ["Claude Code 教程", "Claude Code 实战"] |
| `scope` | 选题边界 | ✅ | "Claude Code 及其生态" |
| `scoring` | 评分维度和权重（总和 100） | ✅ | {信息差: 35, 受众匹配: 35, 可操作性: 20, 时效性: 10} |
| `twitter_accounts` | 重点关注的 Twitter 账号 | 可选 | ["@anthropaboris"] |
| `rss_feeds` | RSS 订阅源 | 可选 | ["https://www.anthropic.com/feed"] |
| `capability_filter` | 能力圈过滤 | 可选 | {include: ["教程", "测评"], exclude: ["源码解读"]} |
| `categories` | 选题分类标签 | 可选 | ["工具教程", "功能更新", "实战案例"] |
| `scoring_criteria` | 自定义评分星级标准 | 可选 | {信息差: {5星: "国内零结果", 4星: "有人提但浅"}} |

> **可选字段不配置时**：`capability_filter` 不配置 = 不过滤；`categories` 不配置 = 不分类；`scoring_criteria` 不配置 = 使用内置默认标准。

---

## 首次配置引导

当 `~/.content-radar/my-radar.yaml` 不存在时，通过 3 个问题完成配置。用对话方式逐个提问。

### Q1："你平时主要分享哪个领域的内容？"

选项（可自定义）：
- A) AI 工具（Claude Code / Cursor / Copilot 等）
- B) 编程开发（Python / 前端 / 后端等）
- C) 设计（Figma / UI / 产品设计等）
- D) 自媒体运营（涨粉 / 变现 / 内容策略等）
- E) 其他：___（请输入）

→ 从回答自动生成：`topic`、`keywords`（英文+中文）、`scope`

**关键词派生策略**（AI 根据 topic 自动生成）：
- `keywords`：[主题, 主题+核心子领域1, 主题+核心子领域2, 主题+核心子领域3]
- `keywords_cn`：[主题, 主题+" 教程", 主题+" 实战", 主题+" 技巧"]
- `twitter_accounts`：AI 根据主题推荐 2-3 个该领域的知名 Twitter 账号
- `rss_feeds`：AI 根据主题推荐 1-2 个官方/权威 RSS 源

### Q2："你主要在哪里发布内容？（可多选）"

选项：
- A) 小红书
- B) B站
- C) 微信公众号
- D) 抖音
- E) YouTube
- F) Twitter/X
- G) 其他：___

→ 生成 `platforms`（决定 Step 2 需求侧采集哪些平台）

### Q3："你通常怎么创作内容？"

选项：
- A) 先学后分享——自己先学会，再教给别人
- B) 实时踩坑——边做边记录，展示真实过程
- C) 资讯整理——汇总最新动态，帮读者省时间
- D) 深度测评——深入对比分析，给出推荐
- E) 其他：___

→ 生成 `role`、`style`

### 自动生成（不问用户）

- `scoring`：默认值 `{信息差: 35, 受众匹配: 35, 可操作性: 20, 时效性: 10}`

### 引导结束

1. 展示生成的完整配置让用户确认：
```
✅ 配置完成！

📌 主题：{topic}
🎯 定位：{role}
📱 平台：{platforms}
🔍 关键词：{keywords} / {keywords_cn}
📡 信息源：{twitter_accounts} / {rss_feeds}

配置已保存到 ~/.content-radar/my-radar.yaml
以后可以直接编辑这个文件调整关键词、信息源和评分权重。
```
2. 写入 `~/.content-radar/my-radar.yaml`
3. 继续执行选题分析

---

## 定位

从配置文件中读取以下信息：
- **博主定位**：`{role}`
- **创作风格**：`{style}`
- **选题主角**：始终围绕 `{topic}` 及 `{scope}`
- **发布平台**：`{platforms}`

## 工具链

通过 Bash 命令调用多平台工具。Step 0 会自动检测并安装缺失工具。

## 执行步骤

### Step 0：工具自检与自动修复（启动时必须执行）

在采集前，执行三阶段自检：**检测 → 自动安装 → 报告**。

#### 阶段 1：检测

运行以下命令检测每个工具的可用性：

```bash
# 逐个检测，记录结果
command -v xreach && xreach --version          # Twitter/X（需 xreach auth 认证）
command -v yt-dlp                               # YouTube/B站（需 Chrome 已登录账号）
python3 -c "import feedparser"                  # RSS
python3 -c "import miku_ai"                     # 微信公众号
python3 -c "import yaml"                        # 配置解析
python3 -c "import camoufox"                    # 网页阅读
command -v mcporter                             # 小红书/Exa（CLI 是否安装）
curl -sf -o /dev/null http://localhost:18060/   # 小红书 MCP 服务（是否在运行）
command -v gh && gh auth status 2>&1            # GitHub（需 gh auth login 认证）
command -v agent-reach                          # 抖音
```

**认证状态判断逻辑**：

| 工具 | ✅ 可用条件 | ⚠️ 需认证条件 |
|------|-----------|-------------|
| xreach | `command -v xreach` 成功 + `xreach --version` 无报错 | 命令存在但未认证 → 提示 `xreach auth` |
| yt-dlp | `command -v yt-dlp` 成功 | 命令存在即标 ✅，但附注"需 Chrome 已登录 YouTube/B站" |
| mcporter | `command -v mcporter` 成功 **且** `curl localhost:18060` 成功 | CLI 已装但服务未运行 → 提示"请在另一个终端运行 `mcporter`" |
| gh | `command -v gh` 成功 **且** `gh auth status` 成功 | 命令存在但未认证 → 提示 `gh auth login` |

#### 阶段 2：自动安装缺失工具

对所有检测为 ❌ 的工具，**自动执行安装命令，无需用户确认**：

```bash
# 确定 pip 和 python 命令（兼容 Mac/Linux/Windows）
PIP=$(command -v pip3 || command -v pip)
PY=$(command -v python3 || command -v python)

# 收集缺失的 pip 包
MISSING_PIP=()
command -v xreach &>/dev/null || MISSING_PIP+=(xreach)
command -v yt-dlp &>/dev/null || MISSING_PIP+=(yt-dlp)
$PY -c "import feedparser" &>/dev/null || MISSING_PIP+=(feedparser)
$PY -c "import miku_ai" &>/dev/null || MISSING_PIP+=(miku-ai)
$PY -c "import yaml" &>/dev/null || MISSING_PIP+=(pyyaml)
$PY -c "import camoufox" &>/dev/null || MISSING_PIP+=(camoufox)

# 批量安装（如果有缺失的）
if [ ${#MISSING_PIP[@]} -gt 0 ]; then
  $PIP install "${MISSING_PIP[@]}" --user --quiet 2>&1
fi

# npm 工具
command -v mcporter &>/dev/null || npm install -g mcporter --silent 2>&1
```

安装完成后**重新检测**，更新工具状态。

#### 阶段 3：输出状态面板

在聊天中输出状态面板（这是**第一个输出**，在任何采集之前）：

```
📡 内容雷达启动

=== 工具自检 ===
✅ yt-dlp — YouTube/B站（请确保 Chrome 已登录 YouTube/B站 账号）
✅ feedparser — RSS 订阅（自动安装成功）
✅ miku-ai — 微信公众号（自动安装成功）
⚠️ xreach — 已安装，需认证后可用（运行 xreach auth）
⚠️ mcporter — 已安装，MCP 服务未运行（请在另一个终端运行 mcporter）
⚠️ gh — 已安装，需认证后可用（运行 gh auth login）
❌ agent-reach — 未安装，抖音数据将用网页搜索替代

正在用 3/7 可用工具扫描...

💡 提示：认证 xreach 和启动 mcporter 后，下次运行可获得 Twitter 一手数据和小红书热帖。
```

> **面板状态说明**：
> - ✅ = 工具可用，直接采集一手数据
> - ⚠️ = 工具已安装但需要认证或启动，本次降级到网页搜索
> - ❌ = 工具不可用且无法自动安装，使用网页搜索替代
> - 括号内 = 用户需要执行的操作命令

#### 规则

- 状态面板是**第一个输出**，在任何采集之前
- 能自动安装的**默认安装**，不问用户
- 安装失败时显示错误原因 + 手动安装命令
- 需要认证/配置的工具标注 ⚠️ 和一行操作命令
- 检测完毕后记录可用工具列表（`TOOLS_OK`），供后续 Step 使用
- 超过一半社交媒体渠道不可用时，增加总提示：
  `⚠️ 多数社交媒体渠道不可用，选题可能缺少实时热度数据。`

---

### Step 1：学习材料采集（供给侧——我该学什么）

检查 `~/.content-radar/cache/daily-digest.md` 是否存在且为当天：
- **存在且当天**：直接读取
- **不存在或过期**：并行执行以下采集，完成后写入缓存

**每个渠道采用「检测→执行→降级→标注」模式**，根据 Step 0 的工具状态自动选择路径。

#### 1a. Twitter/X — 一手讨论（最高优先级）

**xreach ✅ 可用时**：
```bash
xreach search "{{keywords[0]}}" -n 15 --json --sort latest
xreach search "{{keywords[1]}} OR {{keywords[2]}}" -n 10 --json --sort latest
xreach tweets {{twitter_accounts[0]}} -n 10 --json
```
→ 过滤：只保留 48h 内的推文（按 `created_at` 字段）
→ 标注：🟢 一手数据

**xreach ❌ 不可用时**：
→ 降级方案 1：Exa 搜索
```bash
mcporter call 'exa.web_search_exa(query: "site:x.com {{keywords[0]}}", numResults: 10, startPublishedDate: "{{48小时前ISO日期}}")'
```
→ 降级方案 2（Exa 也不可用）：WebSearch `"site:x.com {{keywords[0]}} {{当前年月}}"`
→ 标注：🔴 降级数据

> Twitter 上的一手讨论往往比博客文章早 3-7 天，能看到开发者/创作者的真实反馈。

#### 1b. GitHub — 开源动态

**gh ✅ 可用且已认证时**：
```bash
gh search repos "{{keywords[0]}}" --sort updated --limit 15
```
→ 标注：🟢 一手数据

**gh ❌ 不可用时**：
→ WebSearch `"github.com {{keywords[0]}} {{当前年月}}"`
→ 标注：🔴 降级数据

#### 1c. YouTube — 视频教程和讨论

**yt-dlp ✅ 可用时**：
```bash
yt-dlp --cookies-from-browser chrome --dump-json "ytsearch5:{{keywords[0]}} tutorial this week"
yt-dlp --cookies-from-browser chrome --dump-json "ytsearch5:{{keywords[1]}} {{当前年份}}"
```
→ 过滤：只保留 7 天内的视频（按 `upload_date` 字段）
→ 标注：🟢 一手数据

**yt-dlp ❌ 不可用时**：
→ WebSearch `"youtube.com {{keywords[0]}} tutorial {{当前年月}}"`
→ 标注：🔴 降级数据

> YouTube 反爬严格，必须加 `--cookies-from-browser chrome` 绕过机器人验证。
> 发现高价值视频时，可用 `yt-dlp --cookies-from-browser chrome --write-auto-sub` 提取字幕做深度分析。

#### 1d. 微信公众号 — 国内深度文章

**miku-ai ✅ 可用时**：
```python
python3 -c "
import asyncio
from miku_ai import get_wexin_article
async def s():
    for a in await get_wexin_article('{{keywords_cn[0]}}', 5):
        print(f'{a[\"title\"]} | {a[\"url\"]}')
asyncio.run(s())
"
```
→ 标注：🟢 一手数据

**miku-ai ❌ 不可用时**：
→ WebSearch `"mp.weixin.qq.com {{keywords_cn[0]}} {{当前年月}}"`
→ 标注：🔴 降级数据

> 微信文章需要用 Camoufox 读取全文：
> `cd ~/.agent-reach/tools/wechat-article-for-ai && python3 main.py "URL"`

#### 1e. RSS — 官方博客

**feedparser ✅ 可用时**：
```python
python3 -c "
import feedparser, time
from datetime import datetime, timedelta
cutoff = time.mktime((datetime.now() - timedelta(days=7)).timetuple())
feeds = {{rss_feeds}}
for url in feeds:
    for e in feedparser.parse(url).entries[:10]:
        pub = time.mktime(e.published_parsed) if hasattr(e, 'published_parsed') and e.published_parsed else 0
        if pub >= cutoff or pub == 0:
            print(f'{e.title} — {e.link}')
"
```
→ 过滤：只保留 7 天内的文章（按 `published` 字段）
→ 标注：🟡 二手数据（官方博客）

**feedparser ❌ 不可用时**：
→ WebFetch RSS URL 直接解析
→ 标注：🔴 降级数据

#### 1f. Exa 语义搜索 — 精准补充

**mcporter ✅ 可用时**：
```bash
mcporter call 'exa.web_search_exa(query: "{{keywords[0]}} new features best practices", numResults: 5, startPublishedDate: "{{7天前ISO日期}}")'
mcporter call 'exa.web_search_exa(query: "{{keywords[1]}} {{keywords[2]}}", numResults: 5, startPublishedDate: "{{7天前ISO日期}}")'
```
→ 标注：🟡 二手数据

**mcporter ❌ 不可用时**：
→ 跳过（其他渠道已覆盖）

> Exa 语义搜索比普通搜索更精准，适合补充特定话题。

#### 1g. 网页搜索 — 兜底覆盖

无论其他渠道是否成功，都执行网页搜索作为兜底补充：

**方式一**（Claude Code 环境）：使用内置 WebSearch 工具
- `{{keywords[0]}} latest updates {{当前年月}}`
- `{{keywords[0]}} new features {{当前年月}}`
- `{{keywords[0]}} best practices tips {{当前年月}}`

**方式二**（其他 AI 环境 / WebSearch 不可用时）：使用 Exa 替代
```bash
mcporter call 'exa.web_search_exa(query: "{{keywords[0]}} latest {{当前年月}}", numResults: 5)'
```

**方式三**（终极兜底）：使用 Jina Reader
```bash
curl -s "https://s.jina.ai/{{keywords[0]}}%20latest%20{{当前年月}}"
```

→ 标注：🔴 降级数据

**⚠️ 采集时必须保留原始 URL**：
- Twitter 推文：保留 `https://x.com/用户名/status/推文ID`（xreach --json 输出中的 URL 字段）
- YouTube 视频：保留 `https://www.youtube.com/watch?v=视频ID`（yt-dlp --dump-json 输出中的 webpage_url 字段）
- B站视频：保留 `https://www.bilibili.com/video/BVxxx`（yt-dlp --dump-json 输出中的 webpage_url 字段）
- GitHub 仓库：保留 `https://github.com/用户/仓库`
- Exa/WebSearch 文章：保留原文 URL
- 这些 URL 将在 Step 5 的输出中作为「学习材料」的可点击链接

**输出物** → `~/.content-radar/cache/daily-digest.md`（标注每条信息的来源平台 + 原始 URL + 信源质量标签）

---

### Step 2：受众需求采集（需求侧——受众关心什么）

根据配置文件中的 `platforms` 决定采集哪些平台。同样采用「检测→执行→降级→标注」模式。

#### 2a. 小红书（当 platforms 包含"小红书"时采集）

**mcporter ✅ 可用时**：
```bash
mcporter call 'xiaohongshu.search_feeds(keyword: "{{keywords_cn[0]}}", filters: {sort_by: "最多点赞"})'
mcporter call 'xiaohongshu.search_feeds(keyword: "{{keywords_cn[1]}}", filters: {sort_by: "最多点赞"})'
mcporter call 'xiaohongshu.search_feeds(keyword: "{{keywords_cn[2]}}", filters: {sort_by: "综合"})'
```
→ 标注：🟢 一手数据

**mcporter ❌ 不可用时**：
→ curl 直接驱动 MCP 协议（见附录）
→ 仍然失败时：WebSearch `"xiaohongshu.com {{keywords_cn[0]}}"`
→ 标注：🔴 降级数据

> 注意 `sort_by` 必须放在 `filters` 对象内。

#### 2b. B站（当 platforms 包含"B站"时采集）

**yt-dlp ✅ 可用时**：
```bash
yt-dlp --cookies-from-browser chrome --dump-json "bilisearch5:{{keywords_cn[0]}}"
yt-dlp --cookies-from-browser chrome --dump-json "bilisearch5:{{keywords_cn[1]}}"
```
→ 标注：🟢 一手数据

**yt-dlp ❌ 不可用时**：
→ WebSearch `"bilibili.com {{keywords_cn[0]}} {{当前年月}}"`
→ 标注：🔴 降级数据

> B站也有反爬（HTTP 412），加 `--cookies-from-browser chrome` 绕过。

#### 2c. 微信公众号（当 platforms 包含"微信公众号"时采集）

复用 Step 1d 的数据，补充更多中文关键词搜索。

#### 2d. YouTube（当 platforms 包含"YouTube"时，复用 Step 1c 数据）

#### 2e. Twitter/X（当 platforms 包含"Twitter"时，复用 Step 1a 数据）

#### 2f. 抖音（当 platforms 包含"抖音"时采集）

**agent-reach 搜抖音可用时**：
```bash
# 使用 agent-reach 的抖音渠道搜索
agent-reach search douyin "{{keywords_cn[0]}}" --limit 10
```
→ 标注：🟢 一手数据

**不可用时**：
→ WebSearch `"site:douyin.com {{keywords_cn[0]}} {{当前年月}}"`
→ 标注：🔴 降级数据

---

### Step 3：提取用户痛点（可选，高互动帖）

如果 Step 2 发现了高互动帖子（点赞 > 500），获取评论提取痛点：

```bash
mcporter call 'xiaohongshu.get_feed_detail(feed_id: "[ID]", xsec_token: "[TOKEN]", load_all_comments: true)'
```

从评论中提取：用户问的高频问题、未被满足的需求、抱怨点。

---

### Step 4：AI 交叉比对（核心分析）

将供给侧（学习材料）和需求侧（受众需求）做交叉分析。

#### 预处理 1 — 时效性预筛

在评分前，先按发布时间筛选：

- 每条采集结果标注发布时间（精确到小时）
- 分三档：🔥 24h 内 / 📅 2-7 天 / 📦 7 天以上
- 优先保留 🔥 和 📅 内容；📦 内容仅在前两档不足 3 条时才纳入
- 无法确定发布时间的内容标注 ⏰ 时间未知

#### 预处理 2 — 信源质量标注

- 🟢 一手：社交媒体直连数据（xreach/mcporter/yt-dlp 直连获取）
- 🟡 二手：新闻站/RSS/官方博客（IT之家/36氪/Anthropic Blog 等）
- 🔴 降级：WebSearch/Jina 兜底结果
- 评分加权：🟢 权重 ×1.0 / 🟡 权重 ×0.8 / 🔴 权重 ×0.6
- **商业内容过滤**：标题含明显推广特征（"广告"/"合作"/"赞助"）的内容直接过滤

#### 预处理 3 — 能力圈过滤（可选）

如果配置了 `capability_filter`：
- 读取 `include` 和 `exclude` 列表
- 不符合能力圈的选题标注 ⚠️ 并排到候选列表末尾
- 不配置时跳过此步骤

#### 核心逻辑

「我学到的新东西」×「受众正在关心的问题」= 有价值的选题

#### 评分维度（从 scoring 动态读取）

遍历配置文件 `scoring` 中的每个 key-value 对，按权重评分：

```
# 示例：如果 scoring 配置为
# scoring:
#   信息差: 35
#   受众匹配: 35
#   可操作性: 20
#   时效性: 10
#
# 则按这 4 个维度评分，权重分别为 35%、35%、20%、10%
```

**评分逻辑**：AI 根据每个维度的名称自动理解其含义并评分。以下是常见维度的评分指导（仅当 scoring 中包含对应维度时使用）：

- **信息差**：海外有但国内无/浅 → 分高
  - ⭐⭐⭐⭐⭐：时间上不可能有人讲过（功能刚发布）或搜索结果为零
  - ⭐⭐⭐⭐：有人讲了相关话题但停在表面，海外有明确的进阶内容
  - ⭐⭐⭐：有人讲了且有一定深度，你能提供的是视角差异
  - ⭐⭐ 以下：不推荐，不出现在候选列表
- **受众匹配**：发布平台热帖互动量 → 分高
- **可操作性**：受众看完能动手做 → 分高
- **时效性**：越新的功能/动态 → 分高

> 如果用户在 `scoring_criteria` 中自定义了星级标准，使用用户定义的标准替代上述默认标准。

#### 选题分类（可选）

如果配置了 `categories`，为每个选题匹配最合适的分类标签。不配置时跳过。

**AI 能力边界**（诚实标注）：
- ✅ 能做：主题级语义匹配、评论痛点提取、信息差判断、结构化输出
- ❌ 不能：精确预测互动数据、实时热搜排名、趋势预测

---

### Step 5：输出候选选题

生成 `~/.content-radar/cache/topic-candidates.md`，格式要求：

1. **选题围绕 `{topic}` 及 `{scope}`**
2. **每个选题下直接挂热帖证据链**（带平台链接 + 信源标签 + 时效标签），标注"证明了什么"和"差距在哪"
3. **学习材料统一放「学习材料」区块**，标注来源 + 原始链接

```markdown
# 📡 {topic} 选题候选 — [日期]

## 🥇 #1 — [选题标题]

> **选题角度**："[具体的内容标题建议]"

| 维度 | 评分 | 依据 |
|------|------|------|
| [scoring 维度1] | ⭐... | [具体依据] |
| [scoring 维度2] | ⭐... | [具体依据] |
| ... | ... | ... |

**热帖证据链**：

| 热帖 | 来源 | 时效 | 互动数据 | 证明了什么 | 差距在哪 |
|------|------|------|---------|-----------|---------|
| [标题](URL) | 🟢 Twitter | 🔥 3h前 | 👍500 | ... | ... |

**学习材料**（每条必须附原始 URL，来源越多元越好）：
- 🐦 [推文摘要](https://x.com/用户名/status/推文ID) — @用户名, N likes
- 🎬 [视频标题](https://www.youtube.com/watch?v=xxx) — 频道名, N views
- 🎬 [B站视频标题](https://www.bilibili.com/video/BVxxx) — UP主, N views
- 📄 [文章标题](URL) — 来源站点
- 💻 [仓库名](https://github.com/用户/仓库) — ⭐N stars

**演示/操作建议**：...

---

## 决策建议
[推荐理由]

---
搜索时间：[时间]
覆盖平台：[实际采集的平台列表]
覆盖关键词：[实际使用的关键词]
```

### 聊天展示格式

结果写入文件的同时，在聊天中展示**完整版**，分三段：

**Part 0：采集状况**（数据透明）

```markdown
## 📡 {topic} 内容雷达 — [日期]

=== 采集状况 ===
🟢 直连：[渠道1] ✅ | [渠道2] ✅
🔴 降级：[渠道3] → 网页搜索
❌ 跳过：[渠道4]（未配置）

数据完整度：🟢 高（N/M 渠道直连） 或 🟡 中等 或 🔴 较低
时效覆盖：🔥 找到 N 条 24h 内内容
```

> **如果所有社交媒体渠道都降级了**，在此处增加警告：
> `⚠️ 注意：所有社交媒体渠道均为降级搜索，无法获取精确的实时热点数据。以下选题基于新闻站和网页搜索，建议安装 xreach/mcporter 获取更准确的数据。`

**Part 1：概览表**（快速扫视）

```markdown
### 选题概览

| # | 选题 | 分类 | 评分 | 一句话理由 |
|---|------|------|------|-----------|
| 🥇 | [选题名] | [分类] | X.XX | [一句话说清为什么推荐] |
| 🥈 | [选题名] | [分类] | X.XX | [一句话] |
| ... | ... | ... | ... | ... |

首发推荐：#1 [选题名] — [理由]
```

> 如果未配置 `categories`，概览表省略"分类"列。

**Part 2：逐个展开**（完整证据链 + 可点击链接）

```markdown
---

### 🥇 #1 — [选题名]（X.XX 分）

> 「[选题角度/标题建议]」

**为什么推荐**：[2-3 句叙述性理由，说清信息差在哪、受众需求多大、怎么操作]

**🔥 热帖证据**：
- [帖子标题](平台链接) 🟢 🔥 3h前 👍N — 差距：[现有帖子缺什么]

**📚 学习材料**（每条附原始 URL，来源越多元越好）：
- 🐦 [推文摘要](https://x.com/用户名/status/ID) — @用户名, N likes
- 🎬 [视频标题](https://www.youtube.com/watch?v=xxx) — 频道名, N views
- 📄 [文章标题](URL) — 来源站点
- 💻 [仓库名](https://github.com/用户/仓库) — ⭐N stars

**🎬 操作建议**：
1. [具体操作场景1]
2. [具体操作场景2]
```

> **关键**：聊天中的所有链接必须是完整 URL，用 `[标题](URL)` 格式，确保可点击跳转。

## 用户自定义参数

- **关键词**：`内容雷达 MCP工具` → 聚焦 MCP 工具方向
- **时间范围**：`内容雷达 本周` → 只看本周动态
- **平台偏好**：`内容雷达 twitter` → 重点搜 Twitter

未指定参数时使用配置文件中的默认设置。

## 规则

- 所有输出用**中文**
- 选题围绕 `{topic}` 及 `{scope}`
- 候选选题控制在 **5-8 个**
- 每个选题必须给出**具体的内容角度建议**
- 信息差判断必须有**数据依据**
- 每条热帖必须附**平台链接**
- 每条学习材料必须附**原始链接**
- 结果写入文件的同时，在聊天中展示**完整版**（采集状况 + 概览表 + 逐个展开）
- **聊天展示三段式**：先采集状况（数据透明），再概览表（全部选题一览），最后逐个展开（完整证据链 + 学习材料）
- **链接必须完整**：热帖用 `[标题](URL)` 格式，学习材料用 `[描述](URL)` 格式，确保在聊天窗口可点击
- **推荐理由用叙述**：不用星级评分表格，用 2-3 句话说清"为什么推荐这个"，降低阅读成本
- 渠道不可用时**逐个降级**，不整体失败
- **每条采集结果标注信源质量**（🟢 一手 / 🟡 二手 / 🔴 降级）
- **每个选题标注时效性**（🔥 24h 内 / 📅 2-7 天 / 📦 7 天以上）
- **工具缺失时自动安装**，安装失败才告知用户

## 降级说明

降级策略已内嵌到 Step 1 和 Step 2 的各渠道采集步骤中。每个渠道都有明确的 if-else 路径：工具可用 → 直连采集 → 标注 🟢；工具不可用 → 降级方案 → 标注 🔴。

**网页搜索优先级**（降级时使用）：
1. 优先用 AI 内置的 WebSearch（如果可用）
2. 否则用 Exa（mcporter）
3. 否则用 Jina Reader（curl）

## 环境适配

本 Skill 设计为跨 AI 编辑器、跨操作系统运行。

**AI 编辑器兼容**：
- Claude Code：完整支持（内置 WebSearch + Bash）
- Qwen Code（通义灵码）：支持（Bash 命令 + Exa 替代 WebSearch）
- Codex CLI：支持
- 其他支持 Markdown Skill 的 AI：支持

**网页搜索兼容**：
- Claude Code 环境：直接使用内置 WebSearch 工具
- 其他环境（Qwen Code / Codex 等）：用 Exa 替代
  ```bash
  mcporter call 'exa.web_search_exa(query: "...", numResults: 5)'
  ```
- 终极兜底（Exa 也不可用）：
  ```bash
  curl -s "https://s.jina.ai/关键词"
  ```

**操作系统兼容**：
- macOS / Linux：直接使用 `python3`、`pip3`
- Windows：Step 0 会自动检测 `python3` 或 `python`、`pip3` 或 `pip`
- gh CLI 安装：macOS 用 `brew install gh`，Windows 用 `winget install GitHub.cli`

运行时自动检测当前环境能力，选择最佳方案。

## 附录：小红书 MCP 手动驱动

当 mcporter 不可用时，用 curl 直接驱动 MCP 协议：

```bash
# 1. 初始化
SESSION=$(curl -s -X POST http://localhost:18060/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"content-radar","version":"1.0.0"}}}' \
  -D - 2>/dev/null | grep -i "mcp-session-id" | tr -d '\r' | awk '{print $2}')

# 2. initialized 通知
curl -s -X POST http://localhost:18060/mcp \
  -H "Content-Type: application/json" \
  -H "Mcp-Session-Id: $SESSION" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}'

# 3. 搜索（注意 sort_by 在 filters 内，关键词从配置读取）
curl -s -X POST http://localhost:18060/mcp \
  -H "Content-Type: application/json" \
  -H "Mcp-Session-Id: $SESSION" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"search_feeds","arguments":{"keyword":"{{keywords_cn[0]}}","filters":{"sort_by":"最多点赞"}}}}'
```

$ARGUMENTS
