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
                git branch: 'main', credentialsId: GITHUB_CREDENTIALS_ID, url: GITHUB_REPO_URL
            }
        }
        
        stage('Create ECR Repo') {
            steps {
                // Use 'withCredentials' to provide AWS credentials to the 'sh' step
                withCredentials([
                    awsAccessKey(credentialsId: 'aws', variable: 'AWS_ACCESS_KEY_ID'),
                    awsSecretKey(credentialsId: 'aws', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    // Use AWS CLI to create the ECR repository and capture the repository URL
                    script {
                        ECR_REPO_URL = sh(
                            script: "AWS_ACCESS_KEY_ID=${env.AWS_ACCESS_KEY_ID} AWS_SECRET_ACCESS_KEY=${env.AWS_SECRET_ACCESS_KEY} aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}",
                            returnStdout: true
                        ).trim()
                    }
                }
            }
        }
    }
}
