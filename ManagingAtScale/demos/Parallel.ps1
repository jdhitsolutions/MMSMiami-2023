Return 'This is a demo script file'

#region Sequential
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
#endregion

#region parallel - consider the overhead
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
