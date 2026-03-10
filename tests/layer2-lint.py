#!/usr/bin/env python3
"""Layer 2: SKILL.md static consistency checker.

Analyzes SKILL.md text to catch common issues:
- Missing command parameters (proxy, jq, cookies)
- URL format errors
- Template coverage gaps
- Rule completeness

Usage: python3 tests/layer2-lint.py [path/to/SKILL.md]
"""
import re
import sys
import os

PASS = 0
FAIL = 0
WARN = 0
results = []


def record(check_id, name, status, detail=""):
    global PASS, FAIL, WARN
    results.append((check_id, name, status, detail))
    if status == "PASS":
        PASS += 1
    elif status == "FAIL":
        FAIL += 1
    elif status == "WARN":
        WARN += 1


def extract_code_blocks(text):
    """Extract all bash code blocks with their line numbers."""
    blocks = []
    lines = text.split("\n")
    in_block = False
    block_start = 0
    block_lines = []
    for i, line in enumerate(lines):
        if line.strip().startswith("```bash"):
            in_block = True
            block_start = i + 1
            block_lines = []
        elif line.strip() == "```" and in_block:
            in_block = False
            blocks.append((block_start, block_lines))
        elif in_block:
            block_lines.append((i + 1, line))
    return blocks


def extract_code_line_commands(blocks, cmd_prefix):
    """Extract lines from code blocks that contain a given command (not just checking existence)."""
    found = []
    for block_start, block_lines in blocks:
        for lineno, line in block_lines:
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            # Skip `command -v` checks (just checking if tool is installed)
            if "command -v" in stripped:
                continue
            if re.search(rf'\b{cmd_prefix}\b', stripped):
                found.append((lineno, stripped))
    return found


def check_L03_xreach_proxy(text, blocks):
    """All xreach commands in code blocks must have proxy template."""
    xreach_cmds = extract_code_line_commands(blocks, "xreach")
    issues = []
    for lineno, line in xreach_cmds:
        # Skip detection/test commands (one-shot checks)
        if '2>/dev/null' in line and ('&& echo' in line or '|| echo' in line):
            # This is a detection script line — proxy is handled separately
            # But it should still have proxy if it's the auth check
            if 'XREACH_AUTH' in line and 'proxy' not in line.lower():
                issues.append(f"  Line {lineno}: auth check missing proxy: {line[:80]}")
            continue
        if 'proxy' not in line.lower() and '--proxy' not in line:
            issues.append(f"  Line {lineno}: xreach command missing proxy: {line[:80]}")
    if issues:
        record("L03", "xreach proxy template", "FAIL", "\n".join(issues))
    else:
        count = len(xreach_cmds)
        record("L03", "xreach proxy template", "PASS", f"{count} commands checked")


def check_L04_ytdlp_jq(text, blocks):
    """All yt-dlp --dump-json commands must pipe to jq."""
    issues = []
    for block_start, block_lines in blocks:
        for lineno, line in block_lines:
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            if "yt-dlp" in stripped and "--dump-json" in stripped:
                if "| jq" not in stripped:
                    issues.append(f"  Line {lineno}: yt-dlp --dump-json without jq: {stripped[:80]}")
    if issues:
        record("L04", "yt-dlp jq filter", "FAIL", "\n".join(issues))
    else:
        record("L04", "yt-dlp jq filter", "PASS")


def check_L05_ytdlp_cookies(text, blocks):
    """All yt-dlp commands must use --cookies-from-browser {{browser}}."""
    issues = []
    for block_start, block_lines in blocks:
        for lineno, line in block_lines:
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            if "yt-dlp" in stripped and "yt-dlp --help" not in stripped and "command -v" not in stripped:
                if "--cookies-from-browser" not in stripped:
                    issues.append(f"  Line {lineno}: yt-dlp without --cookies-from-browser: {stripped[:80]}")
                elif "chrome" in stripped and "{{browser}}" not in stripped:
                    issues.append(f"  Line {lineno}: hardcoded 'chrome' instead of {{{{browser}}}}: {stripped[:80]}")
    if issues:
        record("L05", "yt-dlp cookies browser var", "FAIL", "\n".join(issues))
    else:
        record("L05", "yt-dlp cookies browser var", "PASS")


def check_L06_question_format(text, lines):
    """Q1-Q5 should use numbered selection format."""
    issues = []
    # Find Q sections
    q_pattern = re.compile(r'### Q(\d+)：')
    for i, line in enumerate(lines):
        m = q_pattern.search(line)
        if m:
            qnum = m.group(1)
            # Look ahead for format enforcement
            lookahead = "\n".join(lines[i:i+20])
            if qnum in ("2", "3"):
                # Q2 and Q3 must have numbered list format
                if "禁止" not in lookahead:
                    issues.append(f"  Q{qnum} (line {i+1}): missing format enforcement instruction (禁止...)")
                if not re.search(r'\d+\.\s', lookahead):
                    issues.append(f"  Q{qnum} (line {i+1}): missing numbered list format")
    if issues:
        record("L06", "question format consistency", "FAIL", "\n".join(issues))
    else:
        record("L06", "question format consistency", "PASS")


def check_L07_no_bilisearch(text, blocks):
    """bilisearch should only appear in warnings, not in executable commands."""
    issues = []
    for block_start, block_lines in blocks:
        for lineno, line in block_lines:
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            if "bilisearch" in stripped:
                issues.append(f"  Line {lineno}: bilisearch in code block: {stripped[:80]}")
    if issues:
        record("L07", "no bilisearch commands", "FAIL", "\n".join(issues))
    else:
        record("L07", "no bilisearch commands", "PASS")


def check_L08_jina_url(text, blocks):
    """Jina r.jina.ai/ URLs must be followed by https://."""
    issues = []
    for block_start, block_lines in blocks:
        for lineno, line in block_lines:
            stripped = line.strip()
            if stripped.startswith("#"):
                continue
            matches = re.findall(r'r\.jina\.ai/([^\s"\'`]+)', stripped)
            for url_part in matches:
                if not url_part.startswith("https://"):
                    issues.append(f"  Line {lineno}: r.jina.ai/ not followed by https://: {stripped[:80]}")
    if issues:
        record("L08", "Jina URL format", "FAIL", "\n".join(issues))
    else:
        record("L08", "Jina URL format", "PASS")


def check_L02_url_rules(text, lines):
    """URL construction rules must cover all platforms."""
    required_platforms = {
        "Twitter": r"x\.com.*status",
        "YouTube": r"youtube\.com/watch",
        "B站": r"bilibili\.com/video",
        "小红书": r"xiaohongshu\.com/explore",
        "GitHub": r"github\.com",
    }
    # Find the URL rules section
    url_section = ""
    in_section = False
    for line in lines:
        if "采集时必须保留" in line or "构造完整 URL" in line:
            in_section = True
        elif in_section and (line.startswith("##") or line.startswith("**输出物")):
            break
        elif in_section:
            url_section += line + "\n"

    issues = []
    for platform, pattern in required_platforms.items():
        if not re.search(pattern, url_section):
            issues.append(f"  Missing URL rule for: {platform}")
    if issues:
        record("L02", "URL rules coverage", "FAIL", "\n".join(issues))
    else:
        record("L02", "URL rules coverage", "PASS", f"{len(required_platforms)} platforms covered")


def check_L10_output_template_icons(text, lines):
    """Output template must include icons for all platforms."""
    required_icons = {
        "🐦": "Twitter",
        "🎬": "YouTube",
        "📺": "B站",
        "📕": "小红书",
        "💻": "GitHub",
    }
    # Find the learning materials template section
    template_section = ""
    in_section = False
    for line in lines:
        if "学习材料" in line and "每条附原始" in line:
            in_section = True
        elif in_section and (line.startswith("**") or line.startswith(">") or line.strip() == ""):
            if line.strip().startswith(">"):
                template_section += line + "\n"
                continue
            if line.strip() == "":
                continue
            break
        elif in_section:
            template_section += line + "\n"

    issues = []
    for icon, platform in required_icons.items():
        if icon not in template_section:
            issues.append(f"  Missing icon {icon} ({platform}) in output template")
    if issues:
        record("L10", "output template icons", "FAIL", "\n".join(issues))
    else:
        record("L10", "output template icons", "PASS", f"{len(required_icons)} icons present")


def check_L12_rules_completeness(text, lines):
    """Rules section must contain key prohibitions."""
    rules_section = ""
    in_rules = False
    for line in lines:
        if line.strip() == "## 规则":
            in_rules = True
        elif in_rules and line.startswith("## "):
            break
        elif in_rules:
            rules_section += line + "\n"

    required_rules = [
        ("禁止.*技术命令", "prohibit technical commands"),
        ("禁止.*代理|禁止.*排障", "prohibit proxy/troubleshooting advice"),
        ("setup.sh", "point to setup.sh for missing tools"),
    ]
    issues = []
    for pattern, desc in required_rules:
        if not re.search(pattern, rules_section):
            issues.append(f"  Missing rule: {desc} (pattern: {pattern})")
    if issues:
        record("L12", "rules completeness", "FAIL", "\n".join(issues))
    else:
        record("L12", "rules completeness", "PASS")


def check_L11_degradation_labels(text, lines):
    """Degradation paths should be labeled 🔴, direct paths 🟢."""
    # Check that the labeling rule section exists
    if "直连无结果" not in text and "工具可用但搜不到" not in text:
        record("L11", "degradation label rules", "WARN",
               "  No explicit rule distinguishing '直连无结果' from '降级'")
    else:
        record("L11", "degradation label rules", "PASS")


def check_L13_step0_output_link(text, lines):
    """Step 5 should have a pre-output checklist."""
    if "输出前自检" not in text and "输出前检查" not in text:
        record("L13", "Step 5 output checklist", "FAIL",
               "  No pre-output checklist found in Step 5")
    else:
        record("L13", "Step 5 output checklist", "PASS")


def check_L14_breaking_circle_url(text, lines):
    """Breaking circle template must mention URL construction."""
    # Find the Part 3 breaking circle output section (near "Part 3：破圈")
    bc_section = ""
    in_bc = False
    for line in lines:
        if "Part 3" in line and "破圈" in line:
            in_bc = True
        elif in_bc and (line.startswith("## ") and "破圈" not in line):
            break
        elif in_bc:
            bc_section += line + "\n"

    if "bilibili.com/video" not in bc_section and "xiaohongshu.com/explore" not in bc_section:
        record("L14", "breaking circle URL hints", "FAIL",
               "  Breaking circle template missing platform URL construction hints")
    else:
        record("L14", "breaking circle URL hints", "PASS")


def check_L15_proxy_autodetect(text, lines):
    """Proxy should be auto-detected, not asked via Q&A."""
    has_auto = "自动检测" in text and ("HTTPS_PROXY" in text or "HTTP_PROXY" in text)
    has_q_proxy = bool(re.search(r'Q\d+.*代理|Q\d+.*梯子', text))

    if has_q_proxy:
        record("L15", "proxy not in Q&A", "FAIL",
               "  Proxy collection appears in Q&A flow (sensitive topic)")
    elif has_auto:
        record("L15", "proxy not in Q&A", "PASS", "Auto-detection via env vars")
    else:
        record("L15", "proxy not in Q&A", "WARN",
               "  No proxy auto-detection found")


def main():
    skill_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "SKILL.md"
    )

    if not os.path.exists(skill_path):
        print(f"ERROR: {skill_path} not found")
        sys.exit(1)

    with open(skill_path, "r") as f:
        text = f.read()
    lines = text.split("\n")
    blocks = extract_code_blocks(text)

    print("=" * 50)
    print("Layer 2: SKILL.md Static Consistency Check")
    print("=" * 50)
    print()

    check_L02_url_rules(text, lines)
    check_L03_xreach_proxy(text, blocks)
    check_L04_ytdlp_jq(text, blocks)
    check_L05_ytdlp_cookies(text, blocks)
    check_L06_question_format(text, lines)
    check_L07_no_bilisearch(text, blocks)
    check_L08_jina_url(text, blocks)
    check_L10_output_template_icons(text, lines)
    check_L11_degradation_labels(text, lines)
    check_L12_rules_completeness(text, lines)
    check_L13_step0_output_link(text, lines)
    check_L14_breaking_circle_url(text, lines)
    check_L15_proxy_autodetect(text, lines)

    # Print results
    for check_id, name, status, detail in results:
        icon = {"PASS": "✅", "FAIL": "❌", "WARN": "⚠️"}.get(status, "?")
        print(f"{icon} {check_id}: {name} — {status}")
        if detail and status != "PASS":
            print(detail)

    print()
    print(f"Summary: {PASS} PASS / {FAIL} FAIL / {WARN} WARN")

    if FAIL > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
