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

- **要先装什么？** 不用。没装 DS Bot 的话，命令会自己从 DS Bot 官方 GitHub（Fei2411/DS-Bot）下载安装，并核对官方校验码。
- **命令做了什么**：把这个包下载到 `~/dsbot-chief-kit`（Windows 是 `%USERPROFILE%\dsbot-chief-kit`），再跑会更新覆盖；最后在屏幕上打印一段话。**它不会改 DS Bot 的任何数据文件。**
- **然后只做一件事**：打开 DS Bot，把打印出来的那段话整段复制，发给主机器人。主机器人会用 DS Bot 自带的建机器人功能新建 Chief（重名就叫 Chief-2、Chief-3），再让新 Chief 把记忆存好，最后回你一句。那段话也存在 `dsbot-chief-kit/PASTE_TO_CHIEF.txt` 里。
- **刚装好 DS Bot 的话**：先打开它走完第一次设置，**登录你自己的 DeepSeek 账号或填你自己的 API key**，再把那段话发给主机器人。不用再跑命令。
- 本包不带任何密钥和账号，模型用你自己 DS Bot 里配好的。原来的机器人不动。
- Mac 第一次打开 DS Bot 被拦：系统设置 → 隐私与安全性 → 仍要打开。

这是阿杰教给 DS Bot 里 Chief 的东西：Chief 的设定（写话术的规矩）、两份长期记忆、三课教材和考题。


## 说明
- 为什么不直接写进 DS Bot：DS Bot 没有官方导入功能，从外面改它的内部文件建出来的机器人会点不进去，所以改成让主机器人自己建。
- `docs/` 里有 Chief 设定的 md 版、测试题库、硬件成本参考（2026-11 价，仅供估算）。
- `lessons/` 是教材，换别的 AI 也能直接喂给它用。
