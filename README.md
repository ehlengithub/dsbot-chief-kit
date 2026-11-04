# DS Bot Chief 接单话术包（私有）

这是阿杰教给 DS Bot 里 Chief 的东西：Chief 的设定（写话术的规矩）、两份长期记忆、三课教材和考题。

⚠️ 内容里有客户群名、聊天和价格，**这个仓库只能私有，不要公开、不要转发**。仓库里没有任何密钥。

## 一键安装（已装 DS Bot 的电脑）
先完全退出 DS Bot，然后在终端运行这一行：

```
git clone https://github.com/ehlengithub/dsbot-chief-kit.git && bash dsbot-chief-kit/install.sh
```

Windows（PowerShell，未实测）：`git clone https://github.com/ehlengithub/dsbot-chief-kit.git; powershell -ExecutionPolicy Bypass -File dsbot-chief-kit\install.ps1`

装完打开 DS Bot，会多出一个叫 Chief 的机器人（已有同名的就叫 Chief-2、Chief-3……），设定、记忆和话术都带好了。

## 说明
- 脚本会**新建**一个机器人，不改你已有的机器人；写入前把 `state.json` 备份成 `state.json.bak.时间`。每跑一次就多一个。
- 新机器人用你主机器人当前的模型；不带任何密钥、账号或 DeepSeek 配置，也不碰 `.credentials.yaml`。
- DS Bot 正在运行时脚本会直接退出，先关掉再跑。
- 数据目录默认 `~/.ds-bot`，别的位置用 `DSBOT_HOME=路径 bash install.sh`。
- `docs/` 里有 Chief 设定的 md 版、测试题库、硬件成本参考（2026-11 价，仅供估算）。
- `lessons/` 是教材，换别的 AI 也能直接喂给它用。
