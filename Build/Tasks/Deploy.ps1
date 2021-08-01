Task Deploy {
    Write-Host "Starting deployment with files inside '$ProjectPath'"

    $Params = @{
        Path    = $ProjectPath
        Recurse = $false
        Verbose = $false
        Force   = $true
        Confirm = $false
    }
    Invoke-PSDeploy @Params
}
