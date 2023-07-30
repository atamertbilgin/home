pipeline {
    agent any

    environment {
        // Set your GitHub repository URL and AWS ECR repository name
        GITHUB_REPO_URL = "https://github.com/atamertbilgin/home.git"
        ECR_REPO_NAME = "abilgin-portfolio-image"
        // Set your AWS region and ECR URL
        AWS_REGION = "us-east-1"
        AWS_ACCOUNT_ID = "611289949201" // Replace with your AWS account ID
        ECR_URL = "https://${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
        GITHUB_CREDENTIALS_ID = 'github' // Replace with your GitHub credentials ID
        DOCKER_PATH = "/usr/local/bin/docker"
        AWS_PATH = "/usr/local/bin/aws"
        TERRAFORM_PATH = "/opt/homebrew/bin/terraform"
        SSH_PATH = "/usr/bin/ssh"
        SLEEP_PATH = "/bin/sleep"
    }

    stages {
        stage('Clone GitHub Repo') {
            steps {
                // Clone the GitHub repository to the workspace
                git branch: 'main', credentialsId: GITHUB_CREDENTIALS_ID, url: GITHUB_REPO_URL
            }
        }

        stage('Build Docker Image') {
            steps {
                // Navigate to the Jenkins workspace where the repository was cloned
                dir("${WORKSPACE}") {
                    // Build the Docker image using the Dockerfile in the workspace root directory
                    sh "${DOCKER_PATH} build -t my-docker-image ."
                }
            }
        }

        stage('Create ECR Repository') {
            steps {
                // Check if the ECR repository already exists
                script {
                    def ecrRepoExists = sh(
                        script: "${AWS_PATH} ecr describe-repositories --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}",
                        returnStatus: true
                    )
                    if (ecrRepoExists == 0) {
                        echo "ECR repository already exists. Skipping creation."
                    } else {
                        // Use the AWS CLI to create the ECR repository
                        sh "${AWS_PATH} ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}"
                    }
                }
            }
        }

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    // Authenticate Docker with ECR
                    sh "${AWS_PATH} ecr get-login-password --region ${AWS_REGION} | ${DOCKER_PATH} login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    // Tag the Docker image with ECR repository URI
                    def ecrRepoUriWithTag = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"
                    sh "${DOCKER_PATH} tag my-docker-image ${ecrRepoUriWithTag}"

                    // Push the Docker image to ECR
                    sh "${DOCKER_PATH} push ${ecrRepoUriWithTag}"
                }
            }
        }


        stage('Terraform Init') {
            steps {
                script {
                    // Change directory to the workspace where main.tf is present
                    dir("${WORKSPACE}") {
                        // Execute terraform init using the provided binary path
                        sh "${TERRAFORM_PATH} init"
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    // Change directory to the workspace where main.tf is present
                    dir("${WORKSPACE}") {
                        // Execute terraform plan and save the output to a plan file
                        sh "${TERRAFORM_PATH} plan -out=tfplan"
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    // Change directory to the workspace where main.tf is present
                    dir("${WORKSPACE}") {
                        // Execute terraform apply using the plan file generated from the plan stage
                        sh "${TERRAFORM_PATH} apply tfplan"

                        K8S_PUBLIC_IP = sh(returnStdout: true, script: "${TERRAFORM_PATH} output k8s_public_ip").trim()
                    }
                }
            }
        }

        stage('Connect to EC2 Instance') {
            steps {
                // Sleep for 20 seconds
                sh """${SLEEP_PATH} 20"""

                // SSH into the EC2 instance and execute commands remotely
                sh """
                    ${SSH_PATH} -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem ec2-user@${K8S_PUBLIC_IP} '
                    sudo yum update -y;
                    sudo dnf update;
                    sudo dnf install -y docker;
                    sudo systemctl start docker;
                    sudo systemctl enable docker;
                    sudo usermod -aG docker \$USER;
                    newgrp docker;
                    sudo yum install git -y;
                    sudo usermod -aG docker \$USER && newgrp docker;
                    curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl";
                    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl;
                    chmod +x kubectl;
                    mkdir -p ~/.local/bin;
                    mv ./kubectl ~/.local/bin/kubectl;
                    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64;
                    sudo install minikube-linux-amd64 /usr/local/bin/minikube;
                    sudo usermod -aG docker \$USER && newgrp docker'
                """
            }
        }

        stage('Creating the Deployment.yaml for k8s') {
            steps {
                script {
                    def ecrRepoUriWithTag = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"
                    sh """echo 'apiVersion: apps/v1
kind: Deployment
metadata:
name: atamert-bilgin-portfolio
labels:
    app: my-web-app
spec:
replicas: 2  # Number of desired replicas
selector:
    matchLabels:
    app: my-web-app
template:
    metadata:
    labels:
        app: my-web-app
    spec:
    containers:
        - name: abilgin-portfolio-image
        image: ${ecrRepoUriWithTag}
        ports:
            - containerPort: 80  # Expose the container port your application listens on
---
apiVersion: v1
kind: Service
metadata:
name: your-service-name
spec:
type: LoadBalancer
selector:
    app: my-web-app
ports:
    - protocol: TCP
    port: 80
    targetPort: 80
    ' > deployment.yaml"""
                            }
                        }
                    }

        stage('Create minikube') {
            steps {
                // Sleep for 20 seconds
                sh """${SLEEP_PATH} 180"""

                // SSH into the EC2 instance and execute commands remotely
                sh """
                    ${SSH_PATH} -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem ec2-user@${K8S_PUBLIC_IP} '
                    sudo cd ~;
                    scp -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem /Users/atamertbilgin/.jenkins/workspace/portfolio/deployment.yaml .;
                    minikube start;
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 611289949201.dkr.ecr.us-east-1.amazonaws.com'
                """
            }
        }


        stage('Terraform Destroy (Manual Approval)') {
            steps {
                script {
                    // Change directory to the workspace where main.tf is present
                    dir("${WORKSPACE}") {
                        // Execute terraform destroy and save the output to a plan file
                        sh "${TERRAFORM_PATH} destroy -auto-approve"
                    }
                }
            }

            // Adding manual approval input for Terraform destroy step
            input {
                message "This will destroy the infrastructure. Are you sure you want to continue?"
                ok "Yes, I'm sure."
            }
        }
    }
}
