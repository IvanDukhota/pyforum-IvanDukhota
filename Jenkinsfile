pipeline {
    agent any

    triggers {
        pollSCM('H/5 * * * *')
    }

    parameters {
        string(name: 'KEEP_TAGS', defaultValue: '10', description: 'How many recent SHA tags to keep on Docker Hub')
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
                sh '''
                    docker compose run --rm -T -u root app sh -c "
                        pip install --no-cache-dir -q coverage==7.17.0 1>&2 &&
                        python manage.py makemigrations authentication profiles administration 1>&2 &&
                        coverage run --source=. --omit='*/migrations/*' manage.py test --noinput 1>&2 &&
                        coverage xml -o -
                    " > coverage.xml
                '''
            }
        }

        stage('Sonar') {
            steps {
                withCredentials([string(credentialsId: 'sonarcloud', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        docker run --rm \
                            -u "$(id -u):$(id -g)" \
                            -e SONAR_TOKEN \
                            -e SONAR_USER_HOME=/usr/src/.sonar-cache \
                            -v "$PWD:/usr/src" \
                            sonarsource/sonar-scanner-cli:12.3.1.4302_8.3.1 \
                            -Dsonar.working.directory=/usr/src/.scannerwork
                    '''
                }
            }
        }

        stage('Scan') {
            steps {
                sh '''
                    TRIVY="docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/trivy \
                        aquasec/trivy:0.76.1 image --no-progress"

                    $TRIVY --severity HIGH,CRITICAL pyforum-app > trivy-report.txt
                    $TRIVY --severity CRITICAL --exit-code 1 --skip-db-update pyforum-app
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
                }
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

        stage('Cleanup') {
            steps {
                catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DH_USER', passwordVariable: 'DH_TOKEN')]) {
                        sh '''#!/bin/bash
                            set -eo pipefail
                            case "$KEEP_TAGS" in
                                ''|*[!0-9]*|0) echo "KEEP_TAGS must be a positive number"; exit 1 ;;
                            esac

                            HUB=https://hub.docker.com/v2
                            JWT=$(jq -n '{identifier: env.DH_USER, secret: env.DH_TOKEN}' \
                                | curl -sf -H 'Content-Type: application/json' -d @- "$HUB/auth/token" \
                                | jq -r .access_token)
                            [ -n "$JWT" ] && [ "$JWT" != null ] || { echo "Docker Hub login failed"; exit 1; }

                            curl -sf -H "Authorization: Bearer $JWT" \
                                "$HUB/namespaces/${IMAGE%/*}/repositories/${IMAGE#*/}/tags?page_size=100" \
                            | jq -r --argjson keep "$KEEP_TAGS" \
                                '.results | map(select(.name != "latest")) | sort_by(.last_updated) | reverse | .[$keep:][] | .name' \
                            | while read -r TAG; do
                                echo "Deleting $IMAGE:$TAG"
                                curl -sf -X DELETE -H "Authorization: Bearer $JWT" "$HUB/repositories/$IMAGE/tags/$TAG/"
                            done
                        '''
                    }
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
