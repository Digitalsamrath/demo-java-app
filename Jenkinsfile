pipeline {
    agent none 
    
    environment {
        DOCKER_HUB_USER = "samrath09" 
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
                maven 'Maven-3.9'
            }
            steps {
                echo "Running Maven build..."
                sh "mvn clean verify"
                
                // Stash the build artifacts (the jar and test reports)
                echo "Stashing artifacts..."
                stash includes: 'target/demo-0.0.1-SNAPSHOT.jar', name: 'app-jar'
                stash includes: 'target/surefire-reports/*.xml', name: 'test-reports', allowEmpty: true
            }
        }
        
        stage('3. Build Docker Image') {
            agent {
                docker {
                    image 'docker:26-cli' 
                    args '-v /var/run/docker.sock:/var/run/docker.sock --user root'
                }
            }
            steps {
                echo "Building Docker Image..."
                
                // Unstash the jar - creates 'target' folder with .jar inside
                unstash 'app-jar'
                
                // Now the Dockerfile can find the jar
                sh "docker build -t ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ."
                sh "docker tag ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER} ${env.DOCKER_HUB_USER}/my-java-app:latest"
            }
        }
        
        stage('4. Push to Docker Hub') {
            agent {
                docker {
                    image 'docker:26-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --user root'
                }
            }
            steps {
                echo "Pushing image to Docker Hub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${env.DOCKER_HUB_USER}/my-java-app:${BUILD_NUMBER}"
                    sh "docker push ${env.DOCKER_HUB_USER}/my-java-app:latest"
                }
            }
        }
        
        stage('5. Deploy (Local Simulation)') {
            agent {
                docker {
                    image 'docker:26-cli'
                    args '-v /var/run/docker.sock:/var/run/docker.sock --user root'
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
            node('') {
                echo "Pipeline finished. Publishing JUnit test reports..."
                unstash 'test-reports'
                junit allowEmptyResults: true, testResults: 'target/surefire-reports/*.xml'
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