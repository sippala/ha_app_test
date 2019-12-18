data "template_file" "user_data" {
  template = "${file("user_data.sh")}"
  vars { }
}

/*
resource "aws_security_group" "asg-sg" {
  name   = "my-test-sg"
  vpc_id = "${var.vpc_id}"
}

# Ingress Security Port 22
resource "aws_security_group_rule" "http_inbound_access" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = "${aws_security_group.asg-sg.id}"
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

# All OutBound Access
resource "aws_security_group_rule" "all_outbound_access" {
  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.asg-sg.id}"
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
*/
  
resource "aws_launch_configuration" "web-servers" {
  name_prefix      = "web-server"
  image_id         = "ami-09479453c5cde9639"
  instance_type    = "t2.micro"
  key_name         = "TestKey"

  security_groups  = ["${aws_security_group.public_sg.id}"]
  user_data        = "${data.template_file.user_data.rendered}"  
  
  lifecycle        { create_before_destroy = true }

#  user_data = <<USER_DATA
##!/bin/bash
#yum update
#yum install httpd -y 
#service httpd start
#chkconfig httpd on
#cd /var/www/html
#echo "<html><h1>This is WebServer</h1></html>" > index.html
 #USER_DATA

}

resource "aws_autoscaling_group" "web-asg" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size             = "${var.min_size}"
  desired_capacity     = "${var.desired_capacity}"
  max_size             = "${var.max_size}"

  health_check_type    = "EC2"
  
  target_group_arns    = ["${aws_alb_target_group.alb_target.arn}"]
  launch_configuration = "${aws_launch_configuration.web-servers.name}"
  vpc_zone_identifier  = "${aws_subnet.public_subnet.*public_subnet.id*}"
  service_linked_role_arn = "${var.asg_role_arn}" 
}

resource "aws_autoscaling_policy" "web_policy_down" {
  name = "web_policy_down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "web_cpu_alarm_down" {
  alarm_name = "web_cpu_alarm_down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web-asg.name}"
  }

  alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = ["${aws_autoscaling_policy.web_policy_down.arn}"]
}

