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
        DOCKER_PATH = "/usr/local/bin/docker"
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
                // Navigate to the directory containing the Dockerfile
                dir('path/to/dockerfile/directory') {
                    // Build the Docker image using the Dockerfile in the current directory
                    sh "${DOCKER_PATH} build -t my-docker-image ."
                }
            }
        }

    }
}
