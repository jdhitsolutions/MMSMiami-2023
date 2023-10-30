Return 'This is a demo script file'

#region OutVariable
Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 2 } -MaxEvents 1000 -OutVariable errLog |
Group-Object -Property ProviderName -OutVariable go

$errLog[0..4]
$go
$go[-1].Group

#endregion

#region Tee-Object

Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 2 } -MaxEvents 1000 -OutVariable errLog |
Group-Object -Property ProviderName -OutVariable go | Tee-Object -Variable r

$r

#you can also Tee to a file

#endregion

#region PipelineVariable

Get-ChildItem c:\work -File -PipelineVariable source |
Copy-Item -Destination c:\temp -PassThru -PipelineVariable dest |
ForEach-Object {
    $msg = "[$(Get-Date)] Copied {0} from {1} to {2}" -f $source.Name, $source.DirectoryName, $dest.DirectoryName
    Write-Host $msg -ForegroundColor Yellow
}

#endregion
#region putting it all together
#this is not the only way or even the best way to accomplish this task

$splat = @{
    FilterHashtable = @{LogName = 'System'; Level = 2, 3, 4 }
    MaxEvents = 1000
    OutVariable = 'sysLog'
    PipelineVariable = 'get'
}

Get-WinEvent @splat |
Group-Object -Property ProviderName -OutVariable go -PipelineVariable group |
Tee-Object -Variable t |
Select-Object -OutVariable r -property @{Name = 'LogName'; Expression = { $get.LogName } },
Name,
@{Name = 'TotalCount'; Expression = { $_.Count } },
@{Name = 'TotalPct'; Expression = { ($_.Count / ($t | measure count -Sum).sum) * 100 } },
@{Name = 'ErrCount'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Error' }).Count } },
@{Name = 'ErrPct'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Error' }).Count / $group.Count * 100 } },
@{Name = 'WarnCount'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Warning' }).Count } },
@{Name = 'WarnPct'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Warning' }).Count / $group.Count * 100 } },
@{Name = 'InfoCount'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Information' }).Count } },
@{Name = 'InfoPct'; Expression = { ($_.Group | Where-Object { $_.LevelDisplayName -eq 'Information' }).Count / $group.Count * 100 } }


#re-use the data
$t | Sort-Object -Property count -Descending | Select Count,Name -first 10
$syslog | Select-Object -Property ProviderName -Unique | Sort-Object -Property ProviderName
$r | Where-Object InfoPct -ne 100 | Format-Table -GroupBy LogName -Property Name,*count,*pct

#endregion
