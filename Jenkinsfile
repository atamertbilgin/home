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
                        K8S_PUBLIC_IP2 = sh(returnStdout: true, script: "${TERRAFORM_PATH} output k8s_public_ip2").trim()
                    }
                }
            }
        }

        stage('Installations on Ubuntu') {
            steps {
                // Sleep for 20 seconds
                sh """${SLEEP_PATH} 300"""

                // SSH into the EC2 instance and execute commands remotely
                sh """
                    ${SSH_PATH} -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem ubuntu@${K8S_PUBLIC_IP} '
                    sudo apt update;
                    sudo apt install python3 python3-pip;
                    sudo pip3 install awscli;
                    sudo apt install git;
                    aws configure set aws_access_key_id AKIAY4U5YMQIZRSTQZUK;
                    aws configure set aws_secret_access_key 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;
                    aws configure set default.region us-east-1
                    git clone https://github.com/atamertbilgin/home.git;
                    cd ~/home;
                    chmod +x setup-k8s-script.sh;
                    ./setup-k8s-script.sh;
                    kubectl apply -f deployment.yaml
                    '
                """
            }
        }

        // stage('Building the Image and Pushing to ECR') {
        //     steps {

        //         // SSH into the EC2 instance and execute commands remotely
        //         sh """
        //             ${SSH_PATH} -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem ubuntu@${K8S_PUBLIC_IP} '
        //             kubectl apply -f deployment.yaml
        //             '
        //         """
        //     }
        // }

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