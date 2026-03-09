# 各平台渠道说明

## 供给侧（学习材料——你该学什么）

| 渠道 | 工具 | 优势 | 限制 |
|------|------|------|------|
| **Twitter/X** | xreach | 一手讨论，比博客早 3-7 天 | 需要 xreach 账号认证 |
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
| **YouTube** | yt-dlp | 复用供给侧数据 | platforms 包含"YouTube" |
| **Twitter/X** | xreach | 复用供给侧数据 | platforms 包含"Twitter" |

## 降级策略

每个渠道都有备用方案。如果主工具不可用，会自动切换：

```
Twitter (xreach)  ──不可用──>  Exa (site:x.com)  ──不可用──>  网页搜索
YouTube (yt-dlp)  ──不可用──>  网页搜索 (youtube.com)
GitHub (gh)       ──不可用──>  网页搜索 (github.com)
微信 (miku-ai)    ──不可用──>  网页搜索 (mp.weixin.qq.com)
B站 (yt-dlp)      ──不可用──>  网页搜索 (bilibili.com)
小红书 (mcporter)  ──不可用──>  curl 直接调用 MCP
Exa (mcporter)    ──不可用──>  网页搜索
```

"网页搜索"会自动选择最佳可用方案：
1. AI 内置的 WebSearch（Claude Code 环境）
2. Exa 搜索（跨平台）
3. Jina Reader（终极兜底，只需 curl）
