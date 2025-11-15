pipeline {
  agent any

  environment {
    MAVEN_HOME = tool name: "Maven-3", type: "hudson.tasks.Maven$MavenInstallation"
    SONAR_NAME = "My-Sonar"                     // must match Manage Jenkins -> SonarQube Servers name
    NEXUS_URL  = "http://nexus:8081"
  }

  options {
    timeout(time: 60, unit: 'MINUTES')         // overall pipeline safety
    ansiColor('xterm')
  }

  stages {

    stage('Checkout') {
      steps {
        script {
          // ensure branch matches your repo
          git branch: 'master', url: 'https://github.com/KishanGollamudi/onlinebookstore.git'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        withSonarQubeEnv("${SONAR_NAME}") {
          sh """
            echo "Using MAVEN_HOME=${MAVEN_HOME}"
            ${MAVEN_HOME}/bin/mvn -B -e -DskipTests=false clean verify sonar:sonar \
              -Dsonar.projectKey=onlinebookstore \
              -Dsonar.host.url=${env.SONAR_HOST_URL}
          """
        }
      }
    }

    stage('Wait For Quality Gate') {
      steps {
        script {
          // show CE task id in logs to debug if needed
          echo "Polling SonarQube for Quality Gate (timeout 10m)"
          timeout(time: 10, unit: 'MINUTES') {
            def qg = waitForQualityGate abortPipeline: true
            echo "Quality Gate status: ${qg.status}"
          }
        }
      }
    }

    stage('Build (Maven)') {
      steps {
        sh "${MAVEN_HOME}/bin/mvn -B -DskipTests=false clean package"
      }
    }

    stage('Deploy to Nexus') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'nexus-user', usernameVariable: 'NEXUS_USR', passwordVariable: 'NEXUS_PSW')]) {
          sh """
            ${MAVEN_HOME}/bin/mvn -B deploy \
              -DaltDeploymentRepository=nexus::default::${NEXUS_URL}/repository/maven-releases/ \
              -Dnexus.username=${NEXUS_USR} -Dnexus.password=${NEXUS_PSW}
          """
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-user', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PSW')]) {
          sh """
            echo "${DOCKER_PSW}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker build -t ${DOCKER_USER}/onlinebookstore:${GIT_COMMIT ?: 'latest'} .
          """
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-user', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PSW')]) {
          sh """
            echo "${DOCKER_PSW}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push ${DOCKER_USER}/onlinebookstore:${GIT_COMMIT ?: 'latest'}
          """
        }
      }
    }

  } // stages

  post {
    success { echo "Pipeline succeeded" }
    failure { echo "Pipeline failed — check logs" }
    aborted { echo "Pipeline aborted" }
  }
}
