pipeline {
    agent any

    options {
        // Clear old build output before checking out the source to build.
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
                cleanWs(deleteDirs: true, disableDeferredWipeout: true)
                checkout scm
            }
        }

        stage('Docker Image Build') {
            steps {
                sh 'docker build --pull -t "${APP_IMAGE}:${IMAGE_TAG}" .'
            }
        }

        stage('Launch Application') {
            steps {
                sh 'IMAGE_TAG="${IMAGE_TAG}" docker compose up -d --no-build --remove-orphans'
            }
        }
    }
}
