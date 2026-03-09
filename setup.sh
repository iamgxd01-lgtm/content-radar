#!/bin/bash
# ============================================
# 内容雷达 Content Radar — 一键安装
# 用法：bash setup.sh
# ============================================

set -e

# ---- 颜色和图标 ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD='\033[1m'

ok() { echo -e "  ${GREEN}✅ $1${NC}"; }
warn() { echo -e "  ${YELLOW}⚠️  $1${NC}"; }
fail() { echo -e "  ${RED}❌ $1${NC}"; }
info() { echo -e "  ${BLUE}ℹ️  $1${NC}"; }

echo ""
echo -e "${BOLD}📡 内容雷达 Content Radar — 安装开始${NC}"
echo "=========================================="
echo ""

FAILED=()
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Step 0: 前置检查 ----
echo -e "${BOLD}🔍 检查基础环境...${NC}"

if ! command -v python3 &>/dev/null; then
  fail "需要 Python 3，请先安装"
  echo "    macOS: brew install python3"
  echo "    Linux: sudo apt install python3"
  exit 1
fi

if ! command -v pip3 &>/dev/null; then
  fail "需要 pip3，请先安装"
  echo "    macOS: brew install python3（自带 pip3）"
  echo "    Linux: sudo apt install python3-pip"
  exit 1
fi

if ! command -v npm &>/dev/null; then
  fail "需要 Node.js，请先安装"
  echo "    macOS: brew install node"
  echo "    Linux: sudo apt install nodejs npm"
  exit 1
fi

ok "Python3 和 Node.js 已就绪"
echo ""

# ---- Step 1: 安装 Python 工具 ----
echo -e "${BOLD}📦 安装搜索工具（Python）...${NC}"

install_pip() {
  local pkg=$1
  local display_name=$2
  echo -n "  安装 ${display_name}..."
  if pip3 install "$pkg" --user --quiet 2>/dev/null; then
    echo -e " ${GREEN}✅${NC}"
  else
    echo -e " ${RED}❌${NC}"
    FAILED+=("$display_name")
  fi
}

install_pip "xreach"     "Twitter 搜索工具 (xreach)"
install_pip "yt-dlp"     "YouTube/B站 搜索工具 (yt-dlp)"
install_pip "feedparser" "RSS 订阅工具 (feedparser)"
install_pip "miku-ai"    "微信公众号搜索工具 (miku-ai)"
install_pip "camoufox"   "网页阅读工具 (camoufox)"
install_pip "pyyaml"     "配置文件解析 (pyyaml)"

echo ""

# ---- Step 2: 安装 Node.js 工具 ----
echo -e "${BOLD}📦 安装 MCP 工具（Node.js）...${NC}"
echo -n "  安装 小红书/Exa 搜索工具 (mcporter)..."
if npm install -g mcporter --silent 2>/dev/null; then
  echo -e " ${GREEN}✅${NC}"
else
  echo -e " ${RED}❌${NC}"
  FAILED+=("小红书/Exa 搜索工具 (mcporter)")
fi

echo ""

# ---- Step 3: 检查可选工具 ----
echo -e "${BOLD}🔍 检查可选工具...${NC}"

echo -n "  GitHub CLI (gh)..."
if command -v gh &>/dev/null; then
  echo -e " ${GREEN}✅${NC}"
  if gh auth status &>/dev/null 2>&1; then
    ok "GitHub 已登录"
  else
    warn "GitHub 未登录，GitHub 搜索会自动用网页搜索替代"
    info "如需启用：运行 gh auth login"
  fi
else
  warn "未安装，GitHub 搜索会自动用网页搜索替代"
  info "如需安装：brew install gh (macOS) 或 参考 https://cli.github.com"
fi

echo ""

# ---- Step 4: 创建工作目录 ----
echo -e "${BOLD}📁 创建工作目录...${NC}"
mkdir -p ~/.content-radar/cache
ok "~/.content-radar/ 目录已创建"

# 迁移旧数据（如果存在）
if [ -d "$HOME/.claude/content-pipeline" ]; then
  info "检测到旧版数据，正在迁移..."
  if [ -f "$HOME/.claude/content-pipeline/daily-digest.md" ]; then
    cp "$HOME/.claude/content-pipeline/daily-digest.md" "$HOME/.content-radar/cache/"
    ok "daily-digest.md 已迁移"
  fi
  if [ -f "$HOME/.claude/content-pipeline/topic-candidates.md" ]; then
    cp "$HOME/.claude/content-pipeline/topic-candidates.md" "$HOME/.content-radar/cache/"
    ok "topic-candidates.md 已迁移"
  fi
fi

echo ""

# ---- Step 5: 安装 Skill 文件 ----
echo -e "${BOLD}📄 安装 Skill 文件...${NC}"

SKILL_SOURCE="$SCRIPT_DIR/SKILL.md"
if [ ! -f "$SKILL_SOURCE" ]; then
  fail "找不到 SKILL.md，请确保在仓库目录中运行此脚本"
  exit 1
fi

INSTALLED=false

# Claude Code
if [ -d "$HOME/.claude/skills" ]; then
  mkdir -p "$HOME/.claude/skills/content-radar"
  cp "$SKILL_SOURCE" "$HOME/.claude/skills/content-radar/SKILL.md"
  ok "已安装到 Claude Code"
  INSTALLED=true
fi

# Qwen Code（通义灵码）— 常见路径
for qwen_dir in "$HOME/.qwen-code/skills" "$HOME/.tongyi/skills" "$HOME/.qwen/skills"; do
  if [ -d "$qwen_dir" ]; then
    mkdir -p "$qwen_dir/content-radar"
    cp "$SKILL_SOURCE" "$qwen_dir/content-radar/SKILL.md"
    ok "已安装到 Qwen Code ($qwen_dir)"
    INSTALLED=true
    break
  fi
done

# 通用安装
cp "$SKILL_SOURCE" "$HOME/.content-radar/SKILL.md"
if [ "$INSTALLED" = false ]; then
  warn "未检测到已知 AI 编辑器的 skills 目录"
  info "Skill 文件已放在 ~/.content-radar/SKILL.md"
  info "请手动将它复制到你的 AI 编辑器的 skills 目录中"
fi

# 复制配置示例
if [ -f "$SCRIPT_DIR/examples/my-radar.yaml.example" ]; then
  cp "$SCRIPT_DIR/examples/my-radar.yaml.example" "$HOME/.content-radar/"
  ok "配置示例已复制"
fi

# 复制 mcporter 配置
if [ -f "$SCRIPT_DIR/config/mcporter.json" ]; then
  cp "$SCRIPT_DIR/config/mcporter.json" "$HOME/.content-radar/"
  ok "MCP 配置已复制"
fi

echo ""

# ---- Step 6: 结果汇总 ----
echo "=========================================="

if [ ${#FAILED[@]} -eq 0 ]; then
  echo -e "${GREEN}${BOLD}✅ 全部安装成功！${NC}"
else
  echo -e "${YELLOW}${BOLD}⚠️  大部分工具安装成功，以下工具需要手动处理：${NC}"
  echo ""
  for item in "${FAILED[@]}"; do
    echo -e "  ${RED}❌ $item${NC}"
  done
  echo ""
  echo -e "  ${BLUE}不影响使用！${NC}缺失的工具会自动用其他方式替代。"
  echo "  如果想手动安装，可以运行：pip3 install 工具名"
fi

echo ""
echo -e "${BOLD}🚀 下一步${NC}"
echo ""
echo "  1. 打开你的 AI 编辑器（Claude Code / Qwen Code / Codex 等）"
echo "  2. 输入：内容雷达"
echo "  3. 首次运行会问你 3 个问题来了解你的定位"
echo "  4. 之后每次运行，一条命令自动扫描全网找选题"
echo ""
echo -e "  ${BLUE}遇到问题？${NC}查看 docs/TROUBLESHOOTING.md"
echo ""
