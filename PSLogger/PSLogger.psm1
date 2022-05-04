
function Set-LogSetting {
    <#
    .SYNOPSIS
        PSLoggerの設定項目を設定する。
    .DESCRIPTION
        PSLoggerの設定項目を設定する。
    .EXAMPLE
        PS C:\> Set-LogSetting -Property LogLevel -Value Info
    .NOTES
        デバッグ情報を出力する時は
        $DebugPreference = "Continue"
        とすること
    #>
    [CmdletBinding()]
    param (
        # 設定項目
        [Parameter(Mandatory)]
        [ValidateSet('LogLevel', 'Delimiter', 'DateTimeFormat', 'FilePath', IgnoreCase = $true)]
        $Property,
        # 設定値
        [Parameter(Mandatory)]
        [string]
        $Value
    )

    # 設定項目の対象外の値をチェックする
    if ($Property -in $Script:ValidSetPropertiesSetting.Keys `
            -and $Value -notin $Script:ValidSetPropertiesSetting[$Property]) {
        throw [System.ArgumentException](
            "$Value is not  valid value for '$Property'." +
            " Valid values are [$($Script:ValidSetPropertiesSetting[$Property] -join ',')]."
        )
    }
    Set-Variable -Name $Property -Value $Value -Scope Script
}

function Write-Log {
    <#
    .SYNOPSIS
        ログの書き込み
    .DESCRIPTION
        ログを書き込む。対象は引数もしくは Set-LogSetting で設定すること。
    .EXAMPLE
        PS C:\> Write-Log -Message "log message" -LogLevel Info
    .INPUTS
        メッセージ文字列

    .NOTES
        General notes
    #>
    [CmdletBinding()]
    param (
        # ログ内容
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Message,
        # ログ種別。デフォルト値をオーバーライドする場合に設定する。
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Fatal', IgnoreCase = $true)]
        $LogLevel = $Script:LogLevel,
        # 日時フォーマット。デフォルト値をオーバーライドする場合に設定する。
        [Parameter()]
        [string]
        $DateTimeFormat = $Script:DateTimeFormat,
        # 区切り文字。デフォルト値をオーバーライドする場合に設定する。
        [Parameter()]
        [string]
        $Delimiter = $Script:Delimiter,
        # ファイル名。デフォルト値をオーバーライドする場合に設定する。
        [Parameter()]
        [string]
        $FilePath = $Script:FilePath
    )

    begin {
        Write-Verbose ('{0} START' -f $MyInvocation.MyCommand)
        $datetimeText = Get-Date -Format $DateTimeFormat
        Write-Verbose ('パラメーター:' + @(
                "Message = '$Message'",
                "LogLevel = '$LogLevel'",
                "DateTimeFormat = '$DateTimeFormat'",
                "Delimiter = '$Delimiter'",
                "FilePath = '$FilePath'") -join ',')
    }

    process {
        $message = (@($datetimeText, $LogLevel, $Message) -join $Delimiter)
        Write-Verbose ('Write message "{0}"' -f $message)
        Write-Host -Object $message -ForegroundColor $Script:HostLogForegroundColor[$LogLevel]
        if ($FilePath) {
            Write-Verbose ('Write file "{0}"' -f $FilePath)
            Add-Content -Path $FilePath -Value $message -Encoding UTF8
        }
    }

    end {
        Write-Verbose ('{0} END' -f $MyInvocation.MyCommand)
    }
}

# デフォルト値(Get-Commandが必要なので関数定義のあとに初期化する必要がある)
[Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]$Script:LogEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]'Default'
[string]$Script:FilePath = ''
[string]$Script:Delimiter = ','
[string]$Script:DateTimeFormat = 'yyyy/MM/dd HH:mm:ss.fffffff'
[string]$Script:LogLevel = 'Info'
[hashtable]$Script:ValidSetPropertiesSetting = @{}
(Get-Command -Name Write-Log).Parameters.Values `
| Where-Object { $_.Attributes.ValidValues } `
| ForEach-Object { $Script:ValidSetPropertiesSetting[$_.Name] = $_.Attributes.ValidValues }
[hashtable]$Script:HostLogForegroundColor = @{
    'Info'    = [System.ConsoleColor]::Green;
    'Warning' = [System.ConsoleColor]::Yellow;
    'Error'   = [System.ConsoleColor]::Red;
    'Fatal'   = [System.ConsoleColor]::DarkRed;
}

# デバッグログ
Write-Debug ('$Script:LogEncoding = "{0}"' -f $Script:LogEncoding)
Write-Debug ('$Script:FilePath = "{0}"' -f $Script:FilePath)
Write-Debug ('$Script:Delimiter = "{0}"' -f $Script:Delimiter)
Write-Debug ('$Script:LogLevel = "{0}"' -f $Script:LogLevel)
Write-Debug ('$Script:DateTimeFormat = "{0}"' -f $Script:DateTimeFormat)
Write-Debug (
    '$Script:ValidSetPropertiesSetting = @{{{0}}}' `
        -f (($Script:ValidSetPropertiesSetting.Keys `
            | ForEach-Object { '"{0}"=@({1})' -f $_, ($Script:ValidSetPropertiesSetting[$_] -join ',') }) -join ';'))
Write-Debug (
    '$Script:HostLogForegroundColor = @{{{0}}}' `
        -f (($Script:HostLogForegroundColor.Keys `
            | ForEach-Object { '"{0}"={1}' -f $_, $Script:HostLogForegroundColor[$_] }) -join ';'))
