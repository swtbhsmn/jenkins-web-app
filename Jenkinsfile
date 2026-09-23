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

        // AWS ECS & ALB Configuration
        ECS_CLUSTER_NAME    = 'fastapi-cluster'
        ECS_SERVICE_NAME    = 'fastapi-service'
        ALB_DNS_NAME        = 'fastapi-webapp-alb-1756299987.us-east-1.elb.amazonaws.com'
        ALB_URL             = "http://${ALB_DNS_NAME}"
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
        stage('Deploy to AWS ECS') {
            steps {
                echo "=== Deploying to AWS ECS: ${ECS_SERVICE_NAME} on cluster ${ECS_CLUSTER_NAME} ==="
                withCredentials([
                    string(credentialsId: 'AWS_JENKINS_ACCESS_KEY', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_JENKINS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh """
                        # Trigger ECS rolling deployment
                        echo "Triggering new ECS deployment for service '\${ECS_SERVICE_NAME}' in region \${AWS_REGION}..."
                        aws ecs update-service \\
                            --cluster "\${ECS_CLUSTER_NAME}" \\
                            --service "\${ECS_SERVICE_NAME}" \\
                            --force-new-deployment \\
                            --region "\${AWS_REGION}"

                        # Wait for deployment to reach steady state
                        echo "Waiting for ECS service to reach steady state..."
                        aws ecs wait services-stable \\
                            --cluster "\${ECS_CLUSTER_NAME}" \\
                            --services "\${ECS_SERVICE_NAME}" \\
                            --region "\${AWS_REGION}"

                        echo "ECS service successfully deployed and stable!"

                        # Verify ALB health check endpoint
                        echo "Verifying application health via ALB: \${ALB_URL}/health..."
                        HEALTH_OK=0
                        for i in \$(seq 1 15); do
                            if curl -fsS "\${ALB_URL}/health"; then
                                echo ""
                                echo "ALB Health Check: PASSED on attempt \$i!"
                                HEALTH_OK=1
                                break
                            fi
                            echo "Waiting for service to become healthy (attempt \$i/15)..."
                            sleep 10
                        done

                        if [ "\$HEALTH_OK" -ne 1 ]; then
                            echo ""
                            echo "ALB Health Check: FAILED! Application did not respond with 200 OK."
                            exit 1
                        fi
                    """
                }
            }
        }
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
 FastAPI service deployed to AWS ECS and healthy!
 Version:    ${IMAGE_TAG}
 Registry:   ${ECR_IMAGE_URI}:${IMAGE_TAG}
 URL:        ${ALB_URL}
 Health:     ${ALB_URL}/health
======================================================================
            """
        }
        failure {
            echo "Pipeline failed! Check console output for details."
        }
    }
}
