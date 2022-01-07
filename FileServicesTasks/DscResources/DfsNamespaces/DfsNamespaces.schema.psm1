<#
    .SYNOPSIS
    This configuration is used to create, edit or remove standalone or domain based DFS namespaces.

    .PARAMETER DomainFqdn
        [System.String]
        Specify the full qualified domain name of the domain for which to create the namespace.

    .PARAMETER NamespaceShares
        [System.Collections.Hashtable[]]
        Specify a list of DFS Namespace Root Shares to create.

    .PARAMETER Path
    Specifies a path for the root of a DFS namespace.

    .PARAMETER TargetPath
    Specifies a path for a root target of the DFS namespace.

    .PARAMETER Ensure
    Specifies if the DFS Namespace root should exist.

    .PARAMETER Type
    Specifies the type of a DFS namespace as a Type object.

    .PARAMETER Description
    The description of the DFS Namespace.

    .PARAMETER TimeToLiveSec
    Specifies a TTL interval, in seconds, for referrals.

    .PARAMETER EnableSiteCosting
    Indicates whether a DFS namespace uses cost-based selection.

    .PARAMETER EnableInsiteReferrals
    Indicates whether a DFS namespace server provides a client only with referrals that are in the same site as the client.

    .PARAMETER EnableAccessBasedEnumeration
    Indicates whether a DFS namespace uses access-based enumeration.

    .PARAMETER EnableRootScalability
    Indicates whether a DFS namespace uses root scalability mode.

    .PARAMETER EnableTargetFailback
    Indicates whether a DFS namespace uses target failback.

    .PARAMETER ReferralPriorityClass
    Specifies the target priority class for a DFS namespace root.

    .PARAMETER ReferralPriorityRank
    Specifies the priority rank, as an integer, for a root target of the DFS namespace.
#>


configuration DfsNamespaces
{
    param
    (
        [Parameter(Mandatory)]
        [System.String]
        $DomainFqdn,

        [Parameter()]
        [System.Collections.Hashtable[]]
        $RootShares,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $DomainCredential
    )

    <#
        Import required modules
    #>
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName DfsDsc



    <#
        Install prerequisites
    #>
    WindowsFeature AddFsDfsNamespace
    {
        Name   = 'FS-DFS-Namespace'
        Ensure = 'Present'
    }
    WindowsFeature AddRsatDfsMgmtCon
    {
        Name   = 'RSAT-DFS-Mgmt-Con'
        Ensure = 'Present'
    }
    $dependsOnAddRsatDfsMgmtCon = '[WindowsFeature]AddRsatDfsMgmtCon'


    <#
        Enumerate all DFSN shares
    #>
    foreach ($rootShare in $RootShares)
    {
        # create hashtable to store resource parameters
        $params = @{}

        # remove case sensitivity of ordered Dictionary or Hashtable
        $rootShare = @{ } + $rootShare

        # the property 'Name' must be specified, otherwise fail
        if ($rootShare.ContainsKey('Name'))
        {
            $params.Path = '\\{0}\{1}' -f $DomainFqdn, $rootShare.Name
        }
        else
        {
            throw 'ERROR: The property Name is not defined.'
        }

        # format the 'TargetPath' on the target node
        $params.TargetPath = '\\{0}.{1}\{2}' -f $node.Name, $DomainFqdn, $rootShare.Name

        # if property 'Type' not specify, set defaults
        if ($rootShare.ContainsKey('Type'))
        {
            $params.Type = $rootShare.Type
        }
        else
        {
            $params.Type = 'DomainV2'
        }

        # if property 'Description' not specify, set defaults
        if ($rootShare.ContainsKey('Description'))
        {
            $params.Description = $rootShare.Description
        }
        else
        {
            $params.Description = ''
        }

        # if property 'SiteCosting' not specify, set defaults
        if ($rootShare.ContainsKey('SiteCosting'))
        {
            $params.EnableSiteCosting = $rootShare.SiteCosting
        }
        else
        {
            $params.EnableSiteCosting = $true
        }

        # if property 'InsiteReferrals' not specify, set defaults
        if ($rootShare.ContainsKey('InsiteReferrals'))
        {
            $params.EnableInsiteReferrals = $rootShare.InsiteReferrals
        }
        else
        {
            $params.EnableInsiteReferrals = $true
        }

        # if property 'AccessBasedEnumeration' not specify, set defaults
        if ($rootShare.ContainsKey('AccessBasedEnumeration'))
        {
            $params.EnableAccessBasedEnumeration = $rootShare.AccessBasedEnumeration
        }
        else
        {
            $params.EnableAccessBasedEnumeration = $true
        }

        # if property 'RootScalability' not specify, set defaults
        if ($rootShare.ContainsKey('RootScalability'))
        {
            $params.EnableRootScalability = $rootShare.RootScalability
        }
        else
        {
            $params.EnableRootScalability = $true
        }

        # if property 'TargetFailback' not specify, set defaults
        if ($rootShare.ContainsKey('TargetFailback'))
        {
            $params.EnableTargetFailback = $rootShare.TargetFailback
        }
        else
        {
            $params.EnableTargetFailback = $true
        }

        # if property 'ReferralPriorityClass' not specify, set defaults
        if ($rootShare.ContainsKey('ReferralPriorityClass'))
        {
            $params.ReferralPriorityClass = $rootShare.ReferralPriorityClass
        }
        else
        {
            $params.ReferralPriorityClass = 'SiteCost-Normal'
        }

        # if property 'ReferralPriorityRank' not specify, set defaults
        if ($rootShare.ContainsKey('ReferralPriorityRank'))
        {
            $params.ReferralPriorityRank = $rootShare.ReferralPriorityRank
        }
        else
        {
            $params.ReferralPriorityRank = 0
        }

        # if property 'TimeToLiveSec' not specify, set defaults
        if ($rootShare.ContainsKey('TimeToLiveSec'))
        {
            $params.TimeToLiveSec = $rootShare.TimeToLiveSec
        }
        else
        {
            $params.EnableTargetFailback = 300
        }

        # if not specified, ensure 'Present'
        if (-not $rootShare.ContainsKey('Ensure'))
        {
            $params.Ensure = 'Present'
        }

        # Set PsDscRunasCredential is specified
        if ($PSBoundParameters.ContainsKey('DomainCredential'))
        {
            $params.PsDscRunAsCredential = $DomainCredential
        }

        # this resource depends on DFSN Rsat
        $params.DependsOn = $dependsOnAddRsatDfsMgmtCon

        # create execution name for the resource
        $executionName = "$("$($node.Name)_$($DomainFqdn)_$($rootShare.Name)" -replace '[-().:\s]', '_')"

        # create DSC resource
        $Splatting = @{
            ResourceName  = 'DFSNamespaceRoot'
            ExecutionName = $executionName
            Properties    = $params
            NoInvoke      = $true
        }
        (Get-DscSplattedResource @Splatting).Invoke($params)
    }
} #end configuration