# Jenkins on Ubuntu EC2

This guide runs Jenkins in a container on an **Ubuntu 22.04 or 24.04** EC2 instance. Jenkins receives Docker and Docker Compose access through the EC2 host's Docker socket, allowing this repository's pipeline to build and launch the bookstore and MySQL containers.

## 1. EC2 security group

Allow only the ports you need:

| Port | Purpose | Recommended source |
| --- | --- | --- |
| 22 | SSH | Your public IP only |
| 8081 | Jenkins UI | Your public IP only |
| 8080 | Bookstore application | Your users or public internet |

Do not expose port 3306: MySQL is private to Docker's internal network.

## 2. Install Docker Engine and Docker Compose on EC2

SSH to the instance and run:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
```

Disconnect and reconnect over SSH so the new group membership takes effect. Verify Docker:

```bash
docker version
docker compose version
docker run --rm hello-world
```

## 3. Get the project and build the Jenkins image

```bash
git clone <YOUR_REPOSITORY_URL> onlinebookstore
cd onlinebookstore
docker build -t onlinebookstore-jenkins:local ./deployment/jenkins-ec2
docker volume create jenkins_home
```

The custom Jenkins image includes the Docker CLI and the Docker Compose v2 plugin. The Jenkins controller does not run its own Docker daemon; it talks to the EC2 host daemon through the mounted socket.

## 4. Start Jenkins

```bash
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  --group-add "$(stat -c '%g' /var/run/docker.sock)" \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  onlinebookstore-jenkins:local
```

Jenkins is mapped to port `8081` so the bookstore application can use port `8080`.

Get the initial administrator password:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open `http://<EC2_PUBLIC_IP>:8081`, complete the Jenkins setup, and install the suggested plugins. Install the **Workspace Cleanup** plugin too; the repository Jenkinsfile uses `cleanWs`.

## 5. Create the pipeline

1. Create a Pipeline job in Jenkins.
2. Select **Pipeline script from SCM**.
3. Select Git and provide the repository URL and branch.
4. Set the script path to `Jenkinsfile`.
5. Save and select **Build Now**.

The pipeline has three stages only: clean the workspace, build the image, and launch the app with MySQL using `docker compose up`.

## 6. Verify the deployment

```bash
docker ps
docker compose -f /var/jenkins_home/workspace/<JENKINS_JOB_NAME>/compose.yaml ps
```

Open `http://<EC2_PUBLIC_IP>:8080` to use the bookstore.

## Security note

Mounting `/var/run/docker.sock` gives Jenkins powerful control over the EC2 host's Docker daemon. This is suitable for a personal or learning environment. For production, run builds on a dedicated Jenkins agent and restrict who can modify pipeline scripts or Jenkins jobs.
