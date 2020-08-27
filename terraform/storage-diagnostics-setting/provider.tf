provider azurerm {
    version = "= 2.25"
    features {
        virtual_machine {
            delete_os_disk_on_deletion = true
        }
    }
}