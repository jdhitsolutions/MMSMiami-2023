#Splatting with PSBoundParameters
Function Get-OS {
    [CmdletBinding(DefaultParameterSetName = 'ClassNameComputerSet')]
    Param(
        [Parameter(ParameterSetName = 'CimInstanceSessionSet', Mandatory, ValueFromPipeline)]
        [CimSession[]]$CimSession,

        [Parameter(Position = 0, ParameterSetName = 'ClassNameComputerSet', ValueFromPipelineByPropertyName)]
        [Alias('CN', 'ServerName')]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^\w+$')]
        [string[]]$ComputerName = $env:computername
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Using PowerShell host $($host.name)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Using parameter set $($PSCmdlet.ParameterSetName)"
        $PSBoundParameters.Add('ClassName', 'Win32_OperatingSystem')

        $properties = 'CSName', 'Caption', 'Version', 'BuildNumber', 'InstallDate'
        $PSBoundParameters.Add('Property', $properties)
    } #begin

    Process {
        Write-Verbose ($PSBoundParameters | Out-String)
        Write-Verbose "[$((Get-Date).TimeOfDay) PROCESS] Getting operating system with Get-CimInstance"
        Try {
            $data = Get-CimInstance @PSBoundParameters -ErrorAction stop
            foreach ($os in $data) {
                [PSCustomObject]@{
                    Computername    = $os.CSName
                    OperatingSystem = $os.caption
                    Version         = $os.version
                    Build           = $os.BuildNumber
                    Installed       = $os.installDate
                }
            } #foreach
        }
        Catch {
            Throw $_
        }

    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #end function Get-OS