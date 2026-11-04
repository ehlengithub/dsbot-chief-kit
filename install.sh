#!/usr/bin/env bash
# 一键：没装 DS Bot 就先从官方 GitHub Releases（Fei2411/DS-Bot）下载安装；装了就新建一个 Chief 机器人。
# 用法：curl -fsSL https://raw.githubusercontent.com/ehlengithub/dsbot-chief-kit/main/install.sh | bash
# 不动已有机器人；重名自动叫 Chief-2、Chief-3…；不带任何密钥、账号、模型配置。
set -euo pipefail
REPO_TGZ="https://codeload.github.com/ehlengithub/dsbot-chief-kit/tar.gz/refs/heads/main"
REL="https://github.com/Fei2411/DS-Bot/releases/latest/download"
PAGE="https://dsbot.app/  （或 https://github.com/Fei2411/DS-Bot/releases）"
OS="$(uname -s)"; ARCH="$(uname -m)"
need(){ command -v "$1" >/dev/null || { echo "缺少 $1，请先安装后再运行"; exit 1; }; }
need curl; need python3

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

# ---------- 2. 数据目录在哪 ----------
find_data(){
  [ -n "${DSBOT_HOME:-}" ] && { echo "$DSBOT_HOME"; return; }
  case "$OS" in Darwin) U="$HOME/Library/Application Support";; *) U="${XDG_CONFIG_HOME:-$HOME/.config}";; esac
  for n in "DS Bot" "DeepSeek Bot"; do
    L="$U/$n/locations.json"
    [ -f "$L" ] && { python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["dataDir"])' "$L" 2>/dev/null && return; }
  done
  echo "$HOME/.ds-bot"
}

FIRST_RUN_MSG="下一步：
  1) 打开 DS Bot，按提示走完第一次设置（选数据位置），在设置里登录你自己的 DeepSeek 账号或填你自己的 API key；
  2) 看到默认机器人后，完全退出 DS Bot；
  3) 再运行一次同一条命令，就会装上 Chief。"

if ! app_installed; then install_app; echo; echo "DS Bot 已安装。$FIRST_RUN_MSG"; exit 0; fi

H="$(find_data)"; S="$H/bot/state.json"
[ -f "$S" ] || { echo "DS Bot 已安装，但还没完成第一次设置（没找到 ${S}）。"; echo "$FIRST_RUN_MSG"; exit 0; }

if [ -z "${DSBOT_SKIP_RUNCHECK:-}" ] && pgrep -fi "DS Bot.app/|DeepSeek Bot.app/|DS Bot/dsbot|DS-Bot.*AppImage|/usr/bin/dsbot" >/dev/null 2>&1; then
  echo "DS Bot 正在运行，请先完全退出 DS Bot，再运行一次这条命令"; exit 1; fi

# ---------- 3. 拿到 Chief 的文件 ----------
SRC="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -z "$SRC" ] || [ ! -f "$SRC/bot/chief.json" ]; then
  K="$(mktemp -d)"; curl -fsSL "${DSBOT_KIT_TGZ:-$REPO_TGZ}" | tar xz --strip-components=1 -C "$K"; SRC="$K"
fi

# ---------- 4. 新建机器人 ----------
BAK="$S.bak.$(date +%Y%m%d%H%M%S).$$"; cp "$S" "$BAK"; echo "已备份：$BAK"
OUT=$(KIT="$SRC" S="$S" python3 - <<'P'
import json,os,uuid,time
s=os.environ['S'];kit=os.environ['KIT']
d=json.load(open(s,encoding='utf-8'))
c=json.load(open(os.path.join(kit,'bot','chief.json'),encoding='utf-8'))
bots=d.setdefault('bots',{})
names={b.get('name') for b in bots.values()}
name=c['name'];n=2
while name in names: name=f"{c['name']}-{n}";n+=1
sid='session-'+str(uuid.uuid4())
model=c['model']
for i in d.get('mainBotIds',[]):
    if i in bots and bots[i].get('model'): model=bots[i]['model'];break
bots[sid]={'id':sid,'name':name,'role':c['role'],'color':c['color'],'avatar':c['avatar'],
 'instructions':c['instructions'],'createdAt':int(time.time()*1000),'createdBy':None,
 'capabilities':[],'model':model,'appliedModel':model}
d['revision']=int(d.get('revision',0))+1
tmp=s+'.tmp';json.dump(d,open(tmp,'w',encoding='utf-8'),ensure_ascii=False,indent=2);os.replace(tmp,s)
json.load(open(s,encoding='utf-8'))
print(sid+'\t'+name)
P
)
ID="${OUT%%$'\t'*}"; NAME="${OUT#*$'\t'}"
M="$H/bot/memory/bots/$ID"; mkdir -p "$M"; cp "$SRC"/memory/*.md "$M/"
echo "完成：新建机器人「${NAME}」，设定、记忆、话术都写好了。打开 DS Bot 就能看到。"
