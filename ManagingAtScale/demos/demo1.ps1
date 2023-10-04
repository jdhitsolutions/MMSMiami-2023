return 'This is a demo script file.'

#region Arrays vs collections

$p = Get-Process
$p.Count
$p is [array]
$p | sort WorkingSet -Descending | select -First 5
#There are limitations to working with arrays

#collections
$list = [System.Collections.Generic.List[string]]::New()
$list.Add('Hello')
$list.count
$list.PSBase
$list.PSBase | Get-Member
$list.GetType().FullName
Get-Process | select -ExpandProperty Name -Unique | ForEach-Object {
    $list.Add($_)
}
$list.Contains('pwsh')
$list.Remove('pwsh')
$i = $list.FindIndex({ $args -eq 'Code' })
$list[$i]

Measure-Command {
    $a = @()
    1..500 | ForEach-Object {
        $a += Get-Process
    }
}
$a.count
Measure-Command {
    $b = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
    1..500 | ForEach-Object {
        $b.AddRange([System.Diagnostics.process[]]$(Get-Process))
    }
}
$b.count

#endregion
#region Filtering comparisons

#late filtering
Get-Process | Where-Object { $_.WS -ge 100MB }
Get-Service | where Status -EQ 'running'

#don't do this
Get-Process | Where-Object { $_.Name -like 'P*' } | Where-Object { $_.WS -ge 100MB }

#early filtering
Get-Command Get-Process -Syntax
Get-Process -Name P* | Where-Object { $_.WS -ge 100MB }

#important with CIM
#no
Get-CimInstance -ClassName Win32_Service | where { $_.StartName -like '*local*' } |
Select-Object Name, StartName, State

Get-CimInstance -ClassName Win32_Service -Filter "StartName like '%local%'" |
Select-Object Name, StartName, State

#test in separate sessions to negate any caching effect
Measure-Command {
    $a = Get-CimInstance -ClassName Win32_Service -ComputerName dom1, srv1, srv2, dom2, $env:Computername |
    where { $_.StartName -like '*local*' } |
    Select-Object Name, StartName, State, PSComputername
}

Measure-Command {
    $b = Get-CimInstance -ClassName Win32_Service -Filter "StartName like '%local%'" -ComputerName dom1, srv1, srv2, dom2, $env:Computername |
    Select-Object Name, StartName, State, PSComputername
}

#hybrid filtering as needed
Get-Process -Name P* | Where-Object { $_.WS -ge 5 } | Select-Object ID, Name, WS

Get-ChildItem c:\scripts\*.ps1 |
Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) -AND $_.Name -notmatch '^dev' } |
Sort-Object LastWriteTime -Descending
#Why is sorting last?

#decide where it makes the most sense to filter
Get-CimInstance win32_NTEventLogFile -Filter "LogFileName='Security'" -ComputerName dom1, dom2, srv1, srv2 |
Select-Object @{Name = 'ComputerName'; Expression = { $_.CSName } },
LogFileName, FileSize, MaxFileSize, NumberOfRecords,
@{Name = 'PctUsed'; Expression = { ($_.FileSize / $_.MaxFileSize) * 100 } } |
Where-Object { $_.PctUsed -ge 80 }
#984ms

#using remoting may not be faster
$cred = Get-Credential Company\artd
Invoke-Command -ScriptBlock {
    Get-CimInstance win32_NTEventLogFile -Filter "LogFileName='Security'" |
    Where-Object { ($_.FileSize / $_.MaxFileSize) * 100 -ge 80 } |
    Select-Object @{Name = 'ComputerName'; Expression = { $_.CSName } },
    LogFileName, FileSize, MaxFileSize, NumberOfRecords,
    @{Name = 'PctUsed'; Expression = { ($_.FileSize / $_.MaxFileSize) * 100 } }
} -ComputerName dom1, dom2, srv1, srv2 -Credential $cred -HideComputerName |
Select-Object -Property * -ExcludeProperty RunspaceID

$pssess = New-PSSession -ComputerName dom1, dom2, srv1, srv2 -Credential $cred
Invoke-Command -ScriptBlock {
    Get-CimInstance win32_NTEventLogFile -Filter "LogFileName='Security'" |
    Where-Object { ($_.FileSize / $_.MaxFileSize) * 100 -ge 80 } |
    Select-Object @{Name = 'ComputerName'; Expression = { $_.CSName } },
    LogFileName, FileSize, MaxFileSize, NumberOfRecords,
    @{Name = 'PctUsed'; Expression = { ($_.FileSize / $_.MaxFileSize) * 100 } }
} -Session $pssess -HideComputerName |
Select-Object -Property * -ExcludeProperty RunspaceID

#a variation
Invoke-Command -ScriptBlock {
    $log = Get-CimInstance win32_NTEventLogFile -Filter "LogFileName='Security'"
    if (($log.FileSize / $log.MaxFileSize)*100 -ge 80) {
        $log | Select-Object @{Name = 'ComputerName'; Expression = { $_.CSName } },
        LogFileName, FileSize, MaxFileSize, NumberOfRecords,
        @{Name = 'PctUsed'; Expression = { ($_.FileSize / $_.MaxFileSize) * 100 } }
    }
} -session $pssess -HideComputerName |
Select-Object -Property * -ExcludeProperty RunspaceID

Remove-PSSession $pssess
#endregion
#region Scaling with jobs

#background jobs

#thread jobs
#Install-Module ThreadJobs

#endregion

#region ForEach -parallel

#Sequential


#endregion
#region PipelineVariable vs OutVariable


#endregion
#region Leveraging Remoting


#endregion

