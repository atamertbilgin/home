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
        AWS_PATH = "/usr/local/bin/aws"
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

        stage('Push to ECR') {
            steps {
                // Authenticate Docker with ECR
                sh "${AWS_PATH} ecr get-login-password --region ${AWS_REGION} | ${DOCKER_PATH} login --username AWS --password-stdin ${ECR_URL}"

                def ecrRepoUrl = "https://${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

                // Tag the Docker image for ECR
                sh "${DOCKER_PATH} tag my-docker-image:latest ${ecrRepoUrl}:latest"

                // Push the Docker image to ECR
                sh "${DOCKER_PATH} push ${ecrRepoUrl}:latest"
            }
        }
}

