resource null_resource nested_pwsh {
  provisioner "local-exec" {
    command                    = "script.ps1"
    interpreter                = ["pwsh", "-nop", "-File"]
  }
}