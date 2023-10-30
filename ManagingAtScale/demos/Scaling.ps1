Return 'This is a demo script file'

#region sequential
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

Path       FileCount      TotalSize AverageSize
----       ---------      --------- -----------
C:\work          260   111719917.00   429691.99
C:\windows    180921 43728661649.00   241700.31
C:\scripts     10768   608344464.00    56495.59
C:\Users\…     73168 17864185390.00   244152.98

50 seconds

#>
#endregion

#region background jobs

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
        $sb = {
            Param($Path)
            #ignore errors like Access Denied
            $stats = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -Average

            [PSCustomObject]@{
                PSTypeName  = 'folderReport'
                Path        = $Path
                FileCount   = $stats.Count
                TotalSize   = $stats.Sum
                AverageSize = $stats.Average
            }
        }
        $jobs = @()
    } #begin

    Process {
        $cPath = Convert-Path $Path
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Starting background job for $cPath"
        $jobs+= Start-Job -ScriptBlock $sb -ArgumentList $cPath
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Waiting for $($jobs.count) jobs to complete"
        $Jobs | Wait-Job | Receive-Job -Keep | Select-Object -Property * -ExcludeProperty RunspaceID
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FolderReport

#27 seconds
# "c:\work","c:\windows","c:\scripts",$home | Get-FolderReport -Verbose
# Data can remain in background jobs if you want it

#endregion

#region thread jobs
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
        $sb = {
            Param($Path)
            Write-Host "[$((Get-Date).TimeOfDay) THREAD ] Measuring $Path" -ForegroundColor Cyan
            #ignore errors like Access Denied
            $stats = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum -Average

            [PSCustomObject]@{
                PSTypeName  = 'folderReport'
                Path        = $Path
                FileCount   = $stats.Count
                TotalSize   = $stats.Sum
                AverageSize = $stats.Average
            }
            Write-Host "[$((Get-Date).TimeOfDay) THREAD ] Finished measuring $Path" -ForegroundColor cyan
        }
        $jobs = @()
    } #begin

    Process {
        $cPath = Convert-Path $Path
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Starting thread job for $cPath"
        $jobs+= Start-ThreadJob -ScriptBlock $sb -ArgumentList $cPath -StreamingHost $Host
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Waiting for $($jobs.count) thread jobs to complete"
        $Jobs | Wait-Job | Receive-Job -Keep
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-FolderReport

# "c:\work","c:\windows","c:\scripts",$home | Get-FolderReport -Verbose
#25 seconds
#endregion