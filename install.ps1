# Registers the "gclip" command in your PowerShell profile.
# gclip: copies the code block in clipboard.md (GeneralTools, clipboard branch) to the clipboard.
# Usage:  irm https://raw.githubusercontent.com/ToolShed47F/GeneralTools/clipboard/install.ps1 | iex
# Re-running replaces the existing gclip block. Set $env:GH_TOKEN to raise the API rate limit.

$begin = '# >>> gclip >>>'
$end   = '# <<< gclip <<<'
$block = @'
# >>> gclip >>>
function gclip {
    $url = 'https://api.github.com/repos/ToolShed47F/GeneralTools/contents/clipboard.md?ref=clipboard'
    $h = @{ Accept = 'application/vnd.github.raw'; 'User-Agent' = 'gclip' }
    if ($env:GH_TOKEN) { $h.Authorization = "Bearer $env:GH_TOKEN" }
    try {
        $r = Invoke-WebRequest -UseBasicParsing -Uri $url -Headers $h
    } catch {
        Write-Error "gclip: fetch failed: $($_.Exception.Message)"; return
    }
    $text = [Text.Encoding]::UTF8.GetString($r.RawContentStream.ToArray())
    $parts = $text -split '```'
    if ($parts.Count -lt 3) { Write-Error 'gclip: no code block found'; return }
    $v = $parts[1].Trim()
    Set-Clipboard -Value $v
    Write-Host "copied: $v"
}
# <<< gclip <<<
'@

$dir = Split-Path -Parent $PROFILE
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$current = ''
if (Test-Path $PROFILE) { $current = [IO.File]::ReadAllText($PROFILE) }

$pattern = '(?s)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end) + '\r?\n?'
$current = [regex]::Replace($current, $pattern, '')
if ($current.Length -gt 0 -and -not $current.EndsWith("`n")) { $current += "`r`n" }
$current += ($block -replace "`r?`n", "`r`n") + "`r`n"
[IO.File]::WriteAllText($PROFILE, $current, (New-Object Text.UTF8Encoding($true)))

Invoke-Expression $block
Write-Host "gclip registered in $PROFILE"
Write-Host "If new windows say scripts are disabled, run once:  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
