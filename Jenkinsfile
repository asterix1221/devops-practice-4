pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        IMAGE = "devops-pr4-flask:${BUILD_NUMBER}"
    }

    stages {
        stage('Build Docker image') {
            steps {
                sh 'docker version'
                sh 'docker build --pull --tag "$IMAGE" .'
            }
        }

        stage('Unit tests') {
            steps {
                sh 'docker run --rm --entrypoint python "$IMAGE" -m unittest discover -s tests -v'
            }
        }

        stage('Test running container') {
            steps {
                sh '''
                    set -eu
                    docker rm -f pr4-flask-test >/dev/null 2>&1 || true
                    docker run -d --name pr4-flask-test -p 18081:5000 "$IMAGE"
                    for attempt in $(seq 1 30); do
                        if response="$(curl -fsS http://docker:18081/health 2>/dev/null)"; then
                            if printf '%s\\n' "$response" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"'; then
                                docker rm -f pr4-flask-test >/dev/null
                                echo 'Container smoke test passed.'
                                exit 0
                            fi
                        fi
                        sleep 2
                    done
                    docker logs pr4-flask-test || true
                    docker rm -f pr4-flask-test >/dev/null 2>&1 || true
                    echo 'Container did not pass the /health check.' >&2
                    exit 1
                '''
            }
        }

        stage('Deploy to Staging') {
            steps {
                sh '''
                    set -eu
                    docker rm -f pr4-flask-staging >/dev/null 2>&1 || true
                    docker run -d --name pr4-flask-staging -p 18080:5000 "$IMAGE"
                    for attempt in $(seq 1 30); do
                        if response="$(curl -fsS http://docker:18080/health 2>/dev/null)"; then
                            if printf '%s\\n' "$response" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"'; then
                                echo 'Staging /health check passed.'
                                exit 0
                            fi
                        fi
                        sleep 2
                    done
                    docker logs pr4-flask-staging || true
                    echo 'Staging deployment failed its /health check.' >&2
                    exit 1
                '''
            }
        }

        stage('Approve Production') {
            steps {
                input message: 'Staging checks passed. Deploy this image to production?', ok: 'Deploy to production'
            }
        }

        stage('Deploy to Production') {
            steps {
                sh '''
                    set -eu
                    docker rm -f pr4-flask-production >/dev/null 2>&1 || true
                    docker run -d --name pr4-flask-production -p 18082:5000 "$IMAGE"
                    for attempt in $(seq 1 30); do
                        if response="$(curl -fsS http://docker:18082/health 2>/dev/null)"; then
                            if printf '%s\\n' "$response" | grep -Eq '"status"[[:space:]]*:[[:space:]]*"ok"'; then
                                echo 'Production /health check passed.'
                                exit 0
                            fi
                        fi
                        sleep 2
                    done
                    docker logs pr4-flask-production || true
                    echo 'Production deployment failed its /health check.' >&2
                    exit 1
                '''
            }
        }
    }

    post {
        always {
            sh 'docker rm -f pr4-flask-test >/dev/null 2>&1 || true'
            echo 'Pipeline finished. Review Console Output and stage results.'
        }
        success {
            echo 'CI/CD pipeline completed successfully.'
        }
        failure {
            echo 'CI/CD pipeline failed. Check Console Output.'
        }
    }
}
