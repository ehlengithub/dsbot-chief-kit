# 一键（Windows）：irm https://raw.githubusercontent.com/ehlengithub/dsbot-chief-kit/main/install.ps1 | iex
# 没装 DS Bot 就从官方 GitHub Releases（Fei2411/DS-Bot）下载并静默安装；装了就新建 Chief。不带任何密钥。
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Rel = 'https://github.com/Fei2411/DS-Bot/releases/latest/download'
$Page = 'https://dsbot.app/ （或 https://github.com/Fei2411/DS-Bot/releases）'
$FirstRun = "下一步：`n  1) 打开 DS Bot，走完第一次设置，登录你自己的 DeepSeek 账号或填你自己的 API key；`n  2) 看到默认机器人后完全退出 DS Bot；`n  3) 再运行一次同一条命令，就会装上 Chief。"
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
  Write-Host "DS Bot 已安装。$FirstRun"; return
}
function Find-Data {
  if ($env:DSBOT_HOME) { return $env:DSBOT_HOME }
  foreach ($n in 'DS Bot','DeepSeek Bot') {
    $L = Join-Path $env:APPDATA "$n\locations.json"
    if (Test-Path $L) { try { return (Get-Content $L -Raw | ConvertFrom-Json).dataDir } catch {} }
  }
  return (Join-Path $env:USERPROFILE '.ds-bot')
}
$H = Find-Data; $S = Join-Path $H 'bot\state.json'
if (-not (Test-Path $S)) { Write-Host "DS Bot 已安装，但还没完成第一次设置（没找到 $S）。"; Write-Host $FirstRun; return }
if (-not $env:DSBOT_SKIP_RUNCHECK -and (Get-Process | Where-Object { $_.ProcessName -match '^(DS ?Bot|DeepSeek ?Bot|dsbot)' })) {
  Write-Host 'DS Bot 正在运行，请先完全退出，再运行一次这条命令'; exit 1 }
$K = Join-Path $env:TEMP ("chiefkit-" + [guid]::NewGuid()); New-Item -ItemType Directory $K | Out-Null
Invoke-WebRequest 'https://codeload.github.com/ehlengithub/dsbot-chief-kit/zip/refs/heads/main' -OutFile "$K\kit.zip" -UseBasicParsing
Expand-Archive "$K\kit.zip" $K; $Kit = (Get-ChildItem $K -Directory | Select-Object -First 1).FullName
$Bak = "$S.bak.$(Get-Date -Format yyyyMMddHHmmss).$PID"; Copy-Item $S $Bak; Write-Host "已备份：$Bak"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$d = [IO.File]::ReadAllText($S, $utf8) | ConvertFrom-Json
$c = [IO.File]::ReadAllText((Join-Path $Kit 'bot\chief.json'), $utf8) | ConvertFrom-Json
$names = @($d.bots.PSObject.Properties | ForEach-Object { $_.Value.name })
$name = $c.name; $n = 2
while ($names -contains $name) { $name = "$($c.name)-$n"; $n++ }
$sid = 'session-' + [guid]::NewGuid().ToString()
$model = $c.model
foreach ($i in @($d.mainBotIds)) { $b = $d.bots.$i; if ($b -and $b.model) { $model = $b.model; break } }
$bot = [ordered]@{ id=$sid; name=$name; role=$c.role; color=$c.color; avatar=$c.avatar; instructions=$c.instructions;
  createdAt=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); createdBy=$null; capabilities=@(); model=$model; appliedModel=$model }
$d.bots | Add-Member -NotePropertyName $sid -NotePropertyValue ([pscustomobject]$bot)
$d.revision = [int]$d.revision + 1
$tmp = "$S.tmp"; [IO.File]::WriteAllText($tmp, ($d | ConvertTo-Json -Depth 100), $utf8)
$null = [IO.File]::ReadAllText($tmp, $utf8) | ConvertFrom-Json
Move-Item -Force $tmp $S
$M = Join-Path $H "bot\memory\bots\$sid"; New-Item -ItemType Directory -Force $M | Out-Null
Copy-Item (Join-Path $Kit 'memory\*.md') $M
Write-Host "完成：新建机器人「$name」，设定、记忆、话术都写好了。打开 DS Bot 就能看到。"
