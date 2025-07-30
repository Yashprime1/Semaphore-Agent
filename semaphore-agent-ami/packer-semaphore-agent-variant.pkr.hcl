variable "default_agent_ami" {
  type        = string
  description = "The AMI ID of the default agent to use as the base image."
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

source "amazon-ebs" "with-tools" {
  ami_name      = "semaphore-agent-with-tools-{{timestamp}}"
  instance_type = "t2.micro"
  region        = var.aws_region
  source_ami    = var.default_agent_ami
  ssh_username  = "ubuntu"
}

source "amazon-ebs" "with-tools-ultron" {
  ami_name      = "semaphore-agent-with-tools-ultron-{{timestamp}}"
  instance_type = "t2.micro"
  region        = var.aws_region
  source_ami    = var.default_agent_ami
  ssh_username  = "ubuntu"
}

build {
  name    = "with-tools"
  sources = ["source.amazon-ebs.with-tools"]

  provisioner "shell" {
    script = "semaphore-agent-ami/with-tools/bootstrap.sh"
    execute_command = "sudo bash '{{ .Path }}'"
  }
}

build {
  name    = "with-tools-ultron"
  sources = ["source.amazon-ebs.with-tools-ultron"]

  provisioner "shell" {
    script = "semaphore-agent-ami/with-tools/bootstrap.sh"
    execute_command = "sudo bash '{{ .Path }}'"
  }
  provisioner "shell" {
    script = "semaphore-agent-ami/ultron/bootstrap.sh"
    execute_command = "sudo bash '{{ .Path }}'"
  }
} 
