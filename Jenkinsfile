pipeline {
    agent any

    environment {
        APP_NAME        = 'fastapi-webapp'
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        TEST_CONTAINER  = "test-${APP_NAME}-${env.BUILD_NUMBER}"
        APP_PORT        = '8000'
        APP_HOST        = '0.0.0.0'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
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
                sh 'docker compose config'
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

        stage('Push Image') {
            when {
                branch 'main'
            }
            steps {
                echo '=== Ready for Image Push ==='
                // Configure Docker registry credentials in Jenkins credentials store if needed:
                // withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                //     sh """
                //         echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                //         docker tag ${APP_NAME}:${IMAGE_TAG} \$DOCKER_USER/${APP_NAME}:${IMAGE_TAG}
                //         docker tag ${APP_NAME}:latest \$DOCKER_USER/${APP_NAME}:latest
                //         docker push \$DOCKER_USER/${APP_NAME}:${IMAGE_TAG}
                //         docker push \$DOCKER_USER/${APP_NAME}:latest
                //     """
                // }
                sh "echo 'Image ${APP_NAME}:${IMAGE_TAG} built and verified successfully.'"
            }
        }
    }

    post {
        always {
            sh """
                # Clean up dangling images and test containers
                docker rm -f ${TEST_CONTAINER} 2>/dev/null || true
            """
        }
        success {
            echo "Pipeline succeeded! FastAPI service ${APP_NAME}:${IMAGE_TAG} is healthy."
        }
        failure {
            echo "Pipeline failed! Check console output for details."
        }
    }
}

