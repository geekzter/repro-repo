function AzLogin () {
    if (!(Get-AzContext)) {
        Write-Host "Reconnecting to Azure with SPN..."
        if(-not($env:ARM_CLIENT_ID)) { Throw "You must supply a value for clientid" }
        if(-not($clientsecret=$env:ARM_CLIENT_SECRET)) { Throw "You must supply a value for clientsecret" }
        # Use Terraform ARM Backend config to authenticate to Azure
        $secureClientSecret = ConvertTo-SecureString $clientsecret=$env:ARM_CLIENT_SECRET -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($env:ARM_CLIENT_ID, $secureClientSecret)
        $null = Connect-AzAccount -Tenant $env:ARM_TENANT_ID -Subscription $env:ARM_SUBSCRIPTION_ID -ServicePrincipal -Credential $credential
    }
    $null = Set-AzContext -Subscription $env:ARM_SUBSCRIPTION_ID -Tenant $env:ARM_TENANT_ID
}

#AzLogin
# if (!(Get-Module Az.PrivateDns)) {
#     Write-Host "PowerShell module Az.PrivateDns not imported, importing now.."
#     Import-Module Az.PrivateDns
#     Get-Module Az.PrivateDns
# }
Get-Module Az.Accounts
Get-Module Az.Accounts -ListAvailable
Get-Command Get-AzResource
Get-Command New-AzPrivateDnsRecordConfig