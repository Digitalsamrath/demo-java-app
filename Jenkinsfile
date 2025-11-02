pipeline {
    agent none // Run on the main Jenkins instance

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
            // 2. This stage will run on the default Jenkins node
            agent any 
            steps {
                echo "Fetching code..."
                // This is the standard way to check out the code
                // that the pipeline is linked to.
                checkout scm 
            }
        }

        stage('2. Build & Unit Test') {
            // 3. This stage also runs on the default node
            agent any 
            tools {
                maven 'Maven-3.9' // Uses the tool we configured
            }
            steps {
                echo "Running Maven build, JUnit tests, and JaCoCo coverage..."
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

        stage('3. Build Docker Image') { // Renumbered
            // 4. THIS IS THE FIX: This stage runs inside a
            //    special container that *only* has the Docker CLI.
            agent {
                docker {
                    image 'docker:26-cli' // A small, official image with just Docker tools
                    // This is the magic: it connects this container
                    // to our host's Docker engine.
                    args '-v /var/run/docker.sock:/var/run/docker.sock' 
                }
            }
            steps {
                echo "Building Docker Image..."
                // 5. Now that we're on a Docker-enabled agent,
                //    we can use the simple 'sh' commands again!
                sh "docker build -t ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ."
                sh "docker tag ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ${env.DOCKER_HUB_USER}/my-java-app:latest"
            }
        }

        stage('4. Push to Docker Hub') { // Renumbered
            // 6. This stage ALSO needs the Docker agent
            agent {
                docker {
                    image 'docker:26-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                echo "Pushing image to Docker Hub..."
                // Use the credentials we stored in Jenkins
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKK_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "docker login -u ${DOCKER_USER} -p ${DOCKK_PASS}"
                    sh "docker push ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER}"
                    sh "docker push ${env.DOCKER_HUB_USER}/my-java-app:latest"
                }
            }
        }

        stage('5. Deploy (Local Simulation)') { // Renumbered
            // 7. This stage ALSO needs the Docker agent
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
    }
    

    post {
        always {
            agent any
            steps {
             echo "Pipeline finished. Publishing JUnit test reports..."
             // This finds the test results and displays them in the Jenkins UI
             junit 'target/surefire-reports/*.xml'
            } 
        }
        success {
            steps {
             echo "Hooray! Deployed successfully."
             echo "Access your app at http://localhost:8090"
            }
        }
        failure {
            steps {
             echo "Pipeline failed."
            }
        }
    }
}