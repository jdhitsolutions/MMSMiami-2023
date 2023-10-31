Function Update-CMClient{
    [cmdletbinding()]
    param(
        [Parameter(HelpMessage = "Provide the Management Point, if you don't provide one I'll guess." , Mandatory = $FALSE)]
        [string]$ManagementPoint
    )
    if(!($PSBoundParameters.ContainsKey('ManagementPoint'))){
        $ManagementPoint = (Get-CimInstance -ClassName SMS_Authority -Namespace 'root\ccm').CurrentManagementPoint   
    }
    Write-Verbose -Message "Determined the MP is: $($ManagementPoint)"
    $siteCodePath = (Get-CimInstance -ClassName SMS_Authority -Namespace 'root\ccm').Name.Replace(":","_")
    Write-Verbose -Message "Determined the Site Code Info to be: $($siteCodePath)"
    if(!(Test-Path -Path C:\Scratch\CurrentClient)){
        Write-Verbose -Message "The Scratch Space DOESNT exist, creating and downloading Client Info"
        New-Item -ItemType Directory -Path C:\Scratch\CurrentClient | Out-Null
        Copy-Item -Path \\$($ManagementPoint)\$($siteCodePath)\Client -Destination C:\Scratch\CurrentClient -Recurse
        Set-Location -Path C:\Scratch\CurrentClient\Client
        Write-Verbose -Message "Now starting the install..."
        .\ccmsetup.exe /source:C:\Scratch\CurrentClient\Client /mp:$($ManagementPoint)
        Write-Verbose -Message "Now opening log directory..."
        explorer.exe C:\Windows\ccmsetup\Logs
    }
    else{
        Write-Verbose -Verbose "Scratch space existed, cleaning up and re-downloading..."
        Remove-Item -Path C:\Scratch\CurrentClient -Recurse -Force
        New-Item -ItemType Directory -Path C:\Scratch\CurrentClient | Out-Null
        Copy-Item -Path \\$($ManagementPoint)\$($siteCodePath)\Client -Destination C:\Scratch\CurrentClient -Recurse
        Set-Location -Path C:\Scratch\CurrentClient\Client
        Write-Verbose -Message "Now starting the install..."
        .\ccmsetup.exe /source:C:\Scratch\CurrentClient\Client /mp:$($ManagementPoint)
        Write-Verbose -Message "Now opening log directory..."
        explorer.exe C:\Windows\ccmsetup\Logs
    }
}
Update-CMClient -Verbose

$vms | ForEach-Object{Invoke-Command -VMName $_.Name -FilePath C:\ConfigMgrClient.ps1 -Credential $credential -AsJob}