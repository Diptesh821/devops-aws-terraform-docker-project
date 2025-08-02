output "Frontend-Public-Ip"{
  value = aws_instance.frontend.public_ip
}

output "Frontend-Private-Ip"{
  value = aws_instance.frontend.private_ip
}

output "Backend-Private-Ip"{
 value = aws_instance.backend.private_ip
}

output "Frontend-application-url" {
 description = "Access URL for the frontend form application"
 value= "http://${aws_instance.frontend.public_ip}:${var.frontend_port}"
}
