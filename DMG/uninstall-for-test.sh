#!/bin/bash
# Uninstall everything the PPIO Claude Installer installs
# Usage: bash uninstall-for-test.sh [--with-homebrew]
#
# Without --with-homebrew: removes Claude CLI, Node.js, shell config, Claude settings
# With    --with-homebrew: also removes Homebrew entirely (⚠ destructive)
# With    --with-xcode-clt: also removes Xcode Command Line Tools (⚠ destructive)

set -uo pipefail

WITH_HOMEBREW=false
WITH_XCODE_CLT=false
for arg in "$@"; do
    [[ "$arg" == "--with-homebrew" ]]   && WITH_HOMEBREW=true
    [[ "$arg" == "--with-xcode-clt" ]]  && WITH_XCODE_CLT=true
done

OK="✓"
SKIP="–"
FAIL="✗"

step() { echo; echo "▸ $1"; }
ok()   { echo "  $OK  $1"; }
skip() { echo "  $SKIP $1"; }
fail() { echo "  $FAIL $1"; }

echo "======================================"
echo " PPIO Claude Installer — 测试环境清理"
echo "======================================"
if [[ "$WITH_HOMEBREW" == true && "$WITH_XCODE_CLT" == true ]]; then
    echo " 模式: 完整清理（含 Homebrew + Xcode CLT）"
elif [[ "$WITH_HOMEBREW" == true ]]; then
    echo " 模式: 完整清理（含 Homebrew）"
elif [[ "$WITH_XCODE_CLT" == true ]]; then
    echo " 模式: 完整清理（含 Xcode CLT）"
else
    echo " 模式: 保留 Homebrew，只清 Claude 相关"
fi
echo

# ── 1. Claude Code CLI ────────────────────────────────────────────
step "卸载 Claude Code CLI"

# Try npm-global prefix first (EACCES workaround path)
NPM_GLOBAL="$HOME/.npm-global"
if [[ -d "$NPM_GLOBAL" ]]; then
    if "$NPM_GLOBAL/bin/npm" uninstall -g @anthropic-ai/claude-code 2>/dev/null \
    || npm --prefix "$NPM_GLOBAL" uninstall -g @anthropic-ai/claude-code 2>/dev/null; then
        ok "npm-global: @anthropic-ai/claude-code 已卸载"
    else
        skip "npm-global: 未找到 claude-code"
    fi
fi

# Try system npm
if command -v npm &>/dev/null; then
    if npm uninstall -g @anthropic-ai/claude-code 2>/dev/null; then
        ok "npm global: @anthropic-ai/claude-code 已卸载"
    else
        skip "npm global: 未找到 claude-code"
    fi
fi

# Remove claude binary directly if still present
for bin in \
    "$NPM_GLOBAL/bin/claude" \
    /opt/homebrew/bin/claude \
    /usr/local/bin/claude; do
    if [[ -f "$bin" ]]; then
        rm -f "$bin" && ok "已删除 $bin" || fail "无法删除 $bin"
    fi
done

# ── 2. ~/.npm-global 目录 ─────────────────────────────────────────
step "清理 ~/.npm-global"
if [[ -d "$NPM_GLOBAL" ]]; then
    rm -rf "$NPM_GLOBAL" && ok "~/.npm-global 已删除" || fail "无法删除 ~/.npm-global"
else
    skip "~/.npm-global 不存在"
fi

# ── 3. Node.js ────────────────────────────────────────────────────
step "卸载 Node.js"
if command -v brew &>/dev/null && brew list node &>/dev/null 2>&1; then
    brew uninstall node && ok "Node.js 已卸载（via brew）" || fail "Node.js 卸载失败"
elif command -v brew &>/dev/null; then
    skip "Node.js 未通过 brew 安装，跳过"
else
    skip "brew 不可用，跳过 Node.js 卸载"
fi

# ── 4. ~/.zshrc 配置块 ────────────────────────────────────────────
step "清理 ~/.zshrc 中的 PP 配置块"
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]]; then
    # Remove the block starting with "# PP Claude Code Configuration"
    # through the last consecutive export/unset/# line
    python3 - "$ZSHRC" <<'PYEOF'
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

marker = '# PP Claude Code Configuration'
if marker not in content:
    print("  –  ~/.zshrc 中未找到 PP 配置块")
    sys.exit(0)

lines = content.split('\n')
out = []
i = 0
removed = 0
while i < len(lines):
    line = lines[i]
    if marker in line:
        # skip this line and subsequent export/unset/empty/comment lines
        i += 1
        removed += 1
        while i < len(lines):
            l = lines[i].strip()
            if l == '' or l.startswith('export ') or l.startswith('unset ') or l.startswith('#'):
                i += 1
                removed += 1
            else:
                break
    else:
        out.append(line)
        i += 1

with open(path, 'w') as f:
    f.write('\n'.join(out))
print(f"  ✓  已从 ~/.zshrc 删除 {removed} 行 PP 配置")
PYEOF
else
    skip "~/.zshrc 不存在"
fi

# ── 5. ~/.zprofile 中的 brew shellenv 和 npm-global PATH ──────────
step "清理 ~/.zprofile 中的安装器写入行"
ZPROFILE="$HOME/.zprofile"
if [[ -f "$ZPROFILE" ]]; then
    python3 - "$ZPROFILE" <<'PYEOF'
import sys

path = sys.argv[1]
with open(path, 'r') as f:
    lines = f.readlines()

targets = [
    'eval "$(/opt/homebrew/bin/brew shellenv)"',
    'eval "$(/usr/local/bin/brew shellenv)"',
    'export PATH=~/.npm-global/bin:$PATH',
]

new_lines = []
removed = []
for line in lines:
    stripped = line.strip()
    if any(t in stripped for t in targets):
        removed.append(stripped)
    else:
        new_lines.append(line)

with open(path, 'w') as f:
    f.writelines(new_lines)

if removed:
    for r in removed:
        print(f"  ✓  已从 ~/.zprofile 删除: {r[:60]}")
else:
    print("  –  ~/.zprofile 中无需清理的行")
PYEOF
else
    skip "~/.zprofile 不存在"
fi

# ── 6. ~/.claude 配置 ─────────────────────────────────────────────
step "清理 ~/.claude 配置"
CLAUDE_DIR="$HOME/.claude"

# Remove PP-written keys from settings.json (keep other keys intact)
SETTINGS="$CLAUDE_DIR/settings.json"
if [[ -f "$SETTINGS" ]]; then
    python3 - "$SETTINGS" <<'PYEOF'
import sys, json

path = sys.argv[1]
with open(path, 'r') as f:
    data = json.load(f)

pp_keys = ['model', 'smallModel', 'skipDangerousModePermissionPrompt']
removed = [k for k in pp_keys if k in data]
for k in removed:
    del data[k]

with open(path, 'w') as f:
    json.dump(data, f, indent=2)

if removed:
    print(f"  ✓  settings.json 中已删除 PP 写入的键: {', '.join(removed)}")
else:
    print("  –  settings.json 中无 PP 写入的键")
PYEOF
else
    skip "~/.claude/settings.json 不存在"
fi

# Remove OAuth/credentials files the installer deletes (they might have been recreated)
for f in credentials.json .credentials.json; do
    fp="$CLAUDE_DIR/$f"
    if [[ -f "$fp" ]]; then
        rm -f "$fp" && ok "已删除 $fp" || fail "无法删除 $fp"
    fi
done

# ── 7. npm registry 镜像配置 ──────────────────────────────────────
step "恢复 npm registry"
if command -v npm &>/dev/null; then
    CURRENT=$(npm config get registry 2>/dev/null)
    if [[ "$CURRENT" == "https://registry.npmmirror.com" ]]; then
        npm config delete registry && ok "npm registry 已恢复为默认" || fail "npm config delete 失败"
    else
        skip "npm registry 未被修改（当前: $CURRENT）"
    fi
else
    skip "npm 不可用，跳过"
fi

# ── 8. (可选) Homebrew ────────────────────────────────────────────
if [[ "$WITH_HOMEBREW" == true ]]; then
    step "卸载 Homebrew ⚠"

    BREW_PREFIX="/opt/homebrew"
    [[ ! -d "$BREW_PREFIX" ]] && BREW_PREFIX="/usr/local"   # Intel fallback

    if ! command -v brew &>/dev/null && [[ ! -d "$BREW_PREFIX" ]]; then
        skip "Homebrew 未安装"
    else
        # 1. 先卸载所有 brew 安装的包（避免 uninstall.sh 卡在依赖检查）
        if command -v brew &>/dev/null; then
            echo "  移除所有 brew 包..."
            brew remove --force --ignore-dependencies $(brew list --formula 2>/dev/null) 2>/dev/null || true
            brew remove --cask --force $(brew list --cask 2>/dev/null) 2>/dev/null || true
        fi

        # 2. 下载官方卸载脚本（先试 USTC 镜像，再试 GitHub）
        TMPSCRIPT=$(mktemp /tmp/brew-uninstall-XXXX.sh)
        echo "  下载卸载脚本..."
        DOWNLOADED=false
        if curl --silent --fail --max-time 10 \
            https://mirrors.ustc.edu.cn/misc/brew-uninstall.sh -o "$TMPSCRIPT" 2>/dev/null; then
            echo "  下载成功（USTC 镜像）"
            DOWNLOADED=true
        elif curl --silent --fail --max-time 15 \
            https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o "$TMPSCRIPT" 2>/dev/null; then
            echo "  下载成功（GitHub）"
            DOWNLOADED=true
        fi

        if [[ "$DOWNLOADED" == true && -s "$TMPSCRIPT" ]]; then
            NONINTERACTIVE=1 /bin/bash "$TMPSCRIPT"
            rm -f "$TMPSCRIPT"
        else
            rm -f "$TMPSCRIPT"
            echo "  脚本下载失败，跳过官方脚本，直接强删..."
        fi

        # 3. 不管官方脚本是否成功，强制删除 Homebrew 目录和符号链接
        if [[ -d "$BREW_PREFIX" ]]; then
            echo "  强制删除 $BREW_PREFIX （需要 sudo 密码）..."
            sudo rm -rf "$BREW_PREFIX" \
                && ok "$BREW_PREFIX 已删除" \
                || fail "无法删除 $BREW_PREFIX，请手动运行: sudo rm -rf $BREW_PREFIX"
        fi

        # 4. 清理 /usr/local/bin 下的 brew 符号链接（Intel 机器）
        for link in /usr/local/bin/brew /usr/local/share/doc/homebrew \
                    /usr/local/share/man/man1/brew.1; do
            [[ -L "$link" || -f "$link" ]] && sudo rm -f "$link" 2>/dev/null || true
        done

        # 5. 验证
        if ! command -v brew &>/dev/null && [[ ! -d "$BREW_PREFIX" ]]; then
            ok "Homebrew 已完全卸载"
        else
            fail "Homebrew 可能未完全卸载，请手动检查"
            echo "    手动命令: sudo rm -rf /opt/homebrew"
        fi
    fi
else
    step "Homebrew（保留）"
    skip "未传 --with-homebrew，跳过"
fi

# ── 9. (可选) Xcode Command Line Tools ───────────────────────────
if [[ "$WITH_XCODE_CLT" == true ]]; then
    step "卸载 Xcode Command Line Tools ⚠"
    CLT_PATH="/Library/Developer/CommandLineTools"
    if [[ -d "$CLT_PATH" ]]; then
        echo "  删除 $CLT_PATH （需要 sudo 密码）..."
        sudo rm -rf "$CLT_PATH" \
            && ok "Xcode CLT 已删除" \
            || fail "无法删除 $CLT_PATH，请手动运行: sudo rm -rf $CLT_PATH"
    else
        skip "Xcode CLT 未安装（$CLT_PATH 不存在）"
    fi
else
    step "Xcode Command Line Tools（保留）"
    skip "未传 --with-xcode-clt，跳过"
fi

# ── 完成 ──────────────────────────────────────────────────────────
echo
echo "======================================"
echo " 清理完成"
echo "======================================"
echo
echo " 验证命令（新终端中运行）："
echo "   which claude     # 应该找不到"
echo "   which node       # 取决于是否保留 brew"
echo "   brew --version   # 如传了 --with-homebrew 则找不到"
echo "   xcode-select -p  # 如传了 --with-xcode-clt 则报错"
echo
echo " 可选 flag（可组合使用）："
echo "   bash uninstall-for-test.sh --with-homebrew"
echo "   bash uninstall-for-test.sh --with-xcode-clt"
echo "   bash uninstall-for-test.sh --with-homebrew --with-xcode-clt"
