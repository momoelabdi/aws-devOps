
# -> set baseline with AWS predefined patch baseline for Ubuntu 
resource "aws_ssm_patch_baseline" "ubuntu_patch_baseline" {
  name        = "ubuntu_patch_baseline"
  description = "AWS Managed Patch Baseline for Ubuntu"
  operating_system = "UBUNTU"
  # source {
  #   name = "AWS-UbuntuDefaultPatchBaseline"
  #   products = ["Ubuntu20.04"]
  # }
  approval_rule {
    approve_after_days = 7
    compliance_level  = "CRITICAL"

    patch_filter {
      key    = "PRODUCT" 
      values = ["Ubuntu20.04"]
    }
    patch_filter {
      key    = "PRODUCT" 
      values = ["Ubuntu20.04"]
    }

    patch_filter {
      key    = "PRIORITY" 
      values = ["Required", "Important", "Standard"]
    }
  }
}

# -> set maintenance interval 
# -> schedule: every Monday at 2 AM UTC
# -> duration: 2 hours 
# -> cutoff: 1 hour ( time to wait before scheduling new tasks  )
resource "aws_ssm_maintenance_window" "patch_window" {
  name        = "ubuntu-patch-window"
  schedule    = "cron(* * * * ? *)"
  duration    = 2
  cutoff      = 1
  enabled     = true
  description = "Patch Maintenance Window for Ubuntu"
}

# -> identifies the ec2s target by "PatchGroup" tag
resource "aws_ssm_maintenance_window_target" "patch_target" {
  window_id     = aws_ssm_maintenance_window.patch_window.id
  resource_type = "INSTANCE"
  targets {
    key    = "tag:PatchGroup"
    values = ["ubuntu-servers"]
  }
}

# -> task to be executed during maintenance window.
# -> basic task that scans for OS security-related patches that have a priority of "Required".
resource "aws_ssm_maintenance_window_task" "patch_task" {
  window_id = aws_ssm_maintenance_window.patch_window.id
  priority        = 1
  max_concurrency = "100%"
  max_errors      = "0%"
  task_type = "RUN_COMMAND"
  task_arn = "AWS-UbuntuDefaultPatchBaseline"
  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.patch_target.id]
  }
  
  # task_invocation_parameters {
  #   run_command_parameters {
  #     parameter {
  #       name   = "Operation"
  #       values = ["Scan"] # 'Install' to apply patches, 'Scan' to just check for missing patches
  #     }

  #     parameter {
  #       name   = "BaselineName"
  #       values = ["AWS-UbuntuDefaultPatchBaseline"]
  #     }
  #   }
  # }
  task_invocation_parameters {}

  service_role_arn = aws_iam_role.ssm_role.arn
  depends_on       = [aws_instance.ssm, aws_ssm_maintenance_window_target.patch_target]
}




