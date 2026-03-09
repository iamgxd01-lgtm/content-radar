# 📡 内容雷达 Content Radar

> 帮知识博主找到**"有信息差 + 有受众"**的选题。一条命令，全网扫描。

## 它能做什么

输入一条命令，AI 自动帮你：

1. **扫描海外前沿**（Twitter、YouTube、GitHub、Exa、RSS）→ 发现别人还没讲的新东西
2. **扫描国内热帖**（小红书、B站、微信公众号）→ 找到受众正在关心的话题
3. **交叉比对**（供给 × 需求）→ 推荐 5-8 个选题，按信息差和受众匹配度排序
4. **附带证据链**（热帖链接 + 学习材料 URL）→ 每个推荐都有数据支撑

## 30 秒安装

### 第一步：下载

```bash
git clone https://github.com/你的用户名/content-radar.git
cd content-radar
```

### 第二步：一键安装

```bash
bash setup.sh
```

安装脚本会自动帮你装好所有需要的工具。如果某个工具没装成功也不用担心——内容雷达会自动用其他方式替代。

### 第三步：开始使用

打开你的 AI 编辑器，输入：

```
内容雷达
```

首次运行会问你 3 个问题（你的领域、发布平台、创作风格），之后就是全自动的。

## 支持的 AI 编辑器

| 编辑器 | 状态 |
|--------|------|
| Claude Code | ✅ 完整支持 |
| Qwen Code（通义灵码）| ✅ 支持 |
| Codex CLI | ✅ 支持 |
| 其他支持 Markdown Skill 的 AI | ✅ 支持 |

## 配置文件

首次运行后，你的配置会保存在 `~/.content-radar/my-radar.yaml`。

你可以随时编辑这个文件来调整：
- 搜索关键词（想搜什么就搜什么）
- 发布平台（决定扫描哪些国内平台）
- 评分权重（更看重时效性还是信息差？）
- 关注的信息源（Twitter 账号、RSS 订阅）

配置示例见 `examples/my-radar.yaml.example`。

## 采集渠道

| 渠道 | 工具 | 用途 |
|------|------|------|
| Twitter/X | xreach | 一手讨论，比博客早 3-7 天 |
| YouTube | yt-dlp | 视频教程和深度讨论 |
| GitHub | gh CLI | 开源项目和代码动态 |
| Exa | mcporter | 语义搜索，精准查找 |
| RSS | feedparser | 官方博客订阅 |
| 微信公众号 | miku-ai | 国内深度文章 |
| 小红书 | mcporter | 国内热帖和受众需求 |
| B站 | yt-dlp | 国内视频竞品 |

每个渠道都有自动降级策略——如果某个工具不可用，会自动切换到备用方案。

## 常见问题

见 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## License

MIT
