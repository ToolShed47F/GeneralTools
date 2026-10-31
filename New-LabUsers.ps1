<#
.SYNOPSIS
  CSVからActive Directoryユーザーを一括作成する練習用スクリプト

.DESCRIPTION
  1. CSVを読み込む
  2. 部署ごとのOU(フォルダのようなもの)がなければ作る
  3. 同じログオン名のユーザーがいなければ作成する(いればスキップ)
  4. 結果をログファイルに書き出す

.EXAMPLE
  # 試運転(実際には何も作らない)
  .\New-LabUsers.ps1 -CsvPath .\users.csv -WhatIf

  # 本番
  .\New-LabUsers.ps1 -CsvPath .\users.csv
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    # ユーザーを入れる親OUの名前
    [string]$BaseOU = 'LabUsers'
)

Import-Module ActiveDirectory

# ドメインの住所(DN)を取得 例: DC=lab,DC=local
$domain   = Get-ADDomain
$domainDN = $domain.DistinguishedName
$upnSuffix = $domain.DNSRoot   # 例: lab.local

# 初期パスワードは画面で入力(スクリプトに直書きしない)
$password = Read-Host -AsSecureString '初期パスワードを入力'

# 親OUがなければ作る
$baseDN = "OU=$BaseOU,$domainDN"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$baseDN'")) {
    if ($PSCmdlet.ShouldProcess($baseDN, 'OU作成')) {
        New-ADOrganizationalUnit -Name $BaseOU -Path $domainDN
    }
}

$users   = Import-Csv -Path $CsvPath -Encoding UTF8
$results = @()

foreach ($u in $users) {
    $sam    = $u.SamAccountName
    $deptDN = "OU=$($u.Department),$baseDN"

    # 部署OUがなければ作る
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$deptDN'")) {
        if ($PSCmdlet.ShouldProcess($deptDN, 'OU作成')) {
            New-ADOrganizationalUnit -Name $u.Department -Path $baseDN
        }
    }

    # 既にいるならスキップ
    if (Get-ADUser -Filter "SamAccountName -eq '$sam'") {
        Write-Host "[SKIP] $sam は既に存在します" -ForegroundColor Yellow
        $results += [pscustomobject]@{ SamAccountName = $sam; Result = 'Skip(既存)' }
        continue
    }

    $params = @{
        Name                  = "$($u.Sei) $($u.Mei)"
        Surname               = $u.Sei
        GivenName             = $u.Mei
        DisplayName           = "$($u.Sei) $($u.Mei)"
        SamAccountName        = $sam
        UserPrincipalName     = "$sam@$upnSuffix"
        Department            = $u.Department
        Title                 = $u.Title
        Path                  = $deptDN
        AccountPassword       = $password
        ChangePasswordAtLogon = $true
        Enabled               = $true
    }

    try {
        if ($PSCmdlet.ShouldProcess($sam, 'ユーザー作成')) {
            New-ADUser @params -ErrorAction Stop
            Write-Host "[OK]   $sam を作成しました" -ForegroundColor Green
            $results += [pscustomobject]@{ SamAccountName = $sam; Result = 'Created' }
        }
    }
    catch {
        Write-Host "[NG]   $sam : $($_.Exception.Message)" -ForegroundColor Red
        $results += [pscustomobject]@{ SamAccountName = $sam; Result = "Error: $($_.Exception.Message)" }
    }
}

# 結果をログに残す(-WhatIf のときは残さない)
if (-not $WhatIfPreference) {
    $log = Join-Path $PSScriptRoot ("result_{0:yyyyMMdd_HHmmss}.csv" -f (Get-Date))
    $results | Export-Csv -Path $log -NoTypeInformation -Encoding UTF8
    Write-Host "結果ログ: $log"
}
