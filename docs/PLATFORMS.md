# 各平台渠道说明

## 供给侧（学习材料——你该学什么）

| 渠道 | 工具 | 优势 | 限制 |
|------|------|------|------|
| **Twitter/X** | xreach | 一手讨论，比博客早 3-7 天 | 需要 xreach 认证（`xreach auth`）|
| **YouTube** | yt-dlp | 官方教程和深度讨论 | 反爬严格，需 Chrome cookie |
| **GitHub** | gh CLI | 开源项目和代码趋势 | 需要 `gh auth login` |
| **Exa** | mcporter | 语义搜索，比关键词搜索更精准 | 需要 Exa API key |
| **RSS** | feedparser | 官方博客自动推送 | 需要知道 RSS 地址 |
| **微信公众号** | miku-ai | 国内深度文章 | 部分文章需要 Camoufox 读全文 |
| **网页搜索** | 内置/Exa/Jina | 兜底覆盖所有来源 | 结果可能不够精准 |

## 需求侧（受众需求——受众关心什么）

| 渠道 | 工具 | 采集内容 | 何时采集 |
|------|------|---------|---------|
| **小红书** | mcporter (MCP) | 热帖 + 互动数据 + 评论痛点 | platforms 包含"小红书" |
| **B站** | yt-dlp | 视频竞品 + 播放量 | platforms 包含"B站" |
| **微信公众号** | miku-ai | 深度竞品文章 | platforms 包含"微信公众号" |
| **抖音** | agent-reach | 短视频爆款 + 热度数据 | platforms 包含"抖音" |
| **YouTube** | yt-dlp | 复用供给侧数据 | platforms 包含"YouTube" |
| **Twitter/X** | xreach | 复用供给侧数据 | platforms 包含"Twitter" |

## 抖音渠道说明

### 采集方式

**优先方案**：agent-reach 抖音渠道
```bash
agent-reach search douyin "关键词" --limit 10
agent-reach read douyin "URL"
```

**降级方案**：WebSearch
```
WebSearch "site:douyin.com 关键词"
```

### 限制

- 抖音反爬严格，无公开字幕 API
- 视频内容主要分析标题 + 描述 + 评论
- 爆款拆解时标注"以短视频为主，无字幕数据"

## 降级策略

每个渠道都有备用方案。内容雷达会在启动时**自动检测工具状态**，工具不可用时**自动安装**（pip3/npm 包），安装仍失败时**自动降级**：

```
Twitter (xreach)  ──不可用──>  Exa (site:x.com)  ──不可用──>  网页搜索  [标注 🔴]
YouTube (yt-dlp)  ──不可用──>  网页搜索 (youtube.com)                    [标注 🔴]
GitHub (gh)       ──不可用──>  网页搜索 (github.com)                     [标注 🔴]
微信 (miku-ai)    ──不可用──>  网页搜索 (mp.weixin.qq.com)              [标注 🔴]
B站 (yt-dlp)      ──不可用──>  网页搜索 (bilibili.com)                  [标注 🔴]
小红书 (mcporter)  ──不可用──>  curl 直接调用 MCP ──不可用──> 网页搜索   [标注 🔴]
抖音 (agent-reach) ──不可用──>  网页搜索 (douyin.com)                    [标注 🔴]
Exa (mcporter)    ──不可用──>  网页搜索                                  [标注 🔴]
```

"网页搜索"会自动选择最佳可用方案：
1. AI 内置的 WebSearch（Claude Code 环境）
2. Exa 搜索（跨平台）
3. Jina Reader（终极兜底，只需 curl）

### 信源质量标签

每条采集结果都会标注数据来源质量：
- 🟢 一手：社交媒体直连（xreach/mcporter/yt-dlp 等直接获取）
- 🟡 二手：新闻站/RSS/官方博客
- 🔴 降级：WebSearch/Jina 兜底结果
