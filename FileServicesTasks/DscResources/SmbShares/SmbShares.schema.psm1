<#
    .DESCRIPTION
        This configuration is used to manage SMB server configuration, SMB shares, and acccess permissions to SMB shares.
#>
#Requires -Module ComputerManagementDsc

configuration SmbShares
{
    param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $ServerConfiguration,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $Shares
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    WindowsFeature featureFileServer
    {
        Name   = 'FS-FileServer'
        Ensure = 'Present'
    }

    $featureFileServer = '[WindowsFeature]featureFileServer'

    if ( $null -ne $ServerConfiguration )
    {
        if ( $ServerConfiguration.EnableSMB1Protocol -eq $false )
        {
            WindowsFeature removeSMB1
            {
                Name      = 'FS-SMB1'
                Ensure    = 'Absent'
                DependsOn = $featureFileServer
            }
        }

        $ServerConfiguration.IsSingleInstance = 'Yes'
        $ServerConfiguration.DependsOn = $featureFileServer

        (Get-DscSplattedResource -ResourceName SmbServerConfiguration -ExecutionName 'smbServerConfig' -Properties $ServerConfiguration -NoInvoke).Invoke($ServerConfiguration)
    }

    if ( $null -ne $Shares )
    { 
        foreach ( $share in $Shares )
        {
            # Remove Case Sensitivity of ordered Dictionary or Hashtables
            $share = @{} + $share

            # create execution name for the resource
            $shareId = "$($share.Name -replace '[-().:$\s]', '_')"

            $share.DependsOn = $featureFileServer

            if ( -not $share.ContainsKey('Ensure') )
            {
                $share.Ensure = 'Present'
            }

            if ( $share.Ensure -eq 'Present' )
            {
                if ( [string]::IsNullOrWhiteSpace($share.Path) )
                {
                    throw "ERROR: Missing path of the SMB share '$($share.Name)'."
                }

                # skip root paths
                $dirInfo = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $share.Path

                if ( -not (Test-Path -Path $share.Path) )
                {
                    File "Folder_$shareId"
                    {
                        DestinationPath = $share.Path
                        Type            = 'Directory'
                        Ensure          = 'Present'
                        DependsOn       = $featureFileServer
                    }

                    $share.DependsOn = "[File]Folder_$shareId"
                }
            }
            elseif ( [string]::IsNullOrWhiteSpace($share.Path) )
            {
                $share.Path = 'Unused'
            }

            # create DSC resource for SMB share
            $Splatting = @{
                ResourceName  = 'SmbShare'
                ExecutionName = "SmbShare_$shareId"
                Properties    = $share
                NoInvoke      = $true
            }
            (Get-DscSplattedResource @Splatting).Invoke($share)
        }
    }  
}
