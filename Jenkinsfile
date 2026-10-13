pipeline {
    agent any

    stages {
        stage('Check environment') {
            steps {
                sh 'docker --version'
                sh 'docker compose version'
                sh 'ls -la'
            }
        }
    }
}
