pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = 'pyforum'
    }

    stages {
        stage('Prepare') {
            steps {
                withCredentials([file(credentialsId: 'pyforum-env', variable: 'ENV_FILE')]) {
                    sh 'cp -f "$ENV_FILE" .env'
                }
            }
        }

        stage('Build') {
            steps {
                sh 'docker compose build app'
            }
        }

        stage('Lint') {
            steps {
                sh 'docker compose run --rm --no-deps -e BLACK_CACHE_DIR=/tmp app black --check .'
            }
        }
    }
}
