# DevOps AWS-Terraform-Docker Project

### **Project Overview**

This project demonstrates a complete, automated DevOps deployment process for a 2-tier application on **AWS**. It uses **Terraform** for Infrastructure as Code (IaC) to provision cloud resources and **Docker** to containerize the application components. The deployment is orchestrated using Bash scripts, eliminating manual steps. The architecture consists of a public-facing frontend and a private backend with a database, showcasing a secure and scalable design.

This project was developed as part of a one-month training program in DevOps and Cloud Computing, where I gained hands-on experience with Linux commands, Bash scripting, AWS, Terraform, and Docker.

### **Application Details**

The application is a simple feedback form where users can submit details.

  * **Frontend:** Built with HTML, CSS, and JavaScript.
  * **Backend:** A Node.js and Express.js server that handles API requests.
  * **Database:** PostgreSQL to store the feedback data.

The application code is located in the `2-tier-app` folder, which also contains the `docker-compose.yml` file for local testing.

### **Prerequisites**

To run this project, you will need a system running **Ubuntu**. Follow the steps below to set up your environment.

1.  **AWS Account Setup**

      * Create a free-tier account on [AWS](https://aws.amazon.com/free/).
      * Once your account is active, create an IAM user with the following permissions:
          * `AdministratorAccess`
          * `AmazonEC2FullAccess`
          * `AmazonS3FullAccess`
          * `IAMFullAccess`
      * Generate a new set of Access Keys (Access Key ID and Secret Access Key) for this user and save them securely on your local device.

2.  **AWS CLI Installation & Configuration**

      * Install the AWS CLI on your Ubuntu system using the official guide.
          * [**Commands to install AWS CLI**](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
      * Configure your AWS CLI by running the following command in your terminal and providing the access keys you created.
        ```bash
        aws configure
        ```
      * Enter your `AWS Access Key ID`, `AWS Secret Access Key`, `Default region name` (e.g., `us-east-1`), and `Default output format` (e.g., `json`).
      * Verify your configuration is successful by running:
        ```bash
        aws sts get-caller-identity
        ```

3.  **Terraform Installation**

      * Install Terraform on your Ubuntu system by following the official HashiCorp documentation.
          * [**Commands to install Terraform**](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

4.  **Docker Installation**

      * Install Docker on your Ubuntu system.
          * [**Commands to install Docker**](https://docs.docker.com/engine/install/ubuntu/)
      * Create a free account on [Docker Hub](https://hub.docker.com/).
      * 
-----

### **Local Application Run (Optional)**

If you wish to run the 2-tier application locally and push your own images to Docker Hub, follow these steps. Otherwise, you can skip this section and proceed directly to the deployment, as the Terraform scripts are configured to use pre-built images from my Docker Hub.

1.  Navigate into the `2-tier-app` directory.
2.  Run the application locally using Docker Compose:
    ```bash
    cd 2-tier-app
    sudo docker-compose up --build
    ```
3.  Access the application in your browser at `http://localhost:3000`.
4.  Once running, you can create your own Docker images. Tag them with your Docker Hub username and push them to your repository.
      * **Login to Docker Hub:** `docker login`
      * **Tag an image:** `docker tag <local-image-name> <your-dockerhub-username>/<repo-name>:<tag>`
      * **Push an image:** `docker push <your-dockerhub-username>/<repo-name>:<tag>`
5.  **Docker Container & Image Management**
      * **Check running containers:** `sudo docker ps`
      * **Check all containers (including stopped):** `sudo docker ps -a`
      * **Check all images:** `sudo docker images`
6.  To clean up local containers and images:
      * **Stop and remove containers from compose file:** `sudo docker-compose down`
      * **Manually delete a container:** `sudo docker rm -f <container_id>`
      * **Delete an image:** `sudo docker rmi <image_name>`

-----


### **Deployment on AWS**

This section details how to deploy the application on AWS using the Terraform scripts provided in the `Create_Infra` folder.

1.  Navigate into the `Create_Infra` folder.
2.  If you pushed your own images, you must edit the `frontend.sh` and `backend.sh` files inside the `files` folder to use your specific Docker image names.
3.  Execute the main deployment script. This script will initialize Terraform, create an execution plan, and apply it automatically.
    ```bash
    cd Create_Infra
    ./script.sh
    ```
4.  After the script completes, the public URL of the application will be displayed in the terminal.

### **Manual Validation**

After deployment, you can manually verify that the application is running and the database is functional.

1.  **Access the Application:** Open the URL from the terminal in your browser. Enter some data into the form and click submit.
2.  **SSH into Frontend Instance:** Use the public IP of the frontend EC2 instance to SSH in.
    ```bash
    ssh -i "frontend.pem" ubuntu@<frontend-public-ip>
    ```
3.  **SSH into Backend Instance:** From the frontend instance, you can now SSH into the backend instance (which is in the private subnet).
    ```bash
    ssh -i "backend.pem" ubuntu@<backend-private-ip>
    ```
4.  **Check Database:** In the backend instance, check if the Docker containers are running and verify the data was saved.
    ```bash
    sudo docker ps
    sudo docker exec -it db psql -U postgres -d feedbackdb
    ```
    Once in the PostgreSQL shell, run the following query:
    ```sql
    SELECT * FROM feedbacks;
    ```
5.  **Exit and Destroy:** Exit the PostgreSQL shell and both SSH sessions. When you are done, destroy the infrastructure using:
    ```bash
    terraform destroy -auto-approve
    ```

Based on your detailed message, all the challenges and solutions you've described are technically sound and accurately reflect common issues encountered in real-world DevOps deployments. Your understanding of network architecture, Docker networking, Terraform dependencies, and container best practices is solid.

Here is the revised "Challenges & Solutions" section in a more detailed, professional format suitable for your README.md file, incorporating your feedback and ensuring technical accuracy.

***

### **Challenges & Solutions**

This project involved several challenges, which were solved to ensure a stable and functional deployment. These experiences highlight key considerations for designing and implementing secure, multi-tiered applications in a cloud environment.

---

#### **1. Frontend-Backend Communication via a Reverse Proxy**

* **Challenge:** The application worked flawlessly in a local environment where all components were on the same network. However, during cloud deployment, with the frontend in a public subnet and the backend in a private subnet, the frontend couldn't communicate with the backend. The browser, accessing the public frontend URL, was attempting to directly call the backend's private IP, which is not routable from the internet.
* **Solution:** A **reverse proxy** was implemented to fix this. The frontend application's web server was configured to intercept API requests from the browser and securely forward them to the backend's private IP. This allows all communication to happen within the secure Virtual Private Cloud (VPC), with the public-facing frontend acting as a secure gateway for the private backend.

---

#### **2. Database and Backend Communication**

* **Challenge:** The backend container failed to connect to the database container on the same EC2 instance.
* **Solution:** This was resolved by ensuring the PostgreSQL database container's name was identical to the value of the `PGHOST` environment variable in the backend's configuration. In a Docker network, containers communicate with each other using their service names or container names as hostnames. Matching these names directly enabled the backend to find and connect to the database.

---

#### **3. Backend Health Check**

* **Challenge:** A health check (`curl -s --head --fail`) in the deployment script was failing, causing the deployment to stop. This was because the backend was not serving a response on the root (`/`) route.
* **Solution:** The backend's `index.js` file was modified to include a simple health check route at the `/` endpoint. This ensured that a request to the root path would return a valid HTTP response, allowing the `curl` command to succeed and the deployment to continue.

---

#### **4. Docker Networking in a Single Instance**

* **Challenge:** While `docker-compose` on a local machine automatically creates a shared network for services, running containers with individual `docker run` commands on a single EC2 instance does not. Without a shared network, the backend and database containers were isolated and couldn't communicate.
* **Solution:** A custom Docker network was explicitly created on the EC2 instance using the `docker network create` command. Both the backend and database containers were then launched and attached to this custom network, enabling them to communicate seamlessly.

---

#### **5. Security Group Configuration**

* **Challenge:** Improperly configured AWS Security Groups could either expose private resources to the internet or block necessary communication between instances.
* **Solution:** Security Groups were meticulously configured. A Security Group for the frontend instance allowed public traffic (HTTP/HTTPS) from the internet, while a separate Security Group for the backend only allowed inbound traffic from the public subnet cidr in which frontend instance resides. This setup ensures that the backend is securely isolated from all public access.

---

#### **6. Terraform Dependency Management**

* **Challenge:** Defining dependencies incorrectly can lead to **circular dependencies**, where two resources depend on each other, causing the Terraform plan to fail.
* **Solution:** The Terraform configuration was carefully structured to establish a clear, one-way dependency flow. The frontend's dependencies were configured to be on the backend, but not the other way around, preventing the circular loop and ensuring resources were created in the correct order.

---

#### **7. Secure File Transfer to Private Instance via a Bastion Host**

* **Challenge:** As the backend instance was in a private subnet, direct SSH access and file transfer from a local machine were impossible.
* **Solution:** The public-facing frontend instance was leveraged as a **bastion host**. The Terraform provisioner was configured to first SSH into the public instance and then "jump" to the private backend instance, allowing scripts and files to be securely transferred to the backend. This is a standard practice for managing resources in private subnets.

---

#### **8. Dockerfile Environment Variables**

* **Challenge:** The database container failed to initialize on the EC2 instance because environment variables for the database (`POSTGRES_USER`, `POSTGRES_PASSWORD`, etc.) were missing. These variables were previously defined in a `docker-compose.yml` file, which was not used in the cloud deployment.
* **Solution:** The Dockerfile for the database was updated to include the environment variables directly using the `ENV` instruction. This ensured that the values were hardcoded into the image itself, making it self-sufficient when launched with a `docker run` command on the EC2 instance.

---

#### **9. Shebang in Frontend Entrypoint Script**

* **Challenge:** The `frontend.sh` entrypoint script failed to run because its shebang line was `#!/bin/bash`, but the `nginx:alpine` Docker image used as the base does not have Bash installed.
* **Solution:** The shebang was changed from `#!/bin/bash` to `#!/bin/sh`. The `sh` shell is a standard, lightweight shell available in most Linux distributions, including the Alpine image, allowing the script to execute successfully. If Bash was a hard requirement, it would have to be manually installed in the Dockerfile.

---

**Contact**

This project was a part of a one-month training program in DevOps and Cloud at my institute.

* **Name:** Diptesh Singh
* **Institute:** Siksha 'O' Anusandhan University
* **Contact:** +91 7847890495
* **Email:** diptehpiku@gmail.com
