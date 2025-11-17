pipeline {
    agent any

    environment {
        // Docker Hub 이미지 이름
        DOCKER_IMAGE = "jjunch/django"
        // Jenkins에서 만든 Docker Hub credentials ID
        DOCKER_CREDENTIALS = "dockerhub-login"
        // Dockerfile, 소스가 들어있는 폴더 경로
        APP_DIR = "django"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                // django 폴더 안으로 들어가서 Docker build 수행
                dir(APP_DIR) {
                    // Windows라서 bat 사용
                    bat """
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} -t ${DOCKER_IMAGE}:latest .
                    """
                }
            }
        }
        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: DOCKER_CREDENTIALS,
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASS'
                )]) {
                    bat """
                    docker login -u %DOCKERHUB_USER% -p %DOCKERHUB_PASS%
                    docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }
    }
    post {
        always {
            // 디스크 정리를 위해 사용중이지 않은 이미지/컨테이너 제거 (선택)
            bat "docker image prune -f"
        }
    }
}
