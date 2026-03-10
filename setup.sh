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
  # 逐层重试：正常 → 跳过 SSL → 允许系统包覆盖 → 全部放开
  pip3 install "$pkg" --user --quiet 2>/dev/null \
    || pip3 install "$pkg" --user --quiet --trusted-host pypi.org --trusted-host files.pythonhosted.org 2>/dev/null \
    || pip3 install "$pkg" --user --quiet --break-system-packages 2>/dev/null \
    || pip3 install "$pkg" --user --quiet --break-system-packages --trusted-host pypi.org --trusted-host files.pythonhosted.org 2>/dev/null
  if [ $? -eq 0 ]; then
    echo -e " ${GREEN}✅${NC}"
  else
    echo -e " ${RED}❌${NC}"
    FAILED+=("$display_name")
  fi
}

install_pip "yt-dlp"     "YouTube/B站 搜索 (yt-dlp)"
install_pip "feedparser" "RSS 订阅 (feedparser)"
install_pip "camoufox"   "网页阅读 (camoufox)"
install_pip "pyyaml"     "配置文件解析 (pyyaml)"

echo ""

# ---- Step 2: 安装 Node.js 工具 ----
echo -e "${BOLD}📦 安装搜索工具（Node.js）...${NC}"

install_npm() {
  local pkg=$1
  local display_name=$2
  echo -n "  安装 ${display_name}..."
  if npm install -g "$pkg" --silent 2>/dev/null; then
    echo -e " ${GREEN}✅${NC}"
  else
    echo -e " ${RED}❌${NC}"
    FAILED+=("$display_name")
  fi
}

install_npm "xreach-cli" "Twitter/X 搜索 (xreach)"
install_npm "mcporter"   "小红书/Exa 搜索 (mcporter)"

echo ""

# ---- Step 3: 创建工作目录 ----
echo -e "${BOLD}📁 创建工作目录...${NC}"
mkdir -p ~/.content-radar/cache/breakdown
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

# ---- Step 4: 安装 Skill 文件 ----
echo -e "${BOLD}📄 安装 Skill 文件...${NC}"

SKILL_RADAR="$SCRIPT_DIR/SKILL.md"
SKILL_BREAKDOWN="$SCRIPT_DIR/BREAKDOWN.md"

if [ ! -f "$SKILL_RADAR" ]; then
  fail "找不到 SKILL.md，请确保在仓库目录中运行此脚本"
  exit 1
fi

INSTALLED=false

# 安装函数：同时安装两个 Skill
install_skills() {
  local skills_dir=$1
  local editor_name=$2

  mkdir -p "$skills_dir/content-radar"
  cp "$SKILL_RADAR" "$skills_dir/content-radar/SKILL.md"

  if [ -f "$SKILL_BREAKDOWN" ]; then
    mkdir -p "$skills_dir/content-breakdown"
    cp "$SKILL_BREAKDOWN" "$skills_dir/content-breakdown/SKILL.md"
    ok "已安装到 $editor_name（内容雷达 + 爆款拆解）"
  else
    ok "已安装到 $editor_name（内容雷达）"
  fi
  INSTALLED=true
}

# Claude Code
if [ -d "$HOME/.claude/skills" ]; then
  install_skills "$HOME/.claude/skills" "Claude Code"
fi

# Qwen Code（通义灵码）— 常见路径
for qwen_dir in "$HOME/.qwen-code/skills" "$HOME/.tongyi/skills" "$HOME/.qwen/skills"; do
  if [ -d "$qwen_dir" ]; then
    install_skills "$qwen_dir" "Qwen Code"
    break
  fi
done

# 通用安装
cp "$SKILL_RADAR" "$HOME/.content-radar/SKILL.md"
if [ -f "$SKILL_BREAKDOWN" ]; then
  cp "$SKILL_BREAKDOWN" "$HOME/.content-radar/BREAKDOWN.md"
fi
if [ "$INSTALLED" = false ]; then
  warn "未检测到已知 AI 编辑器的 skills 目录"
  info "Skill 文件已放在 ~/.content-radar/"
  info "请手动将它们复制到你的 AI 编辑器的 skills 目录中"
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

# ---- Step 5: 写入安装标记 ----
echo "$( date '+%Y-%m-%d %H:%M' )" > "$HOME/.content-radar/.installed"

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
echo -e "${BOLD}🔑 登录你的账号（可选，数据更好）${NC}"
echo ""
echo "  不登录也能用！AI 会用网页搜索替代。"
echo "  但登录后能拿到更新鲜、更完整的数据，推荐的选题质量更高。"
echo ""
echo -e "  ${BOLD}Twitter/X${NC} — 登录后能搜到实时讨论，比博客早 3-7 天发现新趋势"
echo -e "  ${BOLD}YouTube/B站${NC} — 登录后能看到视频字幕和评论，分析更深入"
echo -e "  ${BOLD}小红书${NC} — 登录后能看到热帖和评论区，了解受众真实需求"
echo ""
echo "  首次使用时，AI 编辑器会一步步引导你完成登录，跟着做就行。"
echo -e "  ${BLUE}现在不用管这些，直接进入下一步。${NC}"
echo ""
echo "=========================================="
echo ""
echo -e "${BOLD}🚀 下一步${NC}"
echo ""
echo "  1. 打开你的 AI 编辑器（Claude Code / Qwen Code / Codex 等）"
echo "  2. 输入 \"内容雷达\" → 全网扫描找选题"
echo "  3. 输入 \"拆解 [URL]\" → 深度拆解一条爆款内容"
echo "  4. 首次运行会问你 3 个问题来了解你的定位，之后全自动"
echo ""
echo -e "${BOLD}📢 本版亮点${NC}"
echo ""
echo "  ✨ 一键安装，AI 不再需要临场拼装命令"
echo "  ✨ 每条数据标注信源质量（🟢一手 / 🟡二手 / 🔴降级）"
echo "  ✨ 选题标注时效性（🔥24h / 📅本周 / 📦更早）"
echo "  ✨ 新增批量拆解（\"批量拆解 URL1 URL2\"）"
echo "  ✨ 新增素材提取（\"提取素材 URL\"）"
echo "  ✨ 评分维度可自定义（不限于默认四维）"
echo ""
echo -e "  ${BLUE}遇到问题？${NC}查看 docs/TROUBLESHOOTING.md"
echo ""
