# Windows 版：在 DS Bot 里新建一个 Chief 机器人。用法：powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'
$Kit = Split-Path -Parent $MyInvocation.MyCommand.Path
$H = if ($env:DSBOT_HOME) { $env:DSBOT_HOME } else { Join-Path $env:USERPROFILE '.ds-bot' }
$S = Join-Path $H 'bot\state.json'
if (-not (Test-Path $S)) { Write-Host "没找到 $S：请先打开一次 DS Bot 并填好密钥，然后完全退出"; exit 1 }
if (-not $env:DSBOT_SKIP_RUNCHECK -and (Get-Process | Where-Object { $_.ProcessName -match 'DS ?Bot|dsbot' })) {
  Write-Host 'DS Bot 正在运行，请先完全退出再运行'; exit 1 }
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
Write-Host "完成：新建机器人「$name」($sid)。打开 DS Bot 即可看到。"
