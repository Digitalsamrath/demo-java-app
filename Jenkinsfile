pipeline {
    agent any // Run on the main Jenkins instance

    tools {
        // This name MUST exactly match what we set up in Jenkins later
        maven 'Maven-3.9' 
    }

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
            steps {
                echo "Fetching code..."
                // This will be your repo's URL
                git branch: 'main', url: 'https://github.com/Digitalsamrath/demo-java-app.git' // <-- 2. UPDATE THIS
            }
        }

        stage('2. Build & Unit Test') {
            steps {
                echo "Running Maven build, JUnit tests, and JaCoCo coverage..."
                // 'verify' runs the build, tests, AND the jacoco report all in one
                sh "mvn clean verify" 
            }
        }
        /*

        stage('3. SonarQube Analysis') {
            steps {
                echo "Running SonarQube scan..."
                // The pom.xml has most settings; this just passes the server URL and token
                sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_TOKEN}"
            }
        }

        stage('4. Quality Gate') {
            steps {
                echo "Checking SonarQube Quality Gate..."
                // This pauses the pipeline and waits for Sonar's analysis
                // It will fail the build if the code quality is bad
                timeout(time: 5, unit: 'MINUTES') { 
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('5. Publish to Artifactory') {
            steps {
                echo "Passed quality checks. Publishing JAR to Artifactory..."
                script {
                    // We need the Artifactory Plugin for this 'Artifactory.server' part
                    def server = Artifactory.server "${ARTIFACTORY_SERVER}"
                    def uploadSpec = """{
                        "files": [{
                            "pattern": "target/*.jar",
                            "target": "${ARTIFACTORY_REPO}/${APP_NAME}/${APP_VERSION}/"
                        }]
                    }"""
                    server.upload(uploadSpec)
                }
            }
        }
        */

        stage('6. Build Docker Image') {
            steps {
                echo "Building Docker Image..."
                // This uses the Dockerfile in your repo
                sh "docker build -t ${DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ."
                sh "docker tag ${DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ${DOCKER_HUB_USER}/my-java-app:latest"
            }
        }

        stage('7. Push to Docker Hub') {
            steps {
                echo "Pushing image to Docker Hub..."
                // 'dockerhub-creds' is the ID we'll create in Jenkins
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS}"
                    sh "docker push ${DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER}"
                    sh "docker push ${DOCKER_HUB_USER}/my-java-app:latest"
                }
            }
        }

        stage('8. Deploy (Local Simulation)') {
            steps {
                echo "Deploying container locally..."
                sh "docker stop my-app || true" 
                sh "docker rm my-app || true"   
                
                // --- IMPORTANT ---
                // We deploy to port 8090 because Artifactory will be on 8081
                sh "docker run -d --name my-app -p 8090:8080 ${DOCKER_HUB_USER}/my-java-app:latest"
            }
        }
    }

    post {
        always {
            echo "Pipeline finished. Publishing JUnit test reports..."
            // This finds the test results and displays them in the Jenkins UI
            junit 'target/surefire-reports/*.xml' 
        }
        success {
            echo "Hooray! Deployed successfully."
            echo "Access your app at http://localhost:8090"
        }
        failure {
            echo "Pipeline failed. Check the logs."
        }
    }
}