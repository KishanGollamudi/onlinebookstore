pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    environment {
        APP_IMAGE = 'onlinebookstore'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs(
                    deleteDirs: true,
                    disableDeferredWipeout: true
                )

                checkout scm
            }
        }

        stage('Verify Deployment Files') {
            steps {
                sh '''
                    set -e

                    echo "=== Workspace ==="
                    pwd

                    echo "=== Files ==="
                    ls -la

                    echo "=== Setup directory ==="
                    ls -la setup

                    echo "=== Checking MySQL initialization script ==="
                    test -f setup/mysql-init.sql

                    echo "mysql-init.sql found successfully."

                    echo "=== Checking Compose file ==="
                    test -f compose.yaml

                    echo "compose.yaml found successfully."
                '''
            }
        }

        stage('Docker Image Build') {
            steps {
                sh '''
                    set -e

                    docker build --pull \
                        -t "${APP_IMAGE}:${IMAGE_TAG}" .
                '''
            }
        }

        stage('Launch Application') {
            steps {
                sh '''
                    set -e

                    echo "=== Starting application ==="

                    IMAGE_TAG="${IMAGE_TAG}" \
                    docker compose up -d \
                        --no-build \
                        --remove-orphans

                    echo "=== Container status ==="

                    docker compose ps
                '''
            }
        }

        stage('Verify Database') {
            steps {
                sh '''
                    set -e

                    echo "=== Waiting for database ==="

                    docker compose exec -T db \
                        mysql \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "USE onlinebookstore; SHOW TABLES;"

                    echo "=== Database verification completed ==="
                '''
            }
        }
    }

    post {
        success {
            echo 'Deployment completed successfully.'
        }

        failure {
            echo 'Deployment failed. Check the stage output above.'
        }
    }
}
