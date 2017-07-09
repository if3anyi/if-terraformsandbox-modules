output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}


output "asg_name" {
  value = "${aws_autoscaling_group.example.name}"
}

# exposing this means to can now create custom rules outside
  # the module.
  # chapter 4 page 97/98 of Terraform Up and Running
output "elb_security_group_id" {
  value = "${aws_security_group.elb-sg.id}"
}
