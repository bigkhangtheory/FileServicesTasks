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

                # array of child nodes
                $mySpokes = New-Object -TypeName System.Collections.Arraylist
                foreach ($s in $g.Spokes)
                {
                    $computerName = $s.Computername
                    $mySpokes.Add($computerName)
                }

                # array of member names
                $myMembers = @() + $g.Hub + $mySpokes
                
                # array of folder names
                $myFolderNames = New-Object -TypeName System.Collections.Arraylist
                # array of content paths
                $myContentPaths = New-Object -TypeName System.Collections.Arraylist

                foreach ($f in $g.Folders)
                {
                    $folderName = $f.FolderName
                    $myFolderNames.Add($folderName)

                    $contentPath = $f.ContentPath
                    $myContentPaths.Add($contentPath)
                }

                # configure the Replication Group resource
                DFSReplicationGroup "$executionName"
                {
                    GroupName            = $g.GroupName
                    Description          = $g.Description
                    Ensure               = $g.Ensure
                    DomainName           = $g.DomainName
                    Topology             = 'Manual'
                    Members              = $myMembers
                    Folders              = $myFolderNames
                    #ContentPaths         = $myContentPaths
                    PSDSCRunAsCredential = $g.Credential
                    DependsOn            = $dependsOnRsatDfsMgmtCon
                } #end DFSReplicationGroup resource
                $dependsOnDfsReplicationGroup = "[DFSReplicationGroup]$executionName"


                # create array of hashtables
                $myFolders = @() + $g.Folders

                foreach ($f in $g.Folders)
                {
                    # set execution name of the resource
                    $executionName = "Folder_$($f.FolderName -replace '[-().:\s]', '_')"

                    # configure DFS Replication Group folder resource
                    DFSReplicationGroupFolder "$executionName"
                    {
                        GroupName            = $g.GroupName
                        FolderName           = $f.FolderName 
                        Description          = $f.Description 
                        FilenameToExclude = @() + $f.FilenameToExclude
                        DirectoryNameToExclude = @() + $f.DirectoryNameToExclude
                        DfsnPath             = $f.DfsnPath
                        DomainName           = $g.DomainName
                        PSDSCRunAsCredential = $g.Credential
                        DependsOn            = $dependsOnDfsReplicationGroup
                    } #end DFSReplicationGroupFolder resource
                    $dependsOnDfsReplicationGroupFolder = "[DFSReplicationGroupFolder]$executionName"


                    # configure DFS Replication Group folder primary membership resource
                    $executionName = "Primary_$($g.Hub -replace '[-().:\s]', '_')"
                    DFSReplicationGroupMembership "$executionName"
                    {
                        GroupName            = $g.GroupName
                        FolderName           = $f.FolderName
                        ComputerName         = $g.Hub
                        ContentPath          = $f.ContentPath
                        #StagingPath            = $f.StagingPath
                        #StagingPathQuotaInMB   = $f.StagingPathQuotaInMB
                        #ConflictAndDeletedPath = $f.ConflictAndDeletedPath
                        ReadOnly             = $false
                        PrimaryMember        = $true
                        DomainName           = $g.DomainName
                        PSDSCRunAsCredential = $g.Credential
                        DependsOn            = $dependsOnDfsReplicationGroupFolder
                    }


                    # configure DFS Replication Group folder child spoke member resource
                    $mySpokeNodes = @() + $g.Spokes
                    foreach ($s in $mySpokeNodes)
                    {
                        # if not specified, ensure 'Present'
                        if ( $null -eq $s.Ensure )
                        {
                            $s.Ensure = 'Present'
                        }

                        # evaluate EnsureEnabled
                        if ($s.Enabled -eq $false)
                        {
                            $s.EnsureEnabled = 'Disabled'
                        }
                        else
                        {
                            $s.EnsureEnabled = 'Enabled'
                        }

                        # evaluate EnsureRDCEnabled
                        if ($s.Compression -eq $false)
                        {
                            $s.EnsureRDCEnabled = 'Disabled'
                        }
                        else
                        {
                            $s.EnsureRDCEnabled = 'Enabled'
                        } 

                        # set execution name for resource
                        $executionName = "Connection_$($s.ComputerName -replace '[-().:\s]', '_')"
                        # create DFS Replication Group connection to Hub
                        DFSReplicationGroupConnection "$executionName"
                        {
                            GroupName               = $g.GroupName
                            SourceComputerName      = $g.Hub
                            DestinationComputerName = $s.ComputerName
                            Ensure                  = 'Present'
                            EnsureEnabled           = $s.EnsureEnabled
                            EnsureRDCEnabled        = $s.EnsureRDCEnabled
                            DomainName              = $g.DomainName
                            PsDscRunAsCredential    = $g.Credential
                            DependsOn               = $dependsOnDfsReplicationGroupFolder
                        }
                        $dependsOnDfsReplicationGroupConnection = "[DFSReplicationGroupConnection]$executionName"

                        # set exection name for resource
                        $executionName = "Membership_$($s.ComputerName -replace '[-().:\s]', '_')"

                        DFSReplicationGroupMembership "$executionName"
                        {
                            GroupName            = $g.GroupName
                            FolderName           = $f.FolderName
                            ComputerName         = $s.ComputerName
                            ContentPath          = $f.ContentPath
                            #StagingPath            = $f.StagingPath
                            #StagingPathQuotaInMB   = $f.StagingPathQuotaInMB
                            #ConflictAndDeletedPath = $f.ConflictAndDeletedPath
                            ReadOnly             = $s.ReadOnly
                            PrimaryMember        = $true
                            DomainName           = $g.DomainName
                            PSDSCRunAsCredential = $g.Credential
                            DependsOn            = $dependsOnDfsReplicationGroupConnection
                        }
                    }
                }

            }
            'FullMesh' {}
            Default {}
        }
    }
}