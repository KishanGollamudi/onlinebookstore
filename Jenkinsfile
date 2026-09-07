pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    parameters {
        booleanParam(
            name: 'RESET_DATABASE',
            defaultValue: false,
            description: 'Delete the MySQL container and volume so mysql-init.sql runs again. Use only when database reset is required.'
        )
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

                    echo "=== Checking required files ==="
                    test -f compose.yaml
                    test -f setup/mysql-init.sql

                    echo "compose.yaml found."
                    echo "setup/mysql-init.sql found."

                    echo "=== MySQL initialization script ==="
                    grep -E "CREATE TABLE|INSERT IGNORE" setup/mysql-init.sql
                '''
            }
        }

        stage('Reset Database') {
            when {
                expression {
                    return params.RESET_DATABASE
                }
            }

            steps {
                sh '''
                    set -e

                    echo "=== RESET_DATABASE=true ==="
                    echo "Stopping and removing current Compose containers..."

                    docker compose down

                    echo "Removing MySQL volume..."

                    docker volume rm test-job_mysql_data || true

                    echo "Database reset completed."
                '''
            }
        }

        stage('Docker Image Build') {
            steps {
                sh '''
                    set -e

                    echo "=== Building application image ==="

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

                    echo "=== Waiting for MySQL ==="

                    docker compose exec -T db \
                        mysql \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "USE onlinebookstore; SHOW TABLES;"

                    echo "=== Checking required tables ==="

                    TABLE_COUNT=$(docker compose exec -T db \
                        mysql \
                        -N \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='onlinebookstore' AND table_name IN ('books','users');")

                    echo "Required table count: ${TABLE_COUNT}"

                    if [ "${TABLE_COUNT}" -ne 2 ]; then
                        echo "ERROR: Required database tables were not created."
                        exit 1
                    fi

                    echo "Database tables verified successfully."

                    echo "=== Checking sample data ==="

                    BOOK_COUNT=$(docker compose exec -T db \
                        mysql \
                        -N \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM onlinebookstore.books;")

                    USER_COUNT=$(docker compose exec -T db \
                        mysql \
                        -N \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM onlinebookstore.users;")

                    echo "Books: ${BOOK_COUNT}"
                    echo "Users: ${USER_COUNT}"

                    echo "=== Database verification completed successfully ==="
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
