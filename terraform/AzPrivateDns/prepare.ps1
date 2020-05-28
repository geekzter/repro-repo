# This module may not be present (yet)
Get-InstalledModule Az.PrivateDnsz -AllVersions -ErrorAction SilentlyContinue
Install-Module -Name Az.PrivateDns -Scope CurrentUser -Force -AllowClobber
Get-InstalledModule Az.PrivateDns -AllVersions
Get-InstalledModule Az.PrivateDns
Import-Module Az.PrivateDns
Get-Module Az.PrivateDns
Get-Command 'New-AzPrivateDnsRecordConfig'