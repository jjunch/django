pipeline {
    agent any

    environment {
        // Docker Hub 이미지 이름
        DOCKER_IMAGE        = "jjunch/django"

        // Jenkins에 등록한 Docker Hub credentials ID
        DOCKER_CREDENTIALS  = "dockerhub-login"

        // Jenkins에 등록한 GitHub PAT credentials ID
        GIT_CREDENTIALS     = "github-token"

        // 매니페스트 레포 정보
        MANIFEST_REPO_URL   = "https://github.com/jjunch/django-k8s-manifests.git"
        MANIFEST_REPO_DIR   = "django-k8s-manifests"
    }

    stages {
        stage('Checkout') {
            steps {
                // 앱 레포(django) 체크아웃
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                // Windows 환경이므로 bat 사용
                bat """
                docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} -t ${DOCKER_IMAGE}:latest .
                """
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

        stage('Update Manifests Repo') {
            steps {
                dir(MANIFEST_REPO_DIR) {
                    // 매니페스트 레포 체크아웃 (있으면 pull, 없으면 clone)
                    script {
                        checkout([
                            $class: 'GitSCM',
                            branches: [[name: '*/main']],
                            userRemoteConfigs: [[
                                url: MANIFEST_REPO_URL,
                                credentialsId: GIT_CREDENTIALS
                            ]]
                        ])
                    }
                    
                    bat """
                    powershell -Command ^
                      "(Get-Content 'django/django-deploy.yml') -replace 'image: jjunch/django:.*', 'image: jjunch/django:${BUILD_NUMBER}' | Set-Content 'django/django-deploy.yml';"
                    """

                    // git 커밋 & 푸시
                    withCredentials([usernamePassword(
                        credentialsId: GIT_CREDENTIALS,
                        usernameVariable: 'GIT_USER',
                        passwordVariable: 'GIT_TOKEN'
                    )]) {
                        bat """
                        git status
                        git config user.name "jjunch"
                        git config user.email "hjc014069@gmail.com"
                        git add django/django-deploy.yml

                        git commit -m "Update Django image to build ${BUILD_NUMBER}" || echo No changes to commit

                        git remote set-url origin https://%GIT_USER%:%GIT_TOKEN%@github.com/jjunch/django-k8s-manifests.git
                        git push origin HEAD:main
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            // 선택: 로컬 도커 이미지 캐시 정리
            bat "docker image prune -f"
        }
    }
}
