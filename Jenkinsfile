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
            description: 'Reset the MySQL database and recreate it from mysql-init.sql. Use only when required.'
        )
    }

    environment {
        APP_IMAGE = 'onlinebookstore'
        DB_IMAGE = 'onlinebookstore-mysql'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DB_TAG = "${BUILD_NUMBER}"
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
                    test -f Dockerfile
                    test -f compose.yaml
                    test -f setup/mysql-init.sql
                    test -f deployment/mysql/Dockerfile

                    echo "All required files found."

                    echo "=== MySQL Dockerfile ==="
                    cat deployment/mysql/Dockerfile

                    echo "=== MySQL initialization SQL ==="
                    grep -E "CREATE TABLE|INSERT IGNORE" setup/mysql-init.sql
                '''
            }
        }

        stage('Build MySQL Image') {
            steps {
                sh '''
                    set -e

                    echo "=== Building custom MySQL image ==="

                    docker build \
                        --pull \
                        -t "${DB_IMAGE}:${DB_TAG}" \
                        -f deployment/mysql/Dockerfile \
                        .

                    echo "=== MySQL image built ==="

                    docker images "${DB_IMAGE}:${DB_TAG}"
                '''
            }
        }

        stage('Docker Image Build') {
            steps {
                sh '''
                    set -e

                    echo "=== Building application image ==="

                    docker build \
                        --pull \
                        -t "${APP_IMAGE}:${IMAGE_TAG}" \
                        .

                    echo "=== Application image built ==="

                    docker images "${APP_IMAGE}:${IMAGE_TAG}"
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

                    docker compose down -v --remove-orphans

                    echo "=== Database containers and volume removed ==="
                '''
            }
        }

        stage('Launch Application') {
            steps {
                sh '''
                    set -e

                    echo "=== Starting application ==="

                    DB_IMAGE="${DB_IMAGE}:${DB_TAG}" \
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
                        mysqladmin \
                        ping \
                        -h 127.0.0.1 \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        --silent

                    echo "MySQL is responding."

                    echo "=== Checking database tables ==="

                    docker compose exec -T db \
                        mysql \
                        -h 127.0.0.1 \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "USE onlinebookstore; SHOW TABLES;"

                    echo "=== Checking required tables ==="

                    TABLE_COUNT=$(
                        docker compose exec -T db \
                        mysql \
                        -N \
                        -h 127.0.0.1 \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='onlinebookstore' AND table_name IN ('books','users');"
                    )

                    echo "Required table count: ${TABLE_COUNT}"

                    if [ "${TABLE_COUNT}" -ne 2 ]; then
                        echo "ERROR: books and users tables were not created."
                        echo "=== MySQL logs ==="
                        docker compose logs db
                        exit 1
                    fi

                    echo "Required tables exist."

                    echo "=== Checking sample data ==="

                    BOOK_COUNT=$(
                        docker compose exec -T db \
                        mysql \
                        -N \
                        -h 127.0.0.1 \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM onlinebookstore.books;"
                    )

                    USER_COUNT=$(
                        docker compose exec -T db \
                        mysql \
                        -N \
                        -h 127.0.0.1 \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM onlinebookstore.users;"
                    )

                    echo "Books: ${BOOK_COUNT}"
                    echo "Users: ${USER_COUNT}"

                    if [ "${BOOK_COUNT}" -lt 1 ]; then
                        echo "ERROR: books table is empty."
                        exit 1
                    fi

                    if [ "${USER_COUNT}" -lt 1 ]; then
                        echo "ERROR: users table is empty."
                        exit 1
                    fi

                    echo "=== DATABASE VERIFICATION PASSED ==="
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
