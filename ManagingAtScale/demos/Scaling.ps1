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