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
    if (($log.FileSize / $log.MaxFileSize) * 100 -ge 80) {
        $log | Select-Object @{Name = 'ComputerName'; Expression = { $_.CSName } },
        LogFileName, FileSize, MaxFileSize, NumberOfRecords,
        @{Name = 'PctUsed'; Expression = { ($_.FileSize / $_.MaxFileSize) * 100 } }
    }
} -Session $pssess -HideComputerName |
Select-Object -Property * -ExcludeProperty RunspaceID

Remove-PSSession $pssess
#endregion
#region Scaling with jobs


#sequential
Function Get-FolderReport {
    [cmdletbinding()]
    [OutputType('folderReport')]
    [alias('gfp')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the top-level folder'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path = '.'
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"

    } #begin

    Process {
        $cPath = Convert-Path $Path
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $cPath "
        #ignore errors like Access Denied
        $stats = Get-ChildItem -Path $cPath -File -Recurse -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum -Average
        [PSCustomObject]@{
            PSTypeName  = 'folderReport'
            Path        = $cPath
            FileCount   = $stats.Count
            TotalSize   = $stats.Sum
            AverageSize = $stats.Average
        }
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FolderReport

<#
"c:\work","c:\windows","c:\scripts",$home | Get-FolderReport
50 seconds

#>
#background jobs

Function Get-FolderReport {
    [cmdletbinding()]
    [OutputType('folderReport')]
    [alias('gfp')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the top-level folder'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path = '.'
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        $jobs = @()
    } #begin

    Process {
        $cPath = Convert-Path $Path
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Starting background job for $cPath"
        #ignore errors like Access Denied
        -ArgumentList $cPath
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Waiting for $($jobs.count) jobs to complete"
        $Jobs | Wait-Job | Receive-Job -Keep
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FolderReport

#20 seconds
# Data can remain in background jobs if you want it

#thread jobs
#Install-Module ThreadJobs
#use the current thread
#pass output to the host
#inherits current location
#can throttle
Function Get-FolderReport {
    [cmdletbinding()]
    [OutputType('folderReport')]
    [alias('gfp')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the top-level folder'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path = '.'
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        $jobs = @()
    } #begin

    Process {
        $cPath = Convert-Path $Path
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Starting thread job for $cPath"
        #ignore errors like Access Denied
        -ArgumentList $cPath -StreamingHost $Host
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Waiting for $($jobs.count) jobs to complete"
        $Jobs | Wait-Job | Receive-Job -Keep
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FolderReport

# "c:\work","c:\windows","c:\scripts",$home | Get-FolderReport -Verbose
#21 seconds
#endregion

#region ForEach -parallel

#Sequential
Measure-Command {
    $r = 'c:\work', 'c:\windows', 'C:\temp', $home |
    ForEach-Object {
        $p = Convert-Path $_
        $start = Get-Date
        Write-Host "[$((Get-Date).TimeOfDay)] Analyzing $p" -ForegroundColor green
        Get-ChildItem -Path $p -File -Recurse -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum -Average |
        Select-Object @{Name = 'Path'; Expression = { $p } }, Count, Sum, Average

        Write-Host "[$((Get-Date).TimeOfDay)] Ending $p -> $(New-TimeSpan -Start $start -End (Get-Date))" -ForegroundColor yellow
    }
}
#27ms

#parallel - consider the overhead
Measure-Command {
    $r = 'c:\work', 'c:\windows', 'C:\temp', $home |
    ForEach-Object -Parallel {
        $p = Convert-Path $_
        $start = Get-Date
        Write-Host "[$((Get-Date).TimeOfDay)] Analyzing $p" -ForegroundColor green

        Get-ChildItem -Path $p -File -Recurse -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum -Average |
        Select-Object @{Name = 'Path'; Expression = { $p } }, Count, Sum, Average
        Write-Host "[$((Get-Date).TimeOfDay)] Ending $p -> $(New-TimeSpan -Start $start -End (Get-Date))" -ForegroundColor yellow
    }
}
#21 ms

#endregion
#region PipelineVariable vs  OutVariable vs Tee-Object

#outvariable
Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 2 } -MaxEvents 1000 -OutVariable errLog |
Group-Object -Property ProviderName -OutVariable go

$errLog[0..10]
$go[-1].Group

#Tee-Object
Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 2 } -MaxEvents 1000 -OutVariable errLog |
Group-Object -Property ProviderName -OutVariable go | Tee-Object -Variable r

$r

#pipelinevariable

Get-ChildItem c:\work -File -PipelineVariable source | Copy-Item -Destination c:\temp -PassThru -PipelineVariable dest |
ForEach-Object {
    $msg = "[$(Get-Date)] Copied {0} from {1} to {2}" -f $source.Name, $source.DirectoryName, $dest.DirectoryName
    Write-Host $msg -ForegroundColor Yellow
}

#putting it all together
#this is not the only way or even the best way to do this
Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 2, 3, 4 } -MaxEvents 1000 -OutVariable sysLog -PipelineVariable get |
Group-Object -Property ProviderName -OutVariable go -PipelineVariable group | Tee-Object -Variable t |
select @{Name = 'LogName'; Expression = { $get.logname } },
Name,
@{Name = 'TotalCount'; Expression = { $_.Count } },
@{Name = 'TotalPct'; Expression = { ($_.Count / ($t | measure count -Sum).sum) * 100 } },
@{Name = 'ErrCount'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Error' }).Count } },
@{Name = 'ErrPct'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Error' }).Count / $group.Count * 100 } },
@{Name = 'WarnCount'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Warning' }).Count } },
@{Name = 'WarnPct'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Warning' }).Count / $group.Count * 100 } },
@{Name = 'InfoCount'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Information' }).Count } },
@{Name = 'InfoPct'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Information' }).Count / $group.Count * 100 } }


#endregion
#region Leveraging Remoting

$computers = 'dom1', 'dom2', 'srv1', 'srv2'
#This assumes there will be no errors connecting to the computer
Measure-command {
    $r = foreach ($c in $computers) {
        Write-Host "[$((Get-Date).TimeOfDay)] Processing $c" -ForegroundColor Green
        Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 3, 4 } -ComputerName $c |
        Group-Object -Property ProviderName | ForEach-Object {
            [PSCustomObject]@{
                ComputerName = $c.ToUpper()
                LogName      = $_.group[0].LogName
                Source       = $_.Name
                TotalCount   = $_.Count
                ErrCount     = ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Error' }).Count
                WarnCount    = ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Warning' }).Count
            }
        }
        Write-Host "[$((Get-Date).TimeOfDay)] Finished $c" -ForegroundColor yellow
    } #foreach
} #41 seconds

Measure-Command {
    $q=  Invoke-Command -ScriptBlock {
        Write-Host "[$((Get-Date).TimeOfDay)] Processing $env:Computername" -ForegroundColor green
        Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 3, 4 } |
        Group-Object -Property ProviderName | ForEach-Object {
            [PSCustomObject]@{
                ComputerName =$env:Computername
                LogName      = $_.group[0].LogName
                Source       = $_.Name
                TotalCount   = $_.Count
                ErrCount     = ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Error' }).Count
                WarnCount    = ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Warning' }).Count
            }
        }
        Write-Host "[$((Get-Date).TimeOfDay)] Finished $env:Computername" -ForegroundColor yellow
    } -ComputerName $computers -HideComputerName | Select-Object -Property * -ExcludeProperty RunspaceID
} #9 seconds

#endregion

