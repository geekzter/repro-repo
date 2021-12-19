resource azurerm_resource_group repro {
  name                         = "startdate-timezone-issue"
  location                     = var.location
}

resource azurerm_logic_app_workflow stop {
  name                         = "stop-workflow"
  resource_group_name          = azurerm_resource_group.repro.name
  location                     = var.location
}  

resource azurerm_logic_app_trigger_recurrence workweek_stop_trigger {
  name                         = "workweek_stop"
  logic_app_id                 = azurerm_logic_app_workflow.stop
  frequency                    = "Week"
  interval                     = 1
  schedule {
    at_these_hours             = [21]
    at_these_minutes           = [00]
    on_these_days              = [
      "Monday",
      "Tuesday", 
      "Wednesday", 
      "Thursday", 
      "Friday",
    ]
  }
  # Valid RFC 3339 Date is not accepted
  # start_time requires a 'Z' at the end, meaning UTC time. 
  start_time                   = "2021-12-19T21:00:00" 
  # Time zone will not affect start_time as start_time is always UTC
  time_zone                    = "W. Europe Standard Time"
}