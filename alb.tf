resource "aws_security_group" "alb_sg" {
  name        = "ALB HTTP/S"
  description = "Allow HTTP/HTTPS traffic to instances"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "alb" {
  name            = "${var.alb_name}"
  subnets         = ["${aws_subnet.public_subnet*.id}"]
  security_groups = ["${aws_security_group.alb_sg.id}"]
  internal        = false
}

resource "aws_alb_target_group" "alb_target_group" {  
  name     = "${var.target_group_name}"  
  port     = "${var.svc_port}"  
  protocol = "HTTP"  
  vpc_id   = "${aws_vpc.main.id}"   
  
  health_check {    
    healthy_threshold   = 3    
    unhealthy_threshold = 10    
    timeout             = 5    
    interval            = 10    
    path                = "${var.target_group_path}"    
    port                = "${var.target_group_port}"  
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "${var.alb_listener_port}"
  protocol          = "${var.alb_listener_protocol}"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target.arn}"
    type             = "forward"
  }
}
