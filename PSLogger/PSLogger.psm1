
function Set-LogSetting {
    <#
    .SYNOPSIS
        PSLogger�̐ݒ荀�ڂ�ݒ肷��B
    .DESCRIPTION
        PSLogger�̐ݒ荀�ڂ�ݒ肷��B
    .EXAMPLE
        PS C:\> Set-LogSetting -Property LogLevel -Value Info
    .NOTES
        �f�o�b�O�����o�͂��鎞��
        $DebugPreference = "Continue"
        �Ƃ��邱��
    #>
    [CmdletBinding()]
    param (
        # �ݒ荀��
        [Parameter(Mandatory)]
        [ValidateSet('LogLevel', 'Delimiter', 'DateTimeFormat', 'FilePath', IgnoreCase = $true)]
        $Property,
        # �ݒ�l
        [Parameter(Mandatory)]
        [string]
        $Value
    )

    # �ݒ荀�ڂ̑ΏۊO�̒l���`�F�b�N����
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
        ���O�̏�������
    .DESCRIPTION
        ���O���������ށB�Ώۂ͈����������� Set-LogSetting �Őݒ肷�邱�ƁB
    .EXAMPLE
        PS C:\> Write-Log -Message "log message" -LogLevel Info
    .INPUTS
        ���b�Z�[�W������

    .NOTES
        General notes
    #>
    [CmdletBinding()]
    param (
        # ���O���e
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]
        $Message,
        # ���O��ʁB�f�t�H���g�l���I�[�o�[���C�h����ꍇ�ɐݒ肷��B
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Fatal', IgnoreCase = $true)]
        $LogLevel = $Script:LogLevel,
        # �����t�H�[�}�b�g�B�f�t�H���g�l���I�[�o�[���C�h����ꍇ�ɐݒ肷��B
        [Parameter()]
        [string]
        $DateTimeFormat = $Script:DateTimeFormat,
        # ��؂蕶���B�f�t�H���g�l���I�[�o�[���C�h����ꍇ�ɐݒ肷��B
        [Parameter()]
        [string]
        $Delimiter = $Script:Delimiter,
        # �t�@�C�����B�f�t�H���g�l���I�[�o�[���C�h����ꍇ�ɐݒ肷��B
        [Parameter()]
        [string]
        $FilePath = $Script:FilePath
    )

    begin {
        Write-Verbose ('{0} START' -f $MyInvocation.MyCommand)
        $datetimeText = Get-Date -Format $DateTimeFormat
        Write-Verbose ('�p�����[�^�[:' + @(
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

# �f�t�H���g�l(Get-Command���K�v�Ȃ̂Ŋ֐���`�̂��Ƃɏ���������K�v������)
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

# �f�o�b�O���O
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
