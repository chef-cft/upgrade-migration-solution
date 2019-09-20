/////////////////////////
// Automate Load Balancing
resource "aws_alb" "automate_lb" {
  name               = "${var.tag_name}-${random_id.random.hex}-automate-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.base_linux.id, aws_security_group.chef_automate.id]
  subnets            = aws_subnet.default.*.id

  tags = {
    X-Dept    = var.tag_dept
    X-Project = var.tag_project
    X-Contact = var.tag_contact
  }
}

data "aws_acm_certificate" "automate_lb" {
  domain      = "success.chef.co"
  types       = ["AMAZON_ISSUED"]
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "aws_alb_target_group" "automate_tg" {
  name     = "${var.tag_name}-${random_id.random.hex}-automate-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.default.id
}

resource "aws_alb_target_group_attachment" "automate_tg_attachment" {
  target_group_arn = aws_alb_target_group.automate_tg.arn
  target_id        = aws_instance.chef_automate.id
  port             = 443
}

resource "aws_alb_listener" "automate_lb_listener_443" {
  load_balancer_arn = aws_alb.automate_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.automate_lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.automate_tg.arn
  }
}

resource "aws_alb_listener" "automate_lb_listener_80" {
  load_balancer_arn = aws_alb.automate_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

