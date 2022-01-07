@{

    PSDependOptions              = @{
        AddToPath      = $true
        Target         = 'BuildOutput\Modules'
        DependencyType = 'PSGalleryModule'
        Parameters     = @{
            Repository = 'PSGallery'
        }
    }

    # -------------------------------------------------------------------------
    # PowerShell Modules
    # -------------------------------------------------------------------------
    
    BuildHelpers                 = 'latest'
    # Helper functions for PowerShell CI/CD scenarios

    Datum                        = 'latest'
    # Module to manage Hierachical Configuration Data

    'Datum.InvokeCommand'        = 'latest'
    # Datum Handler module to encrypt and decrypt secrets in Datum using Dave Wyatt's ProtectedData module

    'Datum.ProtectedData'        = 'latest'
    # Datum Handler module to encrypt and decrypt secrets in Datum using Dave Wyatt's ProtectedData module

    DscBuildHelpers              = 'latest'
    # Build Helpers for DSC Resources and Configurations

    InvokeBuild                  = '5.8.4'
    # Build and test automation in PowerShell

    Pester                       = '4.10.1'
    # Pester provides a framework for running BDD style Tests to execute and validate PowerShell commands inside of PowerShell.
    # It offers a powerful set of Mocking Functions that allow tests to mimic and mock the functionality of any command inside of a piece of PowerShell code being tested.
    # Pester tests can execute any command or script that is accessible to a pester test file. This can include functions, Cmdlets, Modules and scripts.
    # Pester can be run in ad hoc style in a console or it can be integrated into the Build scripts of a Continuous Integration system.

    'posh-git'                   = 'latest'
    # Provides prompt with Git status summary information and tab completion for Git commands, parameters, remotes and branch names.

    'powershell-yaml'            = 'latest'
    # Powershell module for serializing and deserializing YAML

    ProtectedData                = 'latest'
    # Encrypt and share secret data between different users and computers.

    PSScriptAnalyzer             = 'latest'
    # Provides script analysis and checks for potential code defects in the scripts by applying a group of built-in or customized rules on the scripts being analyzed.

    PSDeploy                     = 'latest'
    # Module to simplify PowerShell based deployments

    # -------------------------------------------------------------------------
    # DSC Resources
    # -------------------------------------------------------------------------
    
    ComputerManagementDsc        = '8.4.0'
    # DSC resources for configuration of a Windows computer.
    # These DSC resources allow you to perform computer management tasks, such as renaming the computer,
    # joining a domain and scheduling tasks as well as configuring items such as virtual memory, event logs, time zones and power settings.

    DfsDsc                       = '4.4.0'
    # DSC resources for configuring Distributed File System Replication and Namespaces
    
    xPSDesiredStateConfiguration = '9.1.0'
    # DSC resources for configuring common operating systems features, files and settings.
}
