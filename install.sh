#!/usr/bin/env bash
# 一键：没装 DS Bot 就先从官方 GitHub Releases（Fei2411/DS-Bot）下载安装；再把 Chief 包下载到 ~/dsbot-chief-kit，
# 最后打印一段话，复制给 DS Bot 的主机器人，由它用自带的 create_bot 建新 Chief。
# 用法：curl -fsSL https://raw.githubusercontent.com/ehlengithub/dsbot-chief-kit/main/install.sh | bash
# 不碰 DS Bot 的任何数据文件（~/.ds-bot 一个字节都不改）；不带任何密钥、账号、模型配置。
set -euo pipefail
REPO_TGZ="https://codeload.github.com/ehlengithub/dsbot-chief-kit/tar.gz/refs/heads/main"
REL="https://github.com/Fei2411/DS-Bot/releases/latest/download"
PAGE="https://dsbot.app/  （或 https://github.com/Fei2411/DS-Bot/releases）"
OS="$(uname -s)"; ARCH="$(uname -m)"
need(){ command -v "$1" >/dev/null || { echo "缺少 $1，请先安装后再运行"; exit 1; }; }
need curl; need tar

# ---------- 1. DS Bot 装了没有 ----------
app_installed(){
  [ -n "${DSBOT_ASSUME_NOT_INSTALLED:-}" ] && return 1
  case "$OS" in
    Darwin) for d in /Applications "$HOME/Applications"; do
              [ -d "$d/DS Bot.app" ] || [ -d "$d/DeepSeek Bot.app" ] && return 0; done; return 1;;
    Linux)  command -v dsbot >/dev/null || [ -x "/opt/DS Bot/dsbot" ] || ls "$HOME/Applications"/DS-Bot*.AppImage >/dev/null 2>&1;;
    *) return 1;;
  esac
}
install_app(){
  T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
  case "$OS-$ARCH" in
    Darwin-arm64) F=DS-Bot-mac-arm64.zip;;
    Darwin-x86_64) F=DS-Bot-mac-x64.zip;;
    Linux-x86_64) F=DS-Bot-linux-x86_64.AppImage;;
    *) echo "这台电脑（$OS ${ARCH}）没有现成的 DS Bot 安装包，请到官方页面手动下载：$PAGE"; exit 1;;
  esac
  echo "没找到 DS Bot，正在从官方 GitHub 下载 ${F}（约 350MB，请稍等）…"
  curl -fL --progress-bar -o "$T/$F" "$REL/$F"
  curl -fsSL -o "$T/SUMS" "$REL/SHA256SUMS.txt"
  WANT="$(awk -v f="$F" '$2==f{print $1}' "$T/SUMS")"
  if command -v sha256sum >/dev/null; then GOT="$(sha256sum "$T/$F" | awk '{print $1}')"; else GOT="$(shasum -a 256 "$T/$F" | awk '{print $1}')"; fi
  [ -n "$WANT" ] && [ "$WANT" = "$GOT" ] || { echo "安装包校验不通过，已停止。请到官方页面手动下载：$PAGE"; exit 1; }
  echo "校验通过（SHA-256 和官方 SHA256SUMS.txt 一致）"
  DEST="${DSBOT_INSTALL_DIR:-}"
  case "$OS" in
    Darwin) [ -z "$DEST" ] && { [ -w /Applications ] && DEST=/Applications || DEST="$HOME/Applications"; }
            mkdir -p "$DEST"; (cd "$T" && unzip -q "$F")
            APP="$(find "$T" -maxdepth 2 -name '*.app' -type d | head -1)"
            [ -n "$APP" ] || { echo "压缩包里没找到 .app"; exit 1; }
            cp -R "$APP" "$DEST/"; echo "已装到 $DEST/$(basename "$APP")"
            echo "第一次打开时 macOS 可能拦：系统设置 → 隐私与安全性 → 仍要打开。";;
    Linux)  DEST="${DEST:-$HOME/Applications}"; mkdir -p "$DEST"; cp "$T/$F" "$DEST/"; chmod +x "$DEST/$F"
            echo "已装到 $DEST/${F}（AppImage 需要 FUSE2；Ubuntu 24.04 起若打不开，改装官方 deb）";;
  esac
}

FRESH=""
if ! app_installed; then install_app; FRESH=1; fi

# ---------- 2. 下载 Chief 包到固定文件夹 ----------
KIT="${DSBOT_KIT_DIR:-$HOME/dsbot-chief-kit}"
TMPK="$(mktemp -d)"
curl -fsSL "${DSBOT_KIT_TGZ:-$REPO_TGZ}" | tar xz --strip-components=1 -C "$TMPK"
[ -f "$TMPK/docs/chief_instructions.md" ] || { echo "Chief 包下载不完整，已停止"; rm -rf "$TMPK"; exit 1; }
rm -rf "$KIT"; mkdir -p "$(dirname "$KIT")"; mv "$TMPK" "$KIT"
KIT="$(cd "$KIT" && pwd)"

# ---------- 3. 生成要粘贴给主机器人的话 ----------
MSG="请帮我新建一个机器人，按下面步骤做，别改你自己（主机器人）的设定：
1. 先用 list_bots 看看现在有哪些机器人。名字定为 Chief；如果已经有叫 Chief 的，就用 Chief-2，还被占用就 Chief-3，依次往后。
2. 用你的读文件工具读 ${KIT}/docs/chief_instructions.md 的全部内容（一个字都不要删改）。
3. 用 create_bot 新建这个机器人：name 用第 1 步定的名字，role 填「幕僚长」，instructions 填第 2 步读到的全文，brief 写「接单话术和报价助手」。模型不用指定。
4. 建好后用 message_bot 发给这个新机器人：「请用读文件工具读完 ${KIT}/memory/MEMORY.md 和 ${KIT}/memory/接单话术.md 两个文件，把里面每一条规矩和事实用 remember 分条存进你自己的记忆（话术相关的 topic 填 接单话术），存完回我一句。」
5. 新机器人回复存好后，用一句话告诉我：新机器人叫什么名字，记忆存好了没有。"
printf '%s\n' "$MSG" > "$KIT/PASTE_TO_CHIEF.txt"

if [ -n "$FRESH" ]; then
  echo
  echo "DS Bot 已经装好。先做这两步："
  echo "  1) 打开 DS Bot，按提示走完第一次设置，登录你自己的 DeepSeek 账号或填你自己的 API key；"
  echo "  2) 看到默认的主机器人以后，把下面这段话发给它。"
fi
echo
echo "Chief 的文件已放到：${KIT}"
echo "打开 DS Bot，把下面虚线之间的整段话复制，发给主机器人（这段话也存在 ${KIT}/PASTE_TO_CHIEF.txt）："
echo "------------------------------------------------------------"
printf '%s\n' "$MSG"
echo "------------------------------------------------------------"
