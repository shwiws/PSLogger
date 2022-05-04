BeforeAll {
    function IsDateTimeExact {
        param (
            [Parameter(Mandatory)]
            [string]
            $DateTimeText,
            [Parameter(Mandatory)]
            [string]
            $DateTimeFormat
        )
        [datetime]$parsedDate = [datetime]::MinValue
        [bool]$parseSuccess = [datetime]::TryParseExact(
            $DateTimeText,
            $DateTimeFormat,
            [Globalization.DateTimeFormatInfo]::CurrentInfo,
            [Globalization.DateTimeStyles]::AllowWhiteSpaces,
            [ref]$parsedDate
        )

        return $parseSuccess
    }

    $DebugPreference = 'SilentlyContinue'
    $VerbosePreference = 'SilentlyContinue'

    $ExpectDefaultDelimiter = ','
    $ExpectDefaultLogLevel = 'Info'
    $ExpectDefaultDateTimeFormat = 'yyyy/MM/dd HH:mm:ss.fffffff'
    $ExpectDefaultForegroundColor = 'Green'
}

Describe 'PSLogger' {
    Context 'Write-Log' {
        BeforeEach {
            # モジュールの再インポート
            $module = Get-ChildItem -Path $PSCommandPath.Replace('.Tests.ps1', '.psm1')
            $moduleName = $module.Directory.Name
            Write-Debug "テスト対象モジュール:$($module.FullName)"
            Get-Module $moduleName | Remove-Module
            Import-Module $module.FullName
            # モック
            Mock Write-Host {} -ModuleName $moduleName
            Mock Add-Content {} -ModuleName $moduleName
        }

        It 'Abnormal case. Not passing mandatory parameter.' {
            { Write-Log -Message ""} | Should -Throw
        }

        It 'Abnormal case. Invalid log level.' {
            { Write-Log -Message "" -LogLevel "None" } | Should -Throw
        }

        It 'Write-Log with default parameters.' {
            $expectMessage = 'Write-Log with default parameters'
            Write-Log -Message $expectMessage

            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Object -join ''
                $msgColumns = $message -split $ExpectDefaultDelimiter
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $ExpectDefaultDateTimeFormat) `
                    -and $msgColumns[1] -ceq $ExpectDefaultLogLevel `
                    -and $msgColumns[2] -ceq $expectMessage `
                    -and $ForegroundColor -ceq $ExpectDefaultForegroundColor
            }
        }

        It 'Write-Log with LogLevel' {
            $expectMessage = 'Write-Log with LogLevel'
            $expectLoglevel = 'Error'
            $expectForegroundColor = 'Red'

            Write-Log -Message $expectMessage -LogLevel $expectLoglevel
            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Object -join ''
                $msgColumns = $message -split $ExpectDefaultDelimiter
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $ExpectDefaultDateTimeFormat) `
                    -and $msgColumns[1] -ceq $expectLoglevel `
                    -and $msgColumns[2] -ceq $expectMessage `
                    -and $ForegroundColor -eq $expectForegroundColor
            }
        }

        It 'Write-Log with DateTimeFormat' {
            $expectMessage = 'Write-Log with DateTimeFormat'
            $expectDateTimeFormat = 'yyyy.MM.dd HH.mm.ss'
            Write-Log -Message $expectMessage -DateTimeFormat $expectDateTimeFormat

            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Object -join ''
                $msgColumns = $message -split $ExpectDefaultDelimiter
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $expectDateTimeFormat) `
                    -and $msgColumns[1] -ceq $ExpectDefaultLogLevel `
                    -and $msgColumns[2] -ceq $expectMessage `
                    -and $ForegroundColor -ceq $ExpectDefaultForegroundColor
            }
        }

        It 'Write-Log with Delimiter' {
            $expectMessage = 'Write-Log with Delimiter'
            $expectDelimiter = "`t"
            Write-Log -Message $expectMessage -Delimiter $expectDelimiter

            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Object -join ''
                $msgColumns = $message -split $expectDelimiter
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $ExpectDefaultDateTimeFormat) `
                    -and $msgColumns[1] -ceq $ExpectDefaultLogLevel `
                    -and $msgColumns[2] -ceq $expectMessage `
                    -and $ForegroundColor -ceq $ExpectDefaultForegroundColor
            }
        }

        It 'Write-Log with FilePath' {
            $expectMessage = 'Write-Log with FilePath'
            $expectFilePath = Join-Path $env:TEMP (New-Guid)
            Write-Log -Message $expectMessage -FilePath $expectFilePath

            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Object -join ''
                $msgColumns = $message -split $ExpectDefaultDelimiter
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $ExpectDefaultDateTimeFormat) `
                    -and $msgColumns[1] -ceq $ExpectDefaultLogLevel `
                    -and $msgColumns[2] -ceq $expectMessage `
                    -and $ForegroundColor -ceq $ExpectDefaultForegroundColor
            }
            Assert-MockCalled Add-Content -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Value -join ''
                $msgColumns = $message -split $ExpectDefaultDelimiter
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $ExpectDefaultDateTimeFormat) `
                    -and $msgColumns[1] -eq $ExpectDefaultLogLevel  `
                    -and $msgColumns[2] -ceq $expectMessage `
                    -and $Path -ceq $expectFilePath `
                    -and $Encoding -eq 'UTF8'
            }
        }

        $testCases = @(
            @{inMsg = 'case01'; inDelim = ';'; inLogLv = 'Info'; inDTFormat = 'yyyy/MM/dd'; inFilePath = 'test1.log'; expcColor = 'Green'; }
            @{inMsg = 'case02'; inDelim = ','; inLogLv = 'Warning'; inDTFormat = 'MM/dd'; inFilePath = 'test2.log'; expcColor = 'Yellow'; }
            @{inMsg = 'case03'; inDelim = '`t'; inLogLv = 'Error'; inDTFormat = 'MM/dd HH:mm'; inFilePath = 'test3.log'; expcColor = 'Red'; }
            @{inMsg = 'case04'; inDelim = "`t"; inLogLv = 'Fatal'; inDTFormat = 'HH:mm'; inFilePath = 'test4.log'; expcColor = 'DarkRed'; }
        )
        It 'Write-Log with all parameters' -TestCases $testCases {
            param($inMsg, $inDelim, $inLogLv, $inDTFormat, $inFilePath, $expcColor)

            Write-Log -Message $inMsg -LogLevel $inLogLv -Delimiter $inDelim `
                -DateTimeFormat $inDTFormat -FilePath $inFilePath

            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Object -join ''
                $msgColumns = $message -split $inDelim
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $inDTFormat) `
                    -and $msgColumns[1] -ceq $inLogLv `
                    -and $msgColumns[2] -ceq $inMsg `
                    -and $ForegroundColor -ceq $expcColor
            }

            Assert-MockCalled Add-Content -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Value -join ''
                $msgColumns = $message -split $inDelim
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $inDTFormat) `
                    -and $msgColumns[1] -eq $inLogLv  `
                    -and $msgColumns[2] -ceq $inMsg `
                    -and $Path -ceq $inFilePath `
                    -and $Encoding -eq 'UTF8'
            }
        }
    }

    Context "Set-LogSetting"{
        BeforeEach {
            # モジュールの再インポート
            $module = Get-ChildItem -Path $PSCommandPath.Replace('.Tests.ps1', '.psm1')
            $moduleName = $module.Directory.Name
            Write-Debug "テスト対象モジュール:$($module.FullName)"
            Get-Module $moduleName | Remove-Module
            Import-Module $module.FullName
            # モック
            Mock Write-Host {} -ModuleName $moduleName
            Mock Add-Content {} -ModuleName $moduleName
        }

        $testCases = @(
            @{inMsg = 'case01'; inDelim = ';'; inLogLv = 'Info'; inDTFormat = 'yyyy/MM/dd'; inFilePath = 'test1.log'; expcColor = 'Green'; }
            @{inMsg = 'case02'; inDelim = ','; inLogLv = 'Warning'; inDTFormat = 'MM/dd'; inFilePath = 'test2.log'; expcColor = 'Yellow'; }
            @{inMsg = 'case03'; inDelim = '`t'; inLogLv = 'Error'; inDTFormat = 'MM/dd HH:mm'; inFilePath = 'test3.log'; expcColor = 'Red'; }
            @{inMsg = 'case04'; inDelim = "`t"; inLogLv = 'Fatal'; inDTFormat = 'HH:mm'; inFilePath = 'test4.log'; expcColor = 'DarkRed'; }
        )

        It 'Set default parameters and call Write-Log with default parameters' -TestCases $testCases {
            param($inMsg, $inDelim, $inLogLv, $inDTFormat, $inFilePath, $expcColor)

            Set-LogSetting -Property Delimiter -Value $inDelim
            Set-LogSetting -Property LogLevel -Value $inLogLv
            Set-LogSetting -Property DateTimeFormat -Value $inDTFormat
            Set-LogSetting -Property FilePath -Value $inFilePath
            Write-Log -Message $inMsg

            Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Object -join ''
                $msgColumns = $message -split $inDelim
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $inDTFormat) `
                    -and $msgColumns[1] -ceq $inLogLv `
                    -and $msgColumns[2] -ceq $inMsg `
                    -and $ForegroundColor -ceq $expcColor
            }

            Assert-MockCalled Add-Content -Exactly 1 -Scope It -ModuleName $moduleName `
                -ParameterFilter {
                $message = $Value -join ''
                $msgColumns = $message -split $inDelim
                return $msgColumns.Count -eq 3 `
                    -and (IsDateTimeExact $msgColumns[0] $inDTFormat) `
                    -and $msgColumns[1] -eq $inLogLv  `
                    -and $msgColumns[2] -ceq $inMsg `
                    -and $Path -ceq $inFilePath `
                    -and $Encoding -eq 'UTF8'
            }
        }

    }
}
