pipeline {
    agent any

    environment {
        // Docker Hub 이미지 이름 (이미 이렇게 쓰고 있지?)
        DOCKER_IMAGE        = "jjunch/django"

        // Docker Hub credentials ID (Jenkins 자격증명 ID)
        DOCKER_CREDENTIALS  = "dockerhub-login"

        // GitHub credentials ID (앱/매니페스트 레포 둘 다에 쓸 PAT)
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
                // 매니페스트 레포를 워크스페이스 안에 clone
                dir(MANIFEST_REPO_DIR) {
                    // 이미 디렉터리가 있으면 pull, 없으면 clone
                    script {
                        if (fileExists(".git")) {
                            // 기존 clone 이 있으면 최신으로 갱신
                            checkout([
                                $class: 'GitSCM',
                                branches: [[name: '*/main']],
                                userRemoteConfigs: [[
                                    url: MANIFEST_REPO_URL,
                                    credentialsId: GIT_CREDENTIALS
                                ]]
                            ])
                        } else {
                            // 처음일 때 clone
                            checkout([
                                $class: 'GitSCM',
                                branches: [[name: '*/main']],
                                userRemoteConfigs: [[
                                    url: MANIFEST_REPO_URL,
                                    credentialsId: GIT_CREDENTIALS
                                ]]
                            ])
                        }
                    }

                    // PowerShell로 yaml 내부 image 태그를 현재 BUILD_NUMBER로 교체
                    bat """
                    powershell -Command ^
                      "(Get-Content 'django/django-node1-deploy.yml') -replace 'image: jjunch/django:.*', 'image: jjunch/django:${BUILD_NUMBER}' | Set-Content 'django/django-node1-deploy.yml';" ^
                      "(Get-Content 'django/django-node2-deploy.yml') -replace 'image: jjunch/django:.*', 'image: jjunch/django:${BUILD_NUMBER}' | Set-Content 'django/django-node2-deploy.yml';"
                    """

                    // git 커밋 & 푸시
                    bat """
                    git status
                    git config user.name "jjunch"
                    git config user.email "hjc014069@gmail.com"
                    git add django/django-node1-deploy.yml django/django-node2-deploy.yml

                    git commit -m "Update Django image to build ${BUILD_NUMBER}" || echo No changes to commit

                    git push origin HEAD:main
                    """
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
