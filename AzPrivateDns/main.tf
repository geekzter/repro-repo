resource null_resource nested_pwsh {
  provisioner "local-exec" {
    command                    = "script.ps1"
    interpreter                = ["pwsh", "-nop", "-File"]
  }
  provisioner "local-exec" {
    command                    = "./script.ps1"
    interpreter                = ["pwsh", "-nop", "-Command"]
  }
  provisioner "local-exec" {
    command                    = "Get-Command 'New-AzPrivateDnsRecordConfig'"
    interpreter                = ["pwsh", "-nop", "-Command"]
  }
}