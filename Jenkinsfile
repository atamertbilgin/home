pipeline {
    agent any
    
    environment {
        // Set your GitHub repository URL and AWS ECR repository name
        GITHUB_REPO_URL = "https://github.com/atamertbilgin/home.git"
        ECR_REPO_NAME = "abilgin-portfolio-image"
        // Set your AWS region and ECR URL
        AWS_REGION = "us-east-1"
        ECR_URL = "your-aws-account-id.dkr.ecr.your-aws-region.amazonaws.com"
        GITHUB_CREDENTIALS_ID = 'github'
    }
    
    stages {
        stage('Clone GitHub Repo') {
            steps {
                // Clone the GitHub repository to the workspace
                git branch: 'main', url: GITHUB_REPO_URL
            }
        }
        
        stage('Create ECR Repo') {
            steps {
                // Use AWS CLI to create the ECR repository and capture the repository URL
                script {
                    ECR_REPO_URL = sh(
                        script: "aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                // Build the Docker image and tag it with the ECR URL
                script {
                    docker.withRegistry(ECR_REPO_URL, 'ecr-credentials') {
                        def imageName = "${ECR_REPO_NAME}:latest"
                        docker.build(imageName, '.').push()
                    }
                }
            }
        }
    }
}
