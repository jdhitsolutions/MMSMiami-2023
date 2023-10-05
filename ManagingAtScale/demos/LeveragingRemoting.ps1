Return 'This is a demo script file'

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

