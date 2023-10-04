Return 'This is a demo script file'

#region pipeline paradigm

$Path = 'C:\Work'
Get-ChildItem -Path $Path -Directory -PipelineVariable pv |
ForEach-Object {
    Get-ChildItem -Path $_ -File -Recurse | Measure-Object -Property Length -Sum |
    Select-Object @{Name = 'Path'; Expression = { $pv.Name } }, Count, Sum
} | Sort-Object Sum -Descending |
ConvertTo-Html -Title 'Folder Report' -PreContent "<h1>Folder Report</h1><H2>Path: $path [$($env:ComputerName)]</H2>" -PostContent "<H5><I>Report Run $(Get-Date)</I></H5>" -Head "<style>$(Get-Content .\sample3.css)</style>" |
Out-File .\report.html

Get-Service bits, winrm | Restart-Service -PassThru
Get-Process | Stop-Process -WhatIf

Get-Process | Where-Object StartTime |
Sort-Object -Property StartTime |
Select-Object -Property ID, Name, StartTime,
@{Name = 'RunTime'; Expression = { $(Get-Date) - $_.StartTime } } -First 20

#endregion
#region pipeline binding
<#
This concept applies to how you might consume command output
as well as how you might want to structure your own commands.
#>

help Sort-Object -Parameter InputObject
help Get-ChildItem -Parameter Path
help Get-Counter -Parameter Counter

#Install-Module PSScriptTools
Get-ParameterInfo Get-Counter | select Name, Value*

#ByValue
'C:\Windows' | Get-ChildItem
1, 4, 6, 2, 77, 3, 5 | Sort-Object -Descending

#ByPropertyName
Get-Counter -ListSet Memory
Get-Counter -ListSet Memory | Get-Counter

#variation
'C:\work', $env:Temp, $HOME | Get-ChildItem -Directory -PipelineVariable pv |
ForEach-Object {
    $_ | Get-ChildItem -File -Recurse | Measure-Object -Property Length -Sum |
    Select-Object @{Name = 'Parent'; Expression = { $pv.Parent } },
    @{Name = 'Directory'; Expression = { $pv.Name } }, Count, Sum
} | Where-Object { $_.Sum -ge 500 } | Sort-Object Parent, Sum |
Format-Table -GroupBy Parent -Property Directory, Count,
@{Name = 'SumKB'; Expression = { [math]::Round($_.Sum / 1KB, 4) } }

# !! READ THE HELP !!

#endregion
#region syntax review

#splatting
Get-WinEvent -LogName System -MaxEvents 10 -ComputerName $env:ComputerName

$paramHash = @{
    LogName      = 'System'
    MaxEvents    = 10
    ComputerName = $env:ComputerName
}

Get-WinEvent @paramHash

$paramHash.LogName = "Application"
Get-WinEvent @paramHash

psedit .\Get-OSInformation.ps1
. .\Get-OSInformation.ps1
Get-OSInformation -verbose
"dom1","win10","localhost","foo","srv1" | Get-OsInformation

psedit .\Get-OS.ps1
. .\Get-OS.ps1
Get-OS -verbose

#endregion

#region console to code
psedit .\console-first.ps1
psedit .\basic-script.ps1
psedit .\basic-function.ps1
psedit .\advance-function.ps1
psedit .\advance-function2.ps1
psedit .\advance-function3.ps1
psedit .\advance-function4.ps1
psedit .\advance-function5.ps1

#endregion

#region patterns across technologies

#copy and paste this demo into the Win10 VM
$pass = ConvertTo-SecureString -AsPlainText -Force -String P@ssw0rd
$new = Get-Content c:\scripts\newusers.json | ConvertFrom-JSON
$new | New-ADUser -Enabled $True -PassThru -AccountPassword $pass -ChangePasswordAtLogon $True -WhatIf

#reset demo
# $new | foreach { Remove-ADuser -Identity $_.samaccountname -confirm:$false}

Get-VM -PipelineVariable pv | Get-VMHardDiskDrive | Get-VHD |
Select-Object -property  Computername,@{Name="VMName";Expression={$pv.VMName}},Path,VHDType,
@{Name="SizeGB";Expression={$_.Size/1GB -AS [int32]}},
@{Name="FileSizeGB";Expression={[math]::Round($_.FileSize/1GB,2)}} |
Export-CSV .\vmdisks.csv -NoTypeInformation

Import-CSV .\vmdisks.csv

Import-CSV .\vmdisks.csv | Group-Object -Property VMName |
ForEach-Object -Begin {
    $fragments =  @("<H1>VM Disk Report</H1>")
    $fragments += "<H2>$($ENV:Computername)</H2>"
    $head = @"
    <Title>VMDisk Report</Title>
    <style>
    $(Get-Content .\sample3.css)
    </style
"@
} -process {
    $fragments += "<H3>VM: $($_.Name)</H3>"
    $fragments += $_.Group | Select-Object -property VHDType,Path,SizeGB,FileSizeGB |
    ConvertTo-HTML -Fragment
} -end {
    $fragments += "<H5><I>Report Run $(Get-Date)<I></H5>"
    ConvertTo-HTML -body $Fragments -head $head
} | Out-File .\vmdiskreport.html

Invoke-Item .\vmdiskreport.html

#endregion

#region modules

#debating how much to cover here

#endregion
