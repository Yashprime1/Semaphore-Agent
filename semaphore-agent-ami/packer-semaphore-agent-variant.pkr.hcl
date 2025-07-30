variable "default_agent_ami" {
  type    = string
  description = "The AMI ID of the default agent to use as the base image."
}

source "amazon-ebs" "default" {
  ami_name      = "semaphore-agent-variant-{{timestamp}}"
  instance_type = "t2.micro"
  region        = var.aws_region
  source_ami    = var.default_agent_ami
  ssh_username  = "ubuntu"
  # Add other required fields (subnet_id, vpc_id, etc.) as needed
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

build {
  name    = "with-tools"
  sources = ["source.amazon-ebs.default"]

  provisioner "shell" {
    script = "semaphore-agent-ami/with-tools-ultron-bootstrap.sh"
    environment_vars = [
      "WITH_TOOLS=true",
      "ULTRON=false"
    ]
  }
}

build {
  name    = "with-tools-ultron"
  sources = ["source.amazon-ebs.default"]

  provisioner "shell" {
    script = "semaphore-agent-ami/with-tools-ultron-bootstrap.sh"
    environment_vars = [
      "WITH_TOOLS=true",
      "ULTRON=true"
    ]
  }
} 