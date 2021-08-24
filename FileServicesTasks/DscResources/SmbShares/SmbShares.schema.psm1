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
        [ValidateSet('Server', 'Client')]
        [System.String]
        $HostOS = 'Server',
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable]
        $ServerConfiguration,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Shares
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc

    if ( $HostOS -eq 'Server' )
    {
        WindowsFeature featureFileServer
        {
            Name   = 'FS-FileServer'
            Ensure = 'Present'
        }

        $featureFileServer = '[WindowsFeature]featureFileServer'
    }

    if ( $null -ne $ServerConfiguration )
    {
        if ( $HostOS -eq 'Server' )
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

            $ServerConfiguration.DependsOn = $featureFileServer
        }

        $ServerConfiguration.IsSingleInstance = 'Yes'

        (Get-DscSplattedResource -ResourceName SmbServerConfiguration -ExecutionName 'smbServerConfig' -Properties $ServerConfiguration -NoInvoke).Invoke($ServerConfiguration)
    }

    if ( $null -ne $Shares )
    { 
        foreach ( $share in $Shares )
        {
            # Remove Case Sensitivity of ordered Dictionary or Hashtables
            $share = @{} + $share

            $shareId = $share.Name -replace '[:$\s]', '_'

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

                if ( $null -ne $dirInfo.Parent )
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

            (Get-DscSplattedResource -ResourceName SmbShare -ExecutionName "SmbShare_$shareId" -Properties $share -NoInvoke).Invoke($share)
        } #end foreach
    } #end if
} #end configuration
