<#
    .DESCRIPTION
        This DSC configuration is used to configure Replication Group Folder membership.
    .PARAMETER GroupName
        Specifies the name of the DFS Replication Group.
    .PARAMETER DomainName
        Specifies the name of the AD Domain the DFS Replication Group connection should be in.
    .PARAMETER Folders
        A list of Replication Group Folders and their content path on a target node.
    .PARAMETER Credential
        Specify the credential to configure the DFS Replication Group
#>
#Requires -Module DFSDsc


configuration DfsReplicationGroupMemberships
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $GroupName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Folders,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    <#
        Import required modules
    #>
    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName DFSDsc

    <#
        Install File Services and DFS prerequisites
    #>
    xWindowsFeature AddFileServer
    {
        Name   = 'FS-FileServer'
        Ensure = 'Present'
    }
    xWindowsFeature AddDfsReplication
    {
        Name      = 'FS-DFS-Replication'
        Ensure    = 'Present'
        DependsOn = '[xWindowsFeature]AddFileServer'
    }
    xWindowsFeature AddRsatDfsMgmtCon
    {
        Name      = 'RSAT-DFS-Mgmt-Con'
        Ensure    = 'Present'
        DependsOn = '[xWindowsFeature]AddDfsReplication'
    }
    $dependsOnRsatDfsMgmtCon = '[xWindowsFeature]AddRsatDfsMgmtCon'

    <#
        Created DSC resource for DFS Replication Group memberships
    #>
    if ($Folders)
    {
        foreach ($f in $Folders)
        {
            # remove case sensitivity of ordered Dictionary or Hashtable
            $f = @{ } + $f

            # create hashtable
            $params = @{ }

            # store parameters
            $params = $f

            # add GroupName
            $params.GroupName = $GroupName

            # add DomainName
            $params.DomainName = $DomainName

            # add the name of the current node to enact the resource
            $params.ComputerName = $node.Name

            # this resource depends on DFS management
            #$params.DependsOn = $dependsOnRsatDfsMgmtCon

            # run the resource using Credentials
            $params.PsDscRunAsCredential = $Credential

            # set execution name for the resource
            $executionName = "$($GroupName -replace '[-().:\s]', '_')_$($f.FolderName -replace '[-().:\s]', '_')"


            # create DSC resource
            $Splatting = @{
                ResourceName  = 'DFSReplicationGroupMembership'
                ExecutionName = $executionName
                Properties    = $params
                NoInvoke      = $true
            }
            (Get-DscSplattedResource @Splatting).Invoke($params)
        } #end foreach
    } #end if
} #end configuration