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
        AWS_ACCESS_KEY_ID = ""
        AWS_SECRET_ACCESS_KEY = ""
    }

    stages {
        stage('Clone GitHub Repo') {
            steps {
                // Clone the GitHub repository to the workspace
                git branch: 'main', credentialsId: GITHUB_CREDENTIALS_ID, url: GITHUB_REPO_URL
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
                    echo "Hello World"
                    '
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
