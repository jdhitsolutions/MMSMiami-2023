Function Get-OSInformation {
    [cmdletbinding()]
    [OutputType('cimOSInformation')]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline,
            HelpMessage = 'Specify the computer name to query. Default is localhost'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $ENV:COMPUTERNAME
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Using PowerShell host $($host.name)"

        $splat = @{
            ClassName    = 'Win32_OperatingSystem'
            Property     = 'CSName', 'Caption', 'Version', 'InstallDate'
            ErrorAction  = 'Stop'
            ComputerName = $null
        }
    } #begin

    Process {
        $splat.ComputerName = $Computername
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Processing $($splat.Computername)"
        Try {
            $os = Get-CimInstance @splat
            [PSCustomObject]@{
                PSTypeName      = 'cimOSInformation'
                ComputerName    = $os.CSName
                OperatingSystem = $os.caption
                Version         = $os.version
                Installed       = $os.installDate
                Age             = (Get-Date) - $os.InstallDate
            }
        } #try
        Catch {
            Write-Error "Failed to query $($Computername.ToUpper()). $($_.Exception.Message)"
        } #catch

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close Get-OSInformation