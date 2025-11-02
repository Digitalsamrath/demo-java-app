pipeline {
    // 1. We set a global agent of 'none'.
    agent none 

    // 2. NO 'tools' block here.

    environment {
        /*
        // --- SonarQube Config ---
        SONAR_HOST_URL = "http://sonarqube:9000" // We use the container name, not localhost
        SONAR_TOKEN = credentials('SONAR_TOKEN') // ID from Jenkins Credentials
        */
        // --- Docker Config ---
        DOCKER_HUB_USER = "samrath09" 
        /*
        // --- Artifactory Config ---
        ARTIFACTORY_SERVER = 'artifactory' // ID from Jenkins Global Config
        ARTIFACTORY_REPO = 'libs-release-local'
        APP_NAME = 'demo-java-app'
        APP_VERSION = '1.0.0'
        */
    }

    stages {
        stage('1. Checkout Code') {
            agent any 
            steps {
                echo "Fetching code..."
                checkout scm 
            }
        }

        stage('2. Build & Unit Test') {
            agent any 
            tools {
                maven 'Maven-3.9' // This 'tools' block is in the correct place.
            }
            steps {
                echo "Running Maven build, JUnit tests, and JaCoCo coverage..."
                sh "mvn clean verify" 
            }
        }
        
        /* --- Sonar/Artifactory stages commented out --- */
        /*
        stage('3. SonarQube Analysis') { ... }
        stage('4. Quality Gate') { ... }
        stage('5. Publish to Artifactory') { ... }
        */

        stage('3. Build Docker Image') { // Renumbered
            agent {
                docker {
                    image 'docker:26-cli' 
                    args '-v /var/run/docker.sock:/var/run/docker.sock' 
                }
            }
            steps {
                echo "Building Docker Image..."
                sh "docker build -t ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ."
                sh "docker tag ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ${env.DOCKER_HUB_USER}/my-java-app:latest"
            }
        }

        stage('4. Push to Docker Hub') { // Renumbered
            agent {
                docker {
                    image 'docker:26-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                echo "Pushing image to Docker Hub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKK_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKK_PASS}"
                    sh "docker push ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER}"
                    sh "docker push ${env.DOCKER_HUB_USER}/my-java-app:latest"
                }
            }
        }

        stage('5. Deploy (Local Simulation)') { // Renumbered
            agent {
                docker {
                    image 'docker:26-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                echo "Deploying container locally..."
                sh "docker stop my-app || true"
                sh "docker rm my-app || true"
                sh "docker run -d --name my-app -p 8090:8080 ${env.DOCKER_HUB_USER}/my-java-app:latest"
            }
        }
    } // end stages
    

    post {
        always {
            node('') {
                echo "Pipeline finished. Publishing JUnit test reports..."
                junit 'target/surefire-reports/*.xml' 
            }
        }
        success {
            echo "Hooray! Deployed successfully."
            echo "Access your app at http://localhost:8090"
        }
        failure {
            echo "Pipeline failed."
        }
    }
}