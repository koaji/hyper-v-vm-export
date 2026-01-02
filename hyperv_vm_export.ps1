<#
MIT License

Copyright (c) 2026 koaji

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

function main($logFileDirecotry, $exportListFilePath) {
    $jobArray = @()
    $results = @()
    $oldExportDirList = @()

    $oldExportRemoveFlag = $true
  
    # 実行時ログファイル作成
    $executeTime = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFileName = "HyperV_VM_BackupLog_${executeTime}.log"
    $logFilePath = $logFileDirecotry + "/" + $logFileName
    Start-Transcript $logFilePath -Append

    Write-Output "=== Hyper-V VM Export Script Log ==="
    $sysInfo = systeminfo
    Write-Output $sysInfo

    # エクスポート対象リスト読み込み
    $exportList = Import-Csv -Path $exportListFilePath

    # レコード単位で実行  
    foreach ($record in $exportList) {
        $vmName = $record.VmName
        $exportPath = $record.ExportPath

        # 過去のバックアップを退避
        $oldExportPathDirName = (Get-Item -Path $exportPath).Name + ".old"
        Rename-Item -Path $exportPath -NewName $oldExportPathDirName
        $oldExportDirList += (Split-Path -Path $exportPath -Parent) + "\" + $oldExportPathDirName

        $job = Start-Job -scriptBlock {
            param($vmName, $exportPath)

            function Log-Message {
                param(
                    [string]$msg
                )
                $msg = "[" + (Get-Date).ToString("yyyy/MM/dd HH:mm:ss") + "] " + $msg
                $msg | Write-Output
            }

            $vmState = Get-VM | where {$_.Name -eq $vmName} | Out-String
            Log-Message "Starting export for VM: $vmName to $exportPath $vmState"
            
            # Export-VM 実行
            try {
                Export-VM -Name $vmName -Path $exportPath -ErrorAction Stop
                Log-Message "Successfully exported VM: $vmName"
            } catch {
                Log-Message "Error:$_"
                Log-Message "Failed to export VM: $vmName"
            }

        } -ArgumentList $vmName, $exportPath

        $jobArray += $job
    }

    # job監視
    foreach ($job in $jobArray) {
        Wait-Job -Job $job
        $result = Receive-Job -Job $job
        $result | Write-Output
        Remove-Job -Job $job

        if (($result | Out-String).Contains("Failed") ){
            # 一つでも失敗したとき、過去のバックアップは削除しない
            $oldExportRemoveFlag = ($oldExportRemoveFlag -and $false)
        }
    }

    if ($oldExportRemoveFlag){
        foreach ($dir in $oldExportDirList) {
            # 過去のバックアップを削除する
            Write-Output "Remove old data : $dir"
            Remove-Item -Path $dir -Recurse
        }
    } else {
        Write-Output "Skip remove old data."
    }

    Stop-Transcript
}

# エントリー
main $args[0] $args[1]
exit 0
