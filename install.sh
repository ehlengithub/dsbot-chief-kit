#!/usr/bin/env bash
# 把 Chief 的设定和记忆导入 DS Bot 0.2.7。可重复运行。不碰密钥文件。
set -euo pipefail
KIT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
H="${DSBOT_HOME:-$HOME/.ds-bot}"
S="$H/bot/state.json"
command -v python3 >/dev/null || { echo "需要 python3"; exit 1; }
[ -f "$S" ] || { echo "没找到 $S：请先打开一次 DS Bot、填好密钥，等 Chief 出现后关掉，再运行本脚本"; exit 1; }
if [ -z "${DSBOT_SKIP_RUNCHECK:-}" ] && pgrep -f "DS Bot|dsbot" >/dev/null 2>&1; then echo "请先完全退出 DS Bot 再运行"; exit 1; fi
cp "$S" "$S.bak.$(date +%Y%m%d%H%M%S)"
ID=$(KIT="$KIT" S="$S" python3 - <<'P'
import json,os
s=os.environ['S'];d=json.load(open(s,encoding='utf-8'))
c=json.load(open(os.path.join(os.environ['KIT'],'bot','chief.json'),encoding='utf-8'))
bots=d.get('bots',{});ids=[i for i in d.get('mainBotIds',[]) if i in bots]
if not ids: ids=[i for i,b in bots.items() if b.get('name')==c['name']]
if not ids: raise SystemExit("state.json 里没有主机器人：请先打开一次 DS Bot")
b=bots[ids[0]]
for k in ['name','role','color','avatar','instructions','model']: b[k]=c[k]
d['revision']=int(d.get('revision',0))+1
tmp=s+'.tmp';json.dump(d,open(tmp,'w',encoding='utf-8'),ensure_ascii=False,indent=2);os.replace(tmp,s)
print(ids[0])
P
)
M="$H/bot/memory/bots/$ID"; mkdir -p "$M"; cp "$KIT"/memory/*.md "$M/"
echo "完成：Chief($ID) 的设定和记忆已导入。打开 DS Bot 即可。"
