# Create VPC and assign base address
resource "aws_vpc" "platform" {
	cidr_block  = "${var.vpc_network_prefix}.0.0/16"
	tags {
		Name        = "${var.vpc_platform_name}"
		Terraform   = "true"
	}
}
resource "aws_internet_gateway" "platform" {
    vpc_id = "${aws_vpc.platform.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.platform.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.platform.id}"
}
