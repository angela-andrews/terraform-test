provider "aws"{
    region = "us-east-1"
}

resource "aws_instance" "book_example" {
    ami             = "ami-40d28157"
    instance_type   = "t2.micro"
    vpc_security_group_ids = ["${aws_security_group.instance.id}"]

    user_data = <<-EOF
                #!/bin/bash
                echo "Hey Ya'll! I'm up in this jawn" > index.html
                nohup busybox httpd -f -p 8080 & 
                EOF


    tags {
    Name            = "terraform-book-example"
    }
}



resource "aws_security_group" "instance" {
    name            = "terraform-book-example-instance"

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = [ "0.0.0.0/0"]
    }
}