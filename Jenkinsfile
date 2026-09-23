pipeline {
    agent any

    environment {
        APP_NAME            = 'fastapi-webapp'
        IMAGE_TAG           = "${env.BUILD_NUMBER}"
        TEST_CONTAINER      = "test-${APP_NAME}-${env.BUILD_NUMBER}"
        APP_PORT            = '8000'
        PATH                = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin:${env.PATH}"

        // AWS ECR Configuration (customize with your AWS account details)
        AWS_REGION          = 'us-east-1'
        AWS_ACCOUNT_ID      = '316388238002'
        ECR_REPO_NAME       = 'fastapi-webapp'
        ECR_REGISTRY        = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_IMAGE_URI       = "${ECR_REGISTRY}/${ECR_REPO_NAME}"

        // Production EC2 Configuration (customize with your EC2 server details)
        EC2_IP              = '34.227.194.70'          // EC2 Public IP or DNS
        EC2_SSH_KEY_CRED_ID = 'ec2-ssh-key'                 // Jenkins SSH Username with private key credential ID
        PROD_CONTAINER      = 'fastapi-webapp-prod'
        PROD_PORT           = '80'
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Unit Tests') {
            steps {
                echo '=== Running Local Unit Tests ==='
                sh '''
                    python3 -m venv .venv || true
                    . .venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    python -m unittest discover -s tests -p "test_*.py"
                '''
            }
        }

        stage('Docker Compose Validation') {
            steps {
                echo '=== Validating Docker Compose Configuration ==='
                sh '''
                    if docker compose version >/dev/null 2>&1; then
                        docker compose config
                    elif command -v docker-compose >/dev/null 2>&1; then
                        docker-compose config
                    else
                        echo "Docker compose not installed, skipping compose validation."
                    fi
                '''
            }
        }

        stage('Docker Build') {
            steps {
                echo "=== Building Docker Image: ${APP_NAME}:${IMAGE_TAG} ==="
                sh """
                    docker build -t ${APP_NAME}:${IMAGE_TAG} -t ${APP_NAME}:latest .
                """
            }
        }

        stage('Container Health Check') {
            steps {
                echo '=== Testing Container Health Endpoint ==='
                sh """
                    # Run container in background
                    docker run -d --name ${TEST_CONTAINER} ${APP_NAME}:${IMAGE_TAG}

                    # Wait and poll health endpoint inside the container
                    echo "Waiting for health endpoint (http://localhost:${APP_PORT}/health)..."
                    success=0
                    for i in \$(seq 1 15); do
                        if docker exec ${TEST_CONTAINER} curl -fsS http://localhost:${APP_PORT}/health; then
                            echo "\\nHealth check passed on attempt \$i!"
                            success=1
                            break
                        fi
                        echo "Waiting for service to be healthy (attempt \$i/15)..."
                        sleep 2
                    done

                    if [ \$success -ne 1 ]; then
                        echo "\\nHealth check failed! Container logs:"
                        docker logs ${TEST_CONTAINER}
                        exit 1
                    fi
                """
            }
            post {
                always {
                    sh """
                        # Cleanup test container
                        docker rm -f ${TEST_CONTAINER} 2>/dev/null || true
                    """
                }
            }
        }

        stage('Push to AWS ECR') {
            steps {
                echo "=== Pushing Docker Image to AWS ECR: ${ECR_IMAGE_URI}:${IMAGE_TAG} ==="
                withCredentials([
                    string(credentialsId: 'AWS_JENKINS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_JENKINS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh """
                        # Authenticate Docker to AWS ECR
                        echo "Authenticating with AWS ECR in region ${AWS_REGION}..."
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                        # Tag image with build number and latest
                        echo "Tagging Docker image for ECR..."
                        docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_IMAGE_URI}:${IMAGE_TAG}
                        docker tag ${APP_NAME}:${IMAGE_TAG} ${ECR_IMAGE_URI}:latest

                        # Push both tags to AWS ECR
                        echo "Pushing ${ECR_IMAGE_URI}:${IMAGE_TAG}..."
                        docker push ${ECR_IMAGE_URI}:${IMAGE_TAG}

                        echo "Pushing ${ECR_IMAGE_URI}:latest..."
                        docker push ${ECR_IMAGE_URI}:latest

                        echo "Successfully pushed images to AWS ECR!"
                    """
                }
            }
            post {
                success {
                    echo '=== Cleaning up local Docker images after successful ECR upload ==='
                    sh """
                        # Remove ECR-tagged local images
                        docker rmi ${ECR_IMAGE_URI}:${IMAGE_TAG} 2>/dev/null || true
                        docker rmi ${ECR_IMAGE_URI}:latest 2>/dev/null || true

                        # Remove local build images
                        docker rmi ${APP_NAME}:${IMAGE_TAG} 2>/dev/null || true
                        docker rmi ${APP_NAME}:latest 2>/dev/null || true

                        # Prune dangling/unused images to free disk space
                        docker image prune -f 2>/dev/null || true
                        echo "Cleanup complete: Local Docker images successfully removed."
                    """
                }
            }
        }

//         stage('Deploy to Production (EC2)') {
//             steps {
//                 echo "=== Deploying to Production EC2 (${EC2_IP}) ==="
//                 withCredentials([sshUserPrivateKey(credentialsId: "${EC2_SSH_KEY_CRED_ID}", keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
//                     sh """
//                         ssh -o StrictHostKeyChecking=no -i \${SSH_KEY} \${SSH_USER}@${EC2_IP} "bash -s" << 'REMOTE_DEPLOY'
//                             set -e
//                             REGION="${AWS_REGION}"
//                             REGISTRY="${ECR_REGISTRY}"
//                             IMAGE="${ECR_IMAGE_URI}:${IMAGE_TAG}"
//                             CONTAINER="${PROD_CONTAINER}"
//                             PORT="${PROD_PORT}"

//                             echo "=========================================================="
//                             echo " Step 1: Authenticate EC2 Docker with AWS ECR"
//                             echo "=========================================================="
//                             aws ecr get-login-password --region "\$REGION" | docker login --username AWS --password-stdin "\$REGISTRY"

//                             echo "=========================================================="
//                             echo " Step 2: Pull new production image (\$IMAGE)"
//                             echo "=========================================================="
//                             docker pull "\$IMAGE"

//                             echo "=========================================================="
//                             echo " Step 3: Stop and remove old container (\$CONTAINER)"
//                             echo "=========================================================="
//                             docker stop "\$CONTAINER" 2>/dev/null || true
//                             docker rm "\$CONTAINER" 2>/dev/null || true

//                             echo "=========================================================="
//                             echo " Step 4: Run new container with restart policy"
//                             echo "=========================================================="
//                             docker run -d \\
//                                 --name "\$CONTAINER" \\
//                                 -p "\$PORT":8000 \\
//                                 --restart unless-stopped \\
//                                 -e ENVIRONMENT=production \\
//                                 "\$IMAGE"

//                             echo "=========================================================="
//                             echo " Step 5: Test health endpoint on production"
//                             echo "=========================================================="
//                             sleep 3
//                             HEALTH_OK=0
//                             for i in \$(seq 1 10); do
//                                 if curl -fsS http://localhost:"\$PORT"/health; then
//                                     echo ""
//                                     echo "Production Health Check: PASSED on attempt \$i!"
//                                     HEALTH_OK=1
//                                     break
//                                 fi
//                                 echo "Waiting for service to be healthy (attempt \$i/10)..."
//                                 sleep 2
//                             done

//                             if [ "\$HEALTH_OK" -ne 1 ]; then
//                                 echo ""
//                                 echo "Production Health Check: FAILED! Container logs:"
//                                 docker logs "\$CONTAINER"
//                                 exit 1
//                             fi

//                             echo "=========================================================="
//                             echo " Step 6: Prune old unused images from EC2"
//                             echo "=========================================================="
//                             docker image prune -af --filter "until=48h" 2>/dev/null || true

//                             echo "=========================================================="
//                             echo " SUCCESS: Deployment Verified on Production!"
//                             echo " Container:  \$CONTAINER"
//                             echo " Image:      \$IMAGE"
//                             echo " Port:       \$PORT"
//                             echo "=========================================================="
// REMOTE_DEPLOY
//                     """
//                 }
//             }
//         }
    }

    post {
        always {
            sh """
                # Guarantee test container is cleaned up
                docker rm -f ${TEST_CONTAINER} 2>/dev/null || true
            """
        }
        success {
            echo """
======================================================================
 PIPELINE SUCCESSFUL
 FastAPI service deployed and healthy!
 Version:    ${IMAGE_TAG}
 Registry:   ${ECR_IMAGE_URI}:${IMAGE_TAG}
======================================================================
            """
        }
        failure {
            echo "Pipeline failed! Check console output for details."
        }
    }
}
