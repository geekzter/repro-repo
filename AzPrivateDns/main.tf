resource null_resource nested_pwsh {
  provisioner "local-exec" {
    command                    = "Get-Command 'New-AzPrivateDnsRecordConfig'"
    interpreter                = ["pwsh", "-nop", "-Command"]
  }
}