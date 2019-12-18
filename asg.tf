data "template_file" "user_data" {
  template = "${file("user_data.sh")}"
  vars { }
}

resource "aws_launch_configuration" "web-servers" {
  name_prefix      = "web-server"
  image_id         = "ami-09479453c5cde9639"
  instance_type    = "t2.micro"
  key_name         = "TestKey"

  security_groups  = ["${aws_security_group.public_sg.id}"]
  user_data        = "${data.template_file.user_data.rendered}"  
  
  lifecycle        { create_before_destroy = true }

/*
  user_data = <<USER_DATA
#!/bin/bash
yum update
yum install httpd -y 
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>This is WebServer</h1></html>" > index.html
 USER_DATA
*/

}

resource "aws_autoscaling_group" "web-asg" {
  name = "${aws_launch_configuration.web.name}-asg"

  min_size             = "${var.min_size}"
  desired_capacity     = "${var.desired_capacity}"
  max_size             = "${var.max_size}"

  health_check_type    = "ELB"
  
  target_group_arns    = ["${aws_alb_target_group.alb_target.arn}"]
  launch_configuration = "${aws_launch_configuration.web-servers.name}"
  vpc_zone_identifier  = "${aws_subnet.public_subnet.*public_subnet.id*}"
}