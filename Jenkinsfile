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

        // stage('Build Docker Image') {
        //     steps {
        //         // Navigate to the Jenkins workspace where the repository was cloned
        //         dir("${WORKSPACE}") {
        //             // Build the Docker image using the Dockerfile in the workspace root directory
        //             sh "${DOCKER_PATH} build -t my-docker-image ."
        //         }
        //     }
        // }

        // stage('Create ECR Repository') {
        //     steps {
        //         // Check if the ECR repository already exists
        //         script {
        //             def ecrRepoExists = sh(
        //                 script: "${AWS_PATH} ecr describe-repositories --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}",
        //                 returnStatus: true
        //             )
        //             if (ecrRepoExists == 0) {
        //                 echo "ECR repository already exists. Skipping creation."
        //             } else {
        //                 // Use the AWS CLI to create the ECR repository
        //                 sh "${AWS_PATH} ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}"
        //             }
        //         }
        //     }
        // }

        // stage('Push Docker Image to ECR') {
        //     steps {
        //         script {
        //             // Authenticate Docker with ECR
        //             sh "${AWS_PATH} ecr get-login-password --region ${AWS_REGION} | ${DOCKER_PATH} login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

        //             // Tag the Docker image with ECR repository URI
        //             def ecrRepoUriWithTag = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest"
        //             sh "${DOCKER_PATH} tag my-docker-image ${ecrRepoUriWithTag}"

        //             // Push the Docker image to ECR
        //             sh "${DOCKER_PATH} push ${ecrRepoUriWithTag}"
        //         }
        //     }
        // }


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
                    sudo usermod -aG docker \$USER && newgrp docker;
                    cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
        [kubernetes]
        name=Kubernetes
        baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
        enabled=1
        gpgcheck=1
        gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
        exclude=kubelet kubeadm kubectl
        EOF
                    sudo setenforce 0;
                    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config;
                    sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes;
                    sudo systemctl enable --now kubelet'
                """
            }
        }



        stage('Transfer Deployment YAML') {
            steps {
                script {
                    // Transfer the deployment.yaml file to the EC2 instance using SCP
                    sh """
                        scp -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem \
                        /Users/atamertbilgin/.jenkins/workspace/portfolio/deployment.yaml ec2-user@${K8S_PUBLIC_IP}:~/deployment.yaml
                    """
                }
            }
        }


        stage('Delay stage') {
            steps {
                // Sleep for 20 seconds
                sh """${SLEEP_PATH} 180"""

                // SSH into the EC2 instance and execute commands remotely
                sh """
                    ${SSH_PATH} -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem ec2-user@${K8S_PUBLIC_IP} '
                    sudo cd ~;
                    scp -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem /Users/atamertbilgin/.jenkins/workspace/portfolio/deployment.yaml .;
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 611289949201.dkr.ecr.us-east-1.amazonaws.com'
                """
            }
        }
    
        stage('Docker login and regcred creation') {
            steps {
                // SSH into the EC2 instance and execute commands remotely
                sh """
                    ${SSH_PATH} -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem ec2-user@${K8S_PUBLIC_IP} '
                    docker_ecr_login=\$(aws ecr get-login-password --region us-east-1 | base64 -w0);
                    echo -n "\$docker_ecr_login" | base64 -d | docker login --username AWS --password-stdin 611289949201.dkr.ecr.us-east-1.amazonaws.com;
                    kubectl create secret docker-registry regcred \\
                        --docker-server=611289949201.dkr.ecr.us-east-1.amazonaws.com \\
                        --docker-username=AWS \\
                        --docker-password=\$(aws ecr get-login-password --region us-east-1) \\
                        --docker-email=atamertbilgin@gmail.com
                    '
                """
            }
        }

        stage('Deployment') {
            steps {
                // SSH into the EC2 instance and execute commands remotely
                sh """
                    ${SSH_PATH} -o StrictHostKeyChecking=no -i /Users/atamertbilgin/.ssh/first-key.pem ec2-user@${K8S_PUBLIC_IP} '
                    sudo cd ~;
                    git clone https://github.com/atamertbilgin/home.git;
                    cd home;
                    docker build -t my-docker-image .;
                    \$(aws ecr get-login --no-include-email --region us-east-1);
                    aws ecr create-repository --repository-name abilgin-portfolio-image;
                    docker tag my-docker-image:latest 611289949201.dkr.ecr.us-east-1.amazonaws.com/abilgin-portfolio-image:latest;
                    docker push 611289949201.dkr.ecr.us-east-1.amazonaws.com/abilgin-portfolio-image:latest;'
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
