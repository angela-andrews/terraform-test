provider "aws" {
  region = "us-east-1"
}

resource "aws_launch_configuration" "example" {
  ami             = "ami-40d28157"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.instance.id}"]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hey Ya'll! I'm up in this jawn" > index.html
                nohup busybox httpd -f -p "${var.server_port}" & 
                EOF

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name = "terraform-book-example"
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

// I added this variable since the elb port was duplicated
variable "elb_port" {
  description = "The port the elb will use for HTTP traffic"
  default     = 80
}

resource "aws_security_group" "instance" {
  name = "terraform-book-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}

resource "aws_autoscaling_group" "example" {
      launch_configuration = "${aws_launch_configuration.example.id}"  
      availability_zones = ["${data.aws_availability_zones.all.names}"]

  //resource variables must be three parts: TYPE.NAME.ATTR 
  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
    name               = "terraform-asg-example"  
    availability_zones = ["${data.aws_availability_zones.all.names}"]  
    security_groups    = ["${aws_security_group.elb.id}"]  
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
        interval            = 30    
        target              = "HTTP:${var.server_port}/" 
 }
    }

resource "aws_security_group" "elb" {
    name = "terraform-exmaple-elb"

    ingress {
        from_port = "${var.elb_port}"
        to_port   = "${var.elb_port}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}