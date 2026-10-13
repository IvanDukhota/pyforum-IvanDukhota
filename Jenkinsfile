pipeline {
    agent any

    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        COMPOSE_PROJECT_NAME = 'pyforum'
        IMAGE = 'lubernen/pyforum'
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

        stage('Test') {
            steps {
                sh 'docker compose run --rm -u root app sh -c "python manage.py makemigrations authentication profiles administration && python manage.py test --noinput"'
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
                    sh '''
                        TAG=$(git rev-parse --short HEAD)
                        echo "$DH_TOKEN" | docker login -u "$DH_USER" --password-stdin
                        docker tag pyforum-app "$IMAGE:$TAG"
                        docker tag pyforum-app "$IMAGE:latest"
                        docker push "$IMAGE:$TAG"
                        docker push "$IMAGE:latest"
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker compose down'
            sh 'rm -f .env'
            sh 'docker logout'
        }
    }
}
