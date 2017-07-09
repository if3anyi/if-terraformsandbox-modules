user_data = <<-EOF
            #!/bin/bash
            echo "Hello Again, File layout example" > index.html
            nohup busybox httpd -f -p ${server_port} &
            EOF
