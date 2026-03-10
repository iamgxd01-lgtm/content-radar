#!/bin/bash
# Layer 1: Command Verification
# Tests that SKILL.md bash commands actually work in the current environment.
# Usage: bash tests/layer1-commands.sh [--verbose]

set -o pipefail

VERBOSE=false
[[ "$1" == "--verbose" ]] && VERBOSE=true

# macOS compatibility: use gtimeout if timeout not available
if command -v timeout &>/dev/null; then
  TIMEOUT="timeout"
elif command -v gtimeout &>/dev/null; then
  TIMEOUT="gtimeout"
else
  # No timeout available, run without timeout
  TIMEOUT=""
fi
run_with_timeout() {
  local secs=$1; shift
  if [ -n "$TIMEOUT" ]; then
    $TIMEOUT "$secs" "$@"
  else
    "$@"
  fi
}

PASS=0; FAIL=0; SKIP=0
RESULTS=()

# Test config
KEYWORD="Claude Code"
KEYWORD_CN="Claude Code 教程"
BROWSER="chrome"
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Colors
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

record() {
  local id=$1 name=$2 status=$3 detail=$4
  RESULTS+=("$id|$name|$status|$detail")
  case $status in
    PASS) ((PASS++)); $VERBOSE && echo -e "${GREEN}✅ $id: $name — PASS${NC}" ;;
    FAIL) ((FAIL++)); echo -e "${RED}❌ $id: $name — FAIL${NC}"; [[ -n "$detail" ]] && echo "   $detail" ;;
    SKIP) ((SKIP++)); $VERBOSE && echo -e "${YELLOW}⏭️  $id: $name — SKIP${NC} ($detail)" ;;
  esac
}

# === Proxy auto-detection (replicates SKILL.md Step 0 logic) ===
PROXY="${HTTPS_PROXY:-${HTTP_PROXY:-${ALL_PROXY:-}}}"
PROXY_FLAG=""
if [ -n "$PROXY" ]; then
  PROXY_FLAG="--proxy $PROXY"
fi

echo "=================================================="
echo "Layer 1: Command Verification"
echo "=================================================="
echo "Proxy: ${PROXY:-NONE}"
echo ""

# --- C01: Tool availability detection ---
TOOLS_OK=true
for tool in xreach yt-dlp jq mcporter; do
  if ! command -v "$tool" &>/dev/null; then
    record "C01" "$tool installed" "SKIP" "not installed"
    TOOLS_OK=false
  fi
done
if $TOOLS_OK; then
  record "C01" "core tools installed" "PASS" "xreach, yt-dlp, jq, mcporter"
fi

# --- C02: Proxy detection script ---
PROXY_SCRIPT_OUT=$(bash -c '
PROXY="${HTTPS_PROXY:-${HTTP_PROXY:-${ALL_PROXY:-}}}"
if [ -n "$PROXY" ]; then echo "PROXY=$PROXY"; else echo "PROXY=NONE"; fi
' 2>&1)
if echo "$PROXY_SCRIPT_OUT" | grep -qE '^PROXY=(NONE|https?://)'; then
  record "C02" "proxy detection script" "PASS" "$PROXY_SCRIPT_OUT"
else
  record "C02" "proxy detection script" "FAIL" "unexpected output: $PROXY_SCRIPT_OUT"
fi

# --- C03: xreach search ---
if command -v xreach &>/dev/null; then
  XOUT=$(run_with_timeout 15 xreach search "$KEYWORD" -n 1 --json $PROXY_FLAG 2>"$TMPDIR/xreach_err")
  XEXIT=$?
  if [ $XEXIT -eq 0 ] && echo "$XOUT" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    record "C03" "xreach search" "PASS" "valid JSON returned"
  elif grep -qi "tls\|network\|socket\|ECONNREFUSED" "$TMPDIR/xreach_err" 2>/dev/null; then
    record "C03" "xreach search" "SKIP" "network/proxy issue"
  elif grep -qi "auth\|login\|401" "$TMPDIR/xreach_err" 2>/dev/null; then
    record "C03" "xreach search" "SKIP" "not authenticated"
  else
    record "C03" "xreach search" "FAIL" "exit=$XEXIT stderr=$(head -1 "$TMPDIR/xreach_err")"
  fi
else
  record "C03" "xreach search" "SKIP" "xreach not installed"
fi

# --- C04: xreach tweets ---
if command -v xreach &>/dev/null; then
  XOUT=$(run_with_timeout 15 xreach tweets anthropic -n 1 --json $PROXY_FLAG 2>"$TMPDIR/xreach_err2")
  XEXIT=$?
  if [ $XEXIT -eq 0 ] && echo "$XOUT" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    record "C04" "xreach tweets" "PASS" "valid JSON returned"
  elif grep -qi "tls\|network\|socket" "$TMPDIR/xreach_err2" 2>/dev/null; then
    record "C04" "xreach tweets" "SKIP" "network/proxy issue"
  else
    record "C04" "xreach tweets" "FAIL" "exit=$XEXIT"
  fi
else
  record "C04" "xreach tweets" "SKIP" "xreach not installed"
fi

# --- C05: yt-dlp + jq field filter (YouTube) ---
if command -v yt-dlp &>/dev/null && command -v jq &>/dev/null; then
  YTOUT=$(run_with_timeout 30 yt-dlp --cookies-from-browser "$BROWSER" --dump-json "ytsearch1:$KEYWORD" 2>"$TMPDIR/yt_err" \
    | jq '{title, description, tags, upload_date, view_count, like_count, comment_count, channel, channel_follower_count, webpage_url}' 2>/dev/null)
  YTEXIT=$?
  if [ $YTEXIT -eq 0 ] && echo "$YTOUT" | jq -e '.title' &>/dev/null; then
    # Verify no unwanted fields leaked through
    FIELD_COUNT=$(echo "$YTOUT" | jq 'keys | length' 2>/dev/null)
    if [ "$FIELD_COUNT" -le 10 ]; then
      record "C05" "yt-dlp YouTube + jq" "PASS" "$FIELD_COUNT fields (expected ≤10)"
    else
      record "C05" "yt-dlp YouTube + jq" "FAIL" "$FIELD_COUNT fields leaked through jq filter"
    fi
  elif grep -qi "Sign in\|login\|cookies" "$TMPDIR/yt_err" 2>/dev/null; then
    record "C05" "yt-dlp YouTube + jq" "SKIP" "needs browser login"
  else
    record "C05" "yt-dlp YouTube + jq" "FAIL" "exit=$YTEXIT err=$(head -1 "$TMPDIR/yt_err")"
  fi
else
  record "C05" "yt-dlp YouTube + jq" "SKIP" "yt-dlp or jq not installed"
fi

# --- C06: mcporter exa ---
if command -v mcporter &>/dev/null; then
  MOUT=$(run_with_timeout 15 mcporter call 'exa.web_search_exa(query: "test", numResults: 1)' 2>&1)
  if echo "$MOUT" | grep -q '"results"'; then
    record "C06" "mcporter exa" "PASS" "results returned"
  elif echo "$MOUT" | grep -qi "offline\|ECONNREFUSED\|not found\|404\|Unknown"; then
    record "C06" "mcporter exa" "SKIP" "exa service offline/not configured"
  else
    record "C06" "mcporter exa" "FAIL" "no 'results' in output"
  fi
else
  record "C06" "mcporter exa" "SKIP" "mcporter not installed"
fi

# --- C07: mcporter xiaohongshu ---
if command -v mcporter &>/dev/null; then
  MOUT=$(run_with_timeout 15 mcporter call 'xiaohongshu.search_feeds(keyword: "test")' 2>&1)
  if echo "$MOUT" | grep -q '"feeds"'; then
    record "C07" "mcporter xiaohongshu" "PASS" "feeds returned"
  elif echo "$MOUT" | grep -qi "not found\|404\|ECONNREFUSED\|offline\|Unknown"; then
    record "C07" "mcporter xiaohongshu" "SKIP" "xiaohongshu service unavailable"
  else
    record "C07" "mcporter xiaohongshu" "FAIL" "no 'feeds' in output"
  fi
else
  record "C07" "mcporter xiaohongshu" "SKIP" "mcporter not installed"
fi

# --- C08: Jina Reader B站 search page ---
JOUT=$(run_with_timeout 15 curl -sf "https://r.jina.ai/https://search.bilibili.com/all?keyword=Claude%20Code" 2>/dev/null | head -100)
if [ -n "$JOUT" ] && echo "$JOUT" | grep -qi "BV\|bilibili\|哔哩"; then
  record "C08" "Jina B站 search" "PASS" "returned B站 content with BV numbers"
elif [ -z "$JOUT" ]; then
  record "C08" "Jina B站 search" "SKIP" "Jina Reader returned empty"
else
  record "C08" "Jina B站 search" "FAIL" "returned content but no BV numbers found"
fi

# --- C09: Python feedparser ---
if python3 -c "import feedparser; f=feedparser.parse('https://www.anthropic.com/feed'); assert len(f.entries)>0" 2>/dev/null; then
  record "C09" "feedparser RSS" "PASS" "Anthropic RSS parsed"
elif python3 -c "import feedparser" 2>/dev/null; then
  record "C09" "feedparser RSS" "SKIP" "feedparser installed but RSS fetch failed"
else
  record "C09" "feedparser RSS" "SKIP" "feedparser not installed"
fi

# --- C10: Python pyyaml ---
if python3 -c "import yaml; yaml.safe_load('topic: test')" 2>/dev/null; then
  record "C10" "pyyaml" "PASS"
else
  record "C10" "pyyaml" "SKIP" "pyyaml not installed"
fi

# === Summary ===
echo ""
echo "=================================================="
echo "Summary: $PASS PASS / $FAIL FAIL / $SKIP SKIP"
echo "=================================================="

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "FAILED tests indicate bugs in SKILL.md commands."
  exit 1
fi
