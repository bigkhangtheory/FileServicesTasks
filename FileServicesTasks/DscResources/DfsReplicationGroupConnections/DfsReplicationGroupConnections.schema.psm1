<#
    .DESCRIPTION
        This resource is used to create, edit and remove DFS Replication Group connections.
        
        This resource should ONLY be used if the Topology parameter in the Resource Group is set to Manual.
#>
#Requires -Module DFSDsc

configuration DfsReplicationGroupConnections
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Connections
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName DFSDsc


    <#
        Install File Services and DFS prerequisites
    #>
    xWindowsFeature AddFileServer
    {
        Name      = 'FS-FileServer'
        Ensure    = 'Present'
        DependsOn = '[xService]LanmanServerRunning'
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
        Install Remote Differential Compression
    #>
    xWindowsFeature AddRdc
    {
        Name   = 'RDC'
        Ensure = 'Present'
    }
    $dependsOnRdc = '[xWindowsFeature]AddRdc'


    <#
        Configure Replication Group connection
    #>
    foreach ($c in $Connections)
    {
        # remove case sensitivity of ordered Dictionary or Hashtables
        $c = @{ } + $c

        # set execution name for resource
        $executionName = "Group_$($c.GroupName -replace '[-().:\s]', '_')"

        # ensure that the specified Replication Group to connect does exist and set to manual topology
        DFSReplicationGroup "$executionName"
        {
            GroupName            = $c.GroupName
            Topology             = 'Manual'
            DomainName           = $c.DomainName
            PsDscRunAsCredential = $c.Credential
            Ensure               = 'Present'
        } #end DFSReplicationGroup
        $dependsOnDfsReplicationGroup = "[DFSReplicationGroup]$executionName"



        # create execution name for the resource
        $executionName = "Connection_$($c.GroupName -replace '[-().:\s]', '_')_$($myComputerName -replace '[-().:\s]', '_')"

        # if not specified, ensure 'Present'
        if ( $null -eq $c.Ensure)
        {
            $c.Ensure = 'Present'
        }
        
        # evaluate EnsureEnabled
        if ($c.Enabled -eq $false)
        {
            $isMemberEnabled = 'Disabled'
        }
        else { $isMemberEnabled = 'Enabled' }
        
        # evaluate EnsureRDCEnabled
        if ($c.Compression -eq $false)
        {
            $isRDCEnabled = 'Disabled'
        }
        else { $isRDCEnabled = 'Enabled' } 


        # this resource is used to create, edit, and remove DFS Replication Group connections
        DFSReplicationGroupConnection "$executionName"
        {
            GroupName               = $c.GroupName
            SourceComputerName      = $c.SourceComputerName
            DestinationComputerName = $env:COMPUTERNAME
            Ensure                  = $c.Ensure
            EnsureEnabled           = $isMemberEnabled
            EnsureRDCEnabled        = $isRDCEnabled
            DomainName              = $c.DomainName
            PsDscRunAsCredential    = $c.Credential
            DependsOn = @() + $dependsOnRdc + $dependsOnDfsReplicationGroup
        } #end DFSReplicationGroupConnection
    }
}