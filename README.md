# DS Bot Chief 接单话术包（私有）

这是阿杰教给 DS Bot 里 Chief 的东西：Chief 的设定（写话术的规矩）、两份长期记忆、三课教材和考题。

⚠️ 内容里有客户群名、聊天和价格，**这个仓库只能私有，不要公开、不要转发**。仓库里没有任何密钥。

## 安装（需要 DS Bot 0.2.7）

1. 先装好 DS Bot 0.2.7，打开一次，填上**自己的** DeepSeek 密钥，等 Chief 出现后**完全退出** DS Bot。
2. 在终端（macOS / Linux）运行：

```
git clone https://github.com/ehlengithub/dsbot-chief-kit.git && bash dsbot-chief-kit/install.sh
```

没装 git 的话，用一个能读这个仓库的 GitHub token（把 XXX 换掉）：

```
mkdir -p dsbot-chief-kit && curl -fsSL -H "Authorization: token XXX" https://api.github.com/repos/ehlengithub/dsbot-chief-kit/tarball | tar xz --strip-components=1 -C dsbot-chief-kit && bash dsbot-chief-kit/install.sh
```

3. 打开 DS Bot，Chief 就带着这些规矩和记忆了。

## 说明
- 脚本会把原来的 `state.json` 先备份成 `state.json.bak.时间`，再把主机器人的名字、设定、模型换成这里的；记忆文件拷进它的记忆文件夹。跑几遍都一样。
- 不碰密钥文件 `.credentials.yaml`。
- 数据目录默认 `~/.ds-bot`，别的位置用 `DSBOT_HOME=路径 bash install.sh`。
- Windows 暂时没有脚本：可以手动把 `bot/chief.json` 里的 `instructions` 贴进 Chief 的设定，把 `memory/` 两个文件拷到 `%USERPROFILE%\.ds-bot\bot\memory\bots\<Chief 的 id>\`（路径未实测）。
- `lessons/` 是教材，换别的 AI 也能直接喂给它用。
