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

                    echo "=== MySQL container status ==="

                    docker compose ps db

                    echo "=== Waiting for MySQL to be healthy ==="

                    for i in $(seq 1 30); do

                        STATUS=$(docker compose ps --format '{{.Status}}' db)

                        echo "Attempt ${i}: ${STATUS}"

                        if echo "${STATUS}" | grep -qi "healthy"; then
                            echo "MySQL is healthy."
                            break
                        fi

                        if [ "${i}" -eq 30 ]; then
                            echo "ERROR: MySQL did not become healthy."

                            docker compose logs db

                            exit 1
                        fi

                        sleep 2
                    done

                    echo "=== Testing MySQL connection ==="

                    docker compose exec -T db \
                        mysql \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT 1;"

                    echo "MySQL connection successful."

                    echo "=== Checking onlinebookstore database ==="

                    docker compose exec -T db \
                        mysql \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SHOW DATABASES;"

                    echo "=== Checking tables ==="

                    docker compose exec -T db \
                        mysql \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "USE onlinebookstore; SHOW TABLES;"

                    echo "=== Checking required tables ==="

                    TABLE_COUNT=$(
                        docker compose exec -T db \
                        mysql \
                        -N \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='onlinebookstore' AND table_name IN ('books','users');"
                    )

                    TABLE_COUNT=$(echo "${TABLE_COUNT}" | tr -d '[:space:]')

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
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM onlinebookstore.books;"
                    )

                    BOOK_COUNT=$(echo "${BOOK_COUNT}" | tr -d '[:space:]')

                    USER_COUNT=$(
                        docker compose exec -T db \
                        mysql \
                        -N \
                        -uroot \
                        -p"${MYSQL_ROOT_PASSWORD:-bookstore-root-password}" \
                        -e "SELECT COUNT(*) FROM onlinebookstore.users;"
                    )

                    USER_COUNT=$(echo "${USER_COUNT}" | tr -d '[:space:]')

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
