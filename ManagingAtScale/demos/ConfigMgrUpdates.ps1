
function Get-ConfigMgrUpdates {
    [cmdletbinding()]
    param(
        [Parameter(HelpMessage = "Enter the path for Telem to be stored" , Mandatory = $true, Position = 1)]
        [System.IO.FileInfo]$OfflinePath,
        [Parameter(HelpMessage = "Enter the path for Telem to be stored" , Mandatory = $true, Position = 2)]
        [ValidateScript({$_ -ne $OfflinePath})]
        [System.IO.FileInfo]$DownloadPath
    )
        
        if(!(Test-Path -Path $OfflinePath)){
            try{
                New-Item -ItemType Directory -Path $OfflinePath -ErrorAction Stop | Out-Null
                Write-Verbose -Message "Created Directory" -Verbose
            }
            catch{
                Write-Error -Message $Error[0].Exception.Message
                break
            }
        }
        Write-Verbose -Message "Found Valid Path for offline CAB creation" -Verbose
        if(Test-Path -Path $DownloadPath){
            try{
                if((Get-ChildItem -Path $DownloadPath | Measure-Object).Count -gt 0){
                    Write-Error -Message "You must provide an EMPTY download directory" -ErrorAction Stop
                }
                else{
                    Write-Verbose -Message "Valid Directory for download" -Verbose
                }
            }
            catch{
                
                break
            }
        }
        else{
            New-Item -ItemType Directory -Path $DownloadPath | Out-Null
        }
        Try{
            Set-location $(Resolve-Path "$($ENV:SMS_ADMIN_UI_PATH)\..\..\..\CD.Latest\SMSSETUP\TOOLS\ServiceConnectionTool" -ErrorAction Stop).Path -ErrorAction Stop
        }
        Catch{
            Write-Error -Message "Could not find the service connection tool"
            break
        }
        
        Try{
            .\ServiceConnectionTool.exe -prepare -usagedatadest "$($OfflinePath)\usage.cab"
            Write-Verbose -Message "Completed prepare Step" -Verbose
            .\ServiceConnectionTool.exe -connect -downloadsiteversion -usagedatasrc $OfflinePath -updatepackdest $DownloadPath
            Write-Verbose -Message "Completed Sync Step" -Verbose
            .\ServiceConnectionTool.exe -import -updatepacksrc $DownloadPath
            Write-Verbose -Message "Completed Download Step" -Verbose
        }
        catch{
            Write-Error -Message "Something went terribly wrong..."
            break
        }
        if((Get-ChildItem -Path $DownloadPath | Measure-Object).Count -gt 0){
            Write-Output -InputObject "Completed downloading content, and likely importing"
        }
    }
    
$vms | ForEach-Object{Invoke-Command -VMName $_.Name -FilePath C:\ConfigMgrUpdates.ps1 -Credential $credential -AsJob}

Get-ConfigMgrUpdates -OfflinePath C:\Offline -DownloadPath C:\Offline\Download -Verbose -_