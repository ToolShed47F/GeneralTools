# New-LabUsers.ps1

CSVの名簿からActive Directoryユーザーを一括作成するPowerShellスクリプトです。
新入社員のアカウント作成など、管理画面で1人ずつ行う作業を自動化することを想定しています。

## できること

- CSVを読み込み、1行ごとにADユーザーを作成
- 部署ごとのOUがなければ自動作成し、ユーザーをその中に配置
- 同じログオン名のユーザーが既にいれば作成せずスキップ(二重登録防止)
- 初期パスワードは実行時に入力(スクリプトに書かない)、初回ログオン時に変更を強制
- `-WhatIf` で、実際には何も変更せずに実行内容だけを確認できる
- 実行結果(作成/スキップ/エラー)をCSVログに保存

## 動作確認環境

- Windows Server 2025(ドメインコントローラー、検証用ドメイン lab.local)
- Windows PowerShell 5.1
- ActiveDirectory モジュール

## CSVの形式

```csv
SamAccountName,Sei,Mei,Department,Title
tanaka.taro,田中,太郎,総務部,主任
```

| 列 | 内容 |
|---|---|
| SamAccountName | ログオン名 |
| Sei / Mei | 姓 / 名 |
| Department | 部署(OU名にも使用) |
| Title | 役職 |

文字コードは UTF-8(BOM付き)で保存してください。

## 使い方

```powershell
# 1. 試運転(何も変更しない)
.\New-LabUsers.ps1 -CsvPath .\users.csv -WhatIf

# 2. 本番実行
.\New-LabUsers.ps1 -CsvPath .\users.csv
```

ユーザーは `OU=<部署>,OU=LabUsers,<ドメイン>` に作成されます。親OUの名前は `-BaseOU` で変更できます。

## 実行例

```
[OK]   tanaka.taro を作成しました
[OK]   suzuki.hanako を作成しました
[OK]   sato.ichiro を作成しました
[OK]   takahashi.yui を作成しました
[OK]   ito.kenta を作成しました
結果ログ: C:\lab\result_20261031_144431.csv
```

## 注意

検証環境での利用を想定しています。本番環境で使う場合は、必ず `-WhatIf` で内容を確認してから実行してください。
