## LAUNCH CONFIGURATION  ####
resource "aws_launch_configuration" "example" {
  image_id        = "ami-d7b9a2b1"
  instance_type   = "${var.instance_type}"
  security_groups = ["${aws_security_group.sg.id}"]

  #user_data       = "${data.template_file.user_data.rendered}"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello Again, File layout example" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

  vars {
    server_port = "${var.server_port}"
    #db_address  = "${data.terraform_remote_state.db.address}"
    #db_port     = "${data.terraform_remote_state.db.port}"
  }
}

## AUTOSCALING GROUP  ####
resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key                 = "Name"
    value               = "${var.cluster_name}-example"
    propagate_at_launch = true
  }
}

### SECURITY GROUP  ####
resource "aws_security_group" "sg" {
  name = "${var.cluster_name}-instance"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_inbound_http" {
  type = "ingress"
  security_group_id =  "${aws_security_group.sg.id}"

  from_port   = "${var.server_port}"
  to_port     = "${var.server_port}"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

data "aws_availability_zones" "all" {}

## ELASTICLOAD BALANCER  ####
resource "aws_elb" "example" {
  name               = "${var.cluster_name}-example"
  availability_zones = ["${data.aws_availability_zones.all.names}"]
  security_groups    = ["${aws_security_group.elb-sg.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 60
    target              = "HTTP:${var.server_port}/"
  }
}

#######################
## SECURITY GROUP  ####
resource "aws_security_group" "elb-sg" {
  name = "${var.cluster_name}-elb"
  tags {
    Name = "${var.cluster_name}-elb"
  }
}

#basically allows you to create flexible modules
# exposing this means to can now create custom rules outside
  # the module.
  # chapter 4 page 97/98 of Terraform Up and Running
resource "aws_security_group_rule" "allow_http_inbound" {
  type = "ingress"
  security_group_id =  "${aws_security_group.elb-sg.id}"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  security_group_id =  "${aws_security_group.elb-sg.id}"

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}



## S3 BUCKET GROUP  ####
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}"
}
