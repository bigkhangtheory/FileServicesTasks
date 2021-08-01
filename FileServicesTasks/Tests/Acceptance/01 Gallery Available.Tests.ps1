#take the first trusted gallery to test against, otherwise the PSGallery. This is sufficient for this demo
$repository = Get-PSRepository | Where-Object {$_.Name -eq 'MapPSGallery'}
if (-not $repository) {
    $repository = Get-PSRepository -Name PSGallery
}
$repositoryName = $repository.Name
$moduleName = $env:BHProjectName

Describe "Module '$moduleName' is available on the repository '$repositoryName'" -Tags 'FunctionalQuality' {
    It 'Can be found' {
        Find-Module -name $moduleName -Repository $repositoryName | Should Not BeNullOrEmpty
    }

    It "Module '$moduleName' can be imported" {
        { Import-Module -name $moduleName -Scope Global } | Should Not Throw
    }
}
