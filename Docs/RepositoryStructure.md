# Repository Structure

The root of the tree would be similar to a module root tree where you have supporting files for, say, the CI/CD integration.

- a Build.ps1 that defines the build workflow by composing tasks (see [SampleModule](https://github.com/gaelcolas/SampleModule))
- a Build/ folder, which includes the minimum tasks to bootstrap + custom ones
- the .gitignore where folders like BuildOutput or kitchen specific files are added (`module/`)
- the [PSDepend.Build.psd1](./PSDepend.Build.ps1), so that the build process can use [PSDepend](https://github.com/RamblingCookieMonster/PSDepend/) to pull any prerequisites to build this project
- the Gitlab runner configuration file

## Configuration Module Folder

Very similar to a PowerShell Module folder, the Shared configuration re-use the same principles and techniques.

The re-usable configuration itself is declared in the ps1, the metadata and dependencies in the psd1 to leverage all the goodies of module management, then we have some assets ordered in folders:

- ConfigurationData: the default/example configuration data, organised in test suite/scenarios
- Test Acceptance & Integration: the pester tests used to validate the configuration, per test suite/scenario
- the examples of re-using that shared configuration, per test suite/scenario

## Project Tree

```
CompositeResourceName
│   .gitignore
│   .gitlab-ci.yml
│   Build.ps1
│   CompositeResourceName.PSDeploy.ps1
│   PSDepend.Build.psd1
│   README.md
│
├───Build
│   ├───BuildHelpers
│   │       Invoke-InternalPSDepend.ps1
│   │       Resolve-Dependency.ps1
│   │       Set-PSModulePath.ps1
│   └───Tasks
│           CleanBuildOutput.ps1
│           CopyModule.ps1
│           Deploy.ps1
│           DownloadDscResources.ps1
│           Init.ps1
│           IntegrationTests.ps1
│           SetPsModulePath.ps1
│           TestReleaseAcceptance.ps1
│
├───BuildOutput
│   │   localhost_Configuration1.mof
│   │   localhost_Configuration2.mof
│   │   localhost_Configuration3.mof
│   │   localhost_ConfigurationN.mof
│   │
│   ├───Modules
│   │
│   └───Pester
│           IntegrationTestResults.xml
│
├───docs
│       Configuration1.md
│       Configuration2.md
│       Configuration3.md
│       ConfigurationN.md
│
└───CompositeResourceName
    │   CompositeResourceName.psd1
    │
    ├───DscResources
    │   ├───Configuration1
    │   │       Configuration1.psd1
    │   │       Configuration1.psm1
    │   │
    │   ├───Configuration2
    │   │       Configuration2.psd1
    │   │       Configuration2.psm1
    │   │
    │   ├───Configuration3
    │   │       Configuration3.psd1
    │   │       Configuration3.psm1
    │   │
    │   ├───ConfigurationN
    │   │       ConfigurationN.psd1
    │   │       ConfigurationN.psm1
    │   ...
    │
    └───Tests
        ├───Acceptance
        │       01 Gallery Available.Tests.ps1
        │       02 HasDscResources.Tests.ps1
        │       03 CanBeUninstalled.Tests.ps1
        │
        └───Integration
            │   01 DscResources.Tests.ps1
            │   02.Final.Tests.ps1
            │
            └───Assets
                │   AllNodes.yml
                │   Datum.yml
                │   TestHelpers.psm1
                │
                └───Config
                        Configuration1.yml
                        Configuration2.yml
                        Configuration3.yml
                        ConfigurationN.yml

```

The Composite Resource should be self contained, but will require files for building/testing or development.
The repository will hence need some project files on top of the files required for functionality.

Adopting the 2 layers structure like so:

```
+-- CompositeResourceName\
    +-- CompositeResourceName\
```

Allows to place Project files like build, CI configs and so on at the top level, and everything under the second level are the files that need to be shared and will be uploaded to the PSGallery.

Within that second layer, the Configuration looks like a standard module with some specificities.