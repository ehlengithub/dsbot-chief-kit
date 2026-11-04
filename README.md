# DS Bot Chief 接单话术包

## 一条命令装好（大白话）

**Mac / Linux**：打开「终端」，粘贴回车：
```
curl -fsSL https://raw.githubusercontent.com/ehlengithub/dsbot-chief-kit/main/install.sh | bash
```
**Windows**：打开 PowerShell，粘贴回车：
```
irm https://raw.githubusercontent.com/ehlengithub/dsbot-chief-kit/main/install.ps1 | iex
```

- **要先装什么？** 不用。没装 DS Bot 的话，命令会自己从 DS Bot 官方 GitHub（Fei2411/DS-Bot）下载安装，并核对官方校验码。Mac/Linux 需要系统自带的 curl 和 python3（Mac 第一次可能提示装开发者工具，点安装就行）。
- **第一次（刚装好 DS Bot）**：打开 DS Bot，走完第一次设置，**登录你自己的 DeepSeek 账号或填你自己的 API key**，看到默认机器人后完全退出，然后**再运行一次同一条命令**。
- **已经在用 DS Bot**：先完全退出 DS Bot，运行命令，再打开就多了一个 Chief（重名会叫 Chief-2、Chief-3）。原来的机器人不动。
- 本包不带任何密钥和账号，模型用你自己 DS Bot 里配好的。
- Mac 第一次打开 DS Bot 被拦：系统设置 → 隐私与安全性 → 仍要打开。

这是阿杰教给 DS Bot 里 Chief 的东西：Chief 的设定（写话术的规矩）、两份长期记忆、三课教材和考题。


## 说明
- 脚本会**新建**一个机器人，不改你已有的机器人；写入前把 `state.json` 备份成 `state.json.bak.时间`。每跑一次就多一个。
- 新机器人用你主机器人当前的模型；不带任何密钥、账号或 DeepSeek 配置，也不碰 `.credentials.yaml`。
- DS Bot 正在运行时脚本会直接退出，先关掉再跑。
- 数据目录自动从 DS Bot 的 locations.json 读；也可以用 `DSBOT_HOME=路径` 指定。
- `docs/` 里有 Chief 设定的 md 版、测试题库、硬件成本参考（2026-11 价，仅供估算）。
- `lessons/` 是教材，换别的 AI 也能直接喂给它用。
