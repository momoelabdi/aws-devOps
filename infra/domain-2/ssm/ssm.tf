# -> set maintenance interval 
# -> schedule: every Monday at 2 AM UTC
# -> duration: 2 hours 
# -> cutoff: 1 hour ( time to wait before scheduling new tasks  )
resource "aws_ssm_maintenance_window" "patch_window" {
  name        = "ubuntu-patch-window"
  schedule    =  "cron(0 2 ? * 2 *)" 
  duration    = 2
  cutoff      = 1
  enabled     = true
  description = "Patch Maintenance Window for Ubuntu"
}

# -> task to be executed during maintenance window.
resource "aws_ssm_maintenance_window_task" "patch_task" {
  window_id = aws_ssm_maintenance_window.patch_window.id
  description  = "Automated update and upgrade of Ubuntu instances"
  priority        = 1
  task_type       = "RUN_COMMAND"
  max_concurrency = "100%"
  max_errors      = "0%"
  task_arn     = "aws:runShellScript"
  targets {
    key    = "InstanceIds"
    values = [aws_instance.ssm.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "commands"
        values = ["sudo apt update -y && sudo apt upgrade -y"]
      }
    }
  }
}