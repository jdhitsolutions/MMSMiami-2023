Return 'This is a demo script file'

#region outvariable
Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 2 } -MaxEvents 1000 -OutVariable errLog |
Group-Object -Property ProviderName -OutVariable go

$errLog[0..10]
$go[-1].Group

#endregion

#region Tee-Object
Get-WinEvent -FilterHashtable @{LogName = 'System'; Level = 2 } -MaxEvents 1000 -OutVariable errLog |
Group-Object -Property ProviderName -OutVariable go | Tee-Object -Variable r

$r
#endregion

#region pipelinevariable

Get-ChildItem c:\work -File -PipelineVariable source | Copy-Item -Destination c:\temp -PassThru -PipelineVariable dest |
ForEach-Object {
    $msg = "[$(Get-Date)] Copied {0} from {1} to {2}" -f $source.Name, $source.DirectoryName, $dest.DirectoryName
    Write-Host $msg -ForegroundColor Yellow
}

#endregion
#region putting it all together
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
