<#
    .DESCRIPTION
        This resource is used to create, edit or remove DFS Replication Groups.
#>
#Requires -Module DFSDsc

configuration DfsReplicationGroups
{
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Hashtable[]]
        $Groups
    )

    Import-DscResource -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName DFSDsc


    <#
        Ensure service dependencies
    #>
    xService LanmanServerRunning
    {
        Name         = 'LanmanServer'
        Ensure       = 'Present'
        Dependencies = @(
            'SamSS', 'Srv2'
        )
        State        = 'Running'
    }
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
        Configure the replication group
    #>
    foreach ($g in $Groups)
    {
        switch ($g.Topology)
        {
            # as Hub and Spoke topology
            'HubAndSpoke'
            {
                # remove case sensitivity of ordered Dictionary or Hashtables
                $g = @{ } + $g

                # set execution name of the resource
                $executionName = "$($g.GroupName -replace '[-().:\s]', '_')"

                # if not specified, ensure 'Present'
                if ( -not $g.ContainsKey('Ensure'))
                {
                    $g.Ensure = 'Present'
                }

                # array of member names
                $myMemberNames = New-Object -TypeName System.Collections.Arraylist
                foreach ($m in $g.Members)
                {
                    $myMemberNames.Add($m.Item('ComputerName'))
                }
                
                # array of folder names
                $myFolderNames = New-Object -TypeName System.Collections.Arraylist
                foreach ($f in $g.Folders)
                {
                    $myFolderNames.Add($f.Item('FolderName'))
                }

                # configure the Replication Group resource
                DFSReplicationGroup "$executionName"
                {
                    GroupName            = $g.GroupName
                    Description          = $g.Description
                    Ensure               = $g.Ensure
                    DomainName           = $g.DomainName
                    Topology             = 'Manual'
                    Members              = $myMemberNames
                    Folders              = $myFolderNames
                    PSDSCRunAsCredential = $g.Credential
                    DependsOn            = $dependsOnRsatDfsMgmtCon
                } #end DFSReplicationGroup resource
                $dependsOnDfsReplicationGroup = "[DFSReplicationGroup]$executionName"


                <#
                    Configure all Replication Group Folders
                #>

                foreach ($f in $g.Folders)
                {
                    # remove case sensivity for ordered Dictionary or Hashtables
                    $f = @{} + $f

                    # set execution name of the resource
                    $executionName = "Folder_$($f.FolderName -replace '[-().:\s]', '_')"

                    # configure DFS Replication Group Folder resource
                    DFSReplicationGroupFolder "$executionName"
                    {
                        GroupName              = $g.GroupName
                        FolderName             = $f.FolderName 
                        Description            = $f.Description
                        FilenameToExclude      = $f.FilenameToExclude
                        DirectoryNameToExclude = $f.DirectoryNameToExclude
                        DfsnPath               = $f.DfsnPath
                        DomainName             = $g.DomainName
                        PsDscRunAsCredential   = $g.Credential
                        DependsOn              = $dependsOnDfsReplicationGroup
                    } #end DFSReplicationGroupFolder
                    $dependsOnDfsReplicationGroupFolder = "[DFSReplicationGroupFolder]$executionName"



                    <#
                        Configure all members of the Replication Group for this Folder
                    #>
                    # identity the Primary member
                    $primaryMember = $g.Members | Where-Object { $_.PrimaryMember -eq $true }

                    # iterate through all members
                    foreach ($m in $g.Members)
                    {
                        # remove case sensitity for ordered Dictionary or Hashtables
                        $m = @{} + $m

                        $myComputerName = $m.Item('ComputerName')

                        # configure the primary member node
                        if ($m.PrimaryMember -eq $true)
                        {
                            # create execution name for the resource
                            $executionName = "Primary_$($f.FolderName)_$($m.ComputerName -replace '[-().:\s]', '_')"

                            # this resource is used to configure Replication Group Folder Membership
                            DFSReplicationGroupMembership "$executionName"
                            {
                                GroupName            = $g.GroupName
                                FolderName           = $f.FolderName
                                ComputerName         = $m.ComputerName
                                ContentPath          = $f.ContentPath
                                #StagingPath = $f.StagingPath
                                #StagingPathQuotaInMB   = $f.StagingPathQuotaInMB
                                #ConflictAndDeletedPath = $f.ConflictAndDeletedPath
                                ReadOnly             = $false 
                                PrimaryMember        = $true
                                DomainName           = $g.DomainName
                                PsDscRunAsCredential = $g.Credential
                                DependsOn            = $dependsOnDfsReplicationGroupFolder
                            } #end DFSReplicationGroupMembership

                        } #end if
                        elseif ($m.PrimaryMember -eq $false)
                        {
                            # create execution name for the resource
                            $executionName = "Connection_$($f.FolderName)_$($myComputerName -replace '[-().:\s]', '_')"

                            # if not specified, ensure 'Present'
                            if ( $null -eq $m.Ensure)
                            {
                                $m.Ensure = 'Present'
                            }

                            # evaluate EnsureEnabled
                            if ($m.Enabled -eq $false)
                            {
                                $isMemberEnabled = 'Disabled'
                            }
                            else { $isMemberEnabled = 'Enabled' }

                            # evaluate EnsureRDCEnabled
                            if ($m.Compression -eq $false)
                            {
                                $isRDCEnabled = 'Disabled'
                            }
                            else { $isRDCEnabled = 'Enabled' } 
                            
                            # this resource is used to create, edit, and remove DFS Replication Group connections
                            DFSReplicationGroupConnection "$executionName"
                            {
                                GroupName               = $g.GroupName
                                SourceComputerName      = $primaryMember.ComputerName #$($primaryMember.ComputerName)
                                DestinationComputerName = $myComputerName
                                Ensure                  = $g.Ensure
                                EnsureEnabled           = $isMemberEnabled
                                EnsureRDCEnabled        = $isRDCEnabled
                                DomainName              = $g.DomainName
                                PsDscRunAsCredential    = $g.Credential
                                DependsOn = @() + $dependsOnRdc + $dependsOnDfsReplicationGroup
                            } #end DFSReplicationGroupConnection
                            $dependsOnDfsReplicationGroupConnection = "[DFSReplicationGroupConnection]$executionName"


                            # create execution name for the resource
                            $executionName = "Membership_$($f.FolderName)_$($m.ComputerName -replace '[-().:\s]', '_')"


                            # this resource is used to configure Replication Group Folder Membership
                            DFSReplicationGroupMembership "$executionName"
                            {
                                GroupName            = $g.GroupName
                                FolderName           = $f.FolderName
                                ComputerName         = $m.ComputerName
                                ContentPath          = $f.ContentPath
                                StagingPathQuotaInMB = $f.StagingPathQuotaInMB
                                ReadOnly             = $m.ReadOnly
                                PrimaryMember        = $m.PrimaryMember
                                DomainName           = $g.DomainName
                                PsDscRunAsCredential = $g.Credential
                                DependsOn            = $dependsOnDfsReplicationGroupConnection
                            } #end DFSReplicationGroupMembership
                        }
                    }
                }
            }
            'FullMesh' {}
            Default {}
        }
    }
}