#!/usr/bin/env bash
# 一键在 DS Bot 里新建一个 Chief 机器人（设定 + 记忆 + 话术）。
# 不动已有机器人；重名自动改成 Chief-2、Chief-3…；不碰任何密钥和模型配置文件。
set -euo pipefail
KIT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
H="${DSBOT_HOME:-$HOME/.ds-bot}"
S="$H/bot/state.json"
command -v python3 >/dev/null || { echo "需要 python3"; exit 1; }
[ -f "$S" ] || { echo "没找到 $S：请先打开一次 DS Bot 并填好你自己的密钥，然后完全退出再运行"; exit 1; }
if [ -z "${DSBOT_SKIP_RUNCHECK:-}" ] && pgrep -fi "DS Bot/|dsbot" >/dev/null 2>&1; then
  echo "DS Bot 正在运行，请先完全退出 DS Bot 再运行本脚本"; exit 1; fi
BAK="$S.bak.$(date +%Y%m%d%H%M%S).$$"; cp "$S" "$BAK"; echo "已备份：$BAK"
OUT=$(KIT="$KIT" S="$S" python3 - <<'P'
import json,os,uuid,time
s=os.environ['S'];kit=os.environ['KIT']
d=json.load(open(s,encoding='utf-8'))
c=json.load(open(os.path.join(kit,'bot','chief.json'),encoding='utf-8'))
bots=d.setdefault('bots',{})
names={b.get('name') for b in bots.values()}
name=c['name'];n=2
while name in names: name=f"{c['name']}-{n}";n+=1
sid='session-'+str(uuid.uuid4())
while sid in bots: sid='session-'+str(uuid.uuid4())
model=c['model']
for i in d.get('mainBotIds',[]):   # 跟用户主机器人用同一个模型，避免他没配我们的模型
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
M="$H/bot/memory/bots/$ID"; mkdir -p "$M"; cp "$KIT"/memory/*.md "$M/"
echo "完成：新建机器人「$NAME」($ID)，设定和记忆已写入。打开 DS Bot 即可看到。"
