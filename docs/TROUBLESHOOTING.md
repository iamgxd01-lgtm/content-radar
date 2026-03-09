# 常见问题

## 安装相关

### "需要 Python 3" 怎么办？

- macOS：打开终端，运行 `brew install python3`
- 没有 brew？先装 Homebrew：`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

### "需要 Node.js" 怎么办？

- macOS：运行 `brew install node`
- Linux：运行 `sudo apt install nodejs npm`

### 某个工具安装失败

不影响使用！内容雷达会自动用其他方式替代。如果想手动重试：

```bash
pip3 install --user 工具名
```

## 使用相关

### 配置文件格式出错

如果你手动编辑了配置文件导致格式出错，有两个办法：
1. 对照 `examples/my-radar.yaml.example` 修复格式
2. 删除配置文件重新引导：`rm ~/.content-radar/my-radar.yaml`，然后重新运行"内容雷达"

### 小红书搜索不到结果

确认小红书 MCP 服务正在运行：
```bash
curl -s http://localhost:18060/mcp -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'
```

如果没有响应，需要启动 MCP 服务（具体方法取决于你的安装方式）。

### YouTube/B站 搜索报错

通常是反爬导致的。确保你的 Chrome 浏览器已登录 YouTube/B站，工具会自动借用浏览器的登录状态。

### GitHub 搜索显示"降级为网页搜索"

需要登录 GitHub CLI：
```bash
gh auth login
```
按提示完成登录即可。不登录也不影响使用——会自动用网页搜索替代。
