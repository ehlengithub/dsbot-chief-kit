# 一键（Windows）：irm https://raw.githubusercontent.com/ehlengithub/dsbot-chief-kit/main/install.ps1 | iex
# 没装 DS Bot 就从官方 GitHub Releases（Fei2411/DS-Bot）下载并静默安装；再把 Chief 包下载到 %USERPROFILE%\dsbot-chief-kit，打印一段话给主机器人。不改 DS Bot 任何数据文件，不带任何密钥。
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Rel = 'https://github.com/Fei2411/DS-Bot/releases/latest/download'
$Page = 'https://dsbot.app/ （或 https://github.com/Fei2411/DS-Bot/releases）'
$Fresh = $false
function Test-App {
  if ($env:DSBOT_ASSUME_NOT_INSTALLED) { return $false }
  $keys = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
  $hit = Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'DS Bot|DeepSeek Bot' }
  return [bool]$hit
}
if (-not (Test-App)) {
  $T = Join-Path $env:TEMP ("dsbot-" + [guid]::NewGuid()); New-Item -ItemType Directory $T | Out-Null
  $F = 'DS-Bot-win-x64.exe'; Write-Host "没找到 DS Bot，正在从官方 GitHub 下载 $F（约 290MB）…"
  $ProgressPreference = 'SilentlyContinue'
  Invoke-WebRequest "$Rel/$F" -OutFile "$T\$F" -UseBasicParsing
  Invoke-WebRequest "$Rel/SHA256SUMS.txt" -OutFile "$T\sums.txt" -UseBasicParsing
  $want = (Get-Content "$T\sums.txt" | Where-Object { $_ -match "\s$([regex]::Escape($F))$" } | Select-Object -First 1) -split '\s+' | Select-Object -First 1
  $got = (Get-FileHash "$T\$F" -Algorithm SHA256).Hash.ToLower()
  if (-not $want -or $want -ne $got) { Write-Host "安装包校验不通过，已停止。请到官方页面手动下载：$Page"; exit 1 }
  Write-Host '校验通过，正在静默安装（只装给当前用户，不需要管理员）…'
  Start-Process "$T\$F" -ArgumentList '/S' -Wait
  $Fresh = $true
}
$Kit = if ($env:DSBOT_KIT_DIR) { $env:DSBOT_KIT_DIR } else { Join-Path $env:USERPROFILE 'dsbot-chief-kit' }
$Zip = if ($env:DSBOT_KIT_ZIP) { $env:DSBOT_KIT_ZIP } else { 'https://codeload.github.com/ehlengithub/dsbot-chief-kit/zip/refs/heads/main' }
$K = Join-Path $env:TEMP ("chiefkit-" + [guid]::NewGuid()); New-Item -ItemType Directory $K | Out-Null
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest $Zip -OutFile "$K\kit.zip" -UseBasicParsing
Expand-Archive "$K\kit.zip" "$K\x"
$Src = (Get-ChildItem "$K\x" -Directory | Select-Object -First 1).FullName
if (-not (Test-Path (Join-Path $Src 'docs\chief_instructions.md'))) { Write-Host 'Chief 包下载不完整，已停止'; exit 1 }
if (Test-Path $Kit) { Remove-Item -Recurse -Force $Kit }
Move-Item $Src $Kit
Remove-Item -Recurse -Force $K
$Kit = (Resolve-Path $Kit).Path
$Ins = Join-Path $Kit 'docs\chief_instructions.md'
$M1 = Join-Path $Kit 'memory\MEMORY.md'
$M2 = Join-Path $Kit 'memory\接单话术.md'
$Msg = @"
请帮我新建一个机器人，按下面步骤做，别改你自己（主机器人）的设定：
1. 先用 list_bots 看看现在有哪些机器人。名字定为 Chief；如果已经有叫 Chief 的，就用 Chief-2，还被占用就 Chief-3，依次往后。
2. 用你的读文件工具读 $Ins 的全部内容（一个字都不要删改）。
3. 用 create_bot 新建这个机器人：name 用第 1 步定的名字，role 填「幕僚长」，instructions 填第 2 步读到的全文，brief 写「接单话术和报价助手」。模型不用指定。
4. 建好后用 message_bot 发给这个新机器人：「请用读文件工具读完 $M1 和 $M2 两个文件，把里面每一条规矩和事实用 remember 分条存进你自己的记忆（话术相关的 topic 填 接单话术），存完回我一句。」
5. 新机器人回复存好后，用一句话告诉我：新机器人叫什么名字，记忆存好了没有。
"@
[IO.File]::WriteAllText((Join-Path $Kit 'PASTE_TO_CHIEF.txt'), $Msg + "`r`n", (New-Object System.Text.UTF8Encoding($true)))
if ($Fresh) {
  Write-Host ''
  Write-Host 'DS Bot 已经装好。先做这两步：'
  Write-Host '  1) 打开 DS Bot，按提示走完第一次设置，登录你自己的 DeepSeek 账号或填你自己的 API key；'
  Write-Host '  2) 看到默认的主机器人以后，把下面这段话发给它。'
}
Write-Host ''
Write-Host "Chief 的文件已放到：$Kit"
Write-Host "打开 DS Bot，把下面虚线之间的整段话复制，发给主机器人（这段话也存在 $Kit\PASTE_TO_CHIEF.txt）："
Write-Host '------------------------------------------------------------'
Write-Host $Msg
Write-Host '------------------------------------------------------------'
