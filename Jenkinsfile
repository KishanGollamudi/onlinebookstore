pipeline {
    agent any

    environment {
        // ===== SonarQube =====
        SONARQUBE_URL = 'http://18.207.183.120:9000'

        // ===== Docker =====
        DOCKER_IMAGE = 'kishangollamudi/onlinebookstore'
        VERSION      = "${env.BUILD_NUMBER}"

        // ===== Ansible =====
        ANSIBLE_DIR  = '/home/ubuntu/ansible'
        INVENTORY    = '/home/ubuntu/ansible/inventory.ini'
        DEPLOY_PLAYBOOK = '/home/ubuntu/ansible/deploy-app.yml'
    }

    tools {
        maven 'maven3'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                echo 'Building application with Maven...'
                sh 'mvn clean package'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withCredentials([string(credentialsId: 'sonarqube-token', variable: 'SONAR_TOKEN')]) {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=onlinebookstore \
                        -Dsonar.host.url=${SONARQUBE_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                echo 'Uploading artifact to Nexus...'
                withCredentials([usernamePassword(
                    credentialsId: 'nexus',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {

                    sh '''
                        cat <<EOF > settings.xml
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>${NEXUS_USER}</username>
      <password>${NEXUS_PASS}</password>
    </server>
  </servers>
</settings>
EOF
                    '''

                    sh 'mvn deploy -DskipTests -s settings.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_IMAGE}:${VERSION} ."
            }
        }

        stage('Push Docker Image to DockerHub') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-user',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {

                    sh """
                        echo ${DH_PASS} | docker login -u ${DH_USER} --password-stdin
                        docker push ${DOCKER_IMAGE}:${VERSION}
                        docker tag ${DOCKER_IMAGE}:${VERSION} ${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to Docker Host (via Ansible)') {
            steps {
                echo 'Triggering Ansible deployment...'
                sh """
                    ansible-playbook \
                      -i ${INVENTORY} \
                      ${DEPLOY_PLAYBOOK}
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
        success {
            echo '🎉 CI/CD pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs above.'
        }
    }
}
