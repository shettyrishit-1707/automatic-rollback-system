pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Getting source code from GitHub...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'

                bat """
                    docker build -t rollback-app:${BUILD_NUMBER} .
                """
            }
        }

        stage('Deploy with Automatic Rollback') {
            steps {
                echo 'Deploying application...'

                powershell """
                    powershell -ExecutionPolicy Bypass -File .\\scripts\\deploy.ps1 -Version ${BUILD_NUMBER}
                """
            }
        }
    }

    post {

        success {
            echo '======================================'
            echo ' DEPLOYMENT SUCCESSFUL'
            echo '======================================'
        }

        failure {
            echo '======================================'
            echo ' DEPLOYMENT FAILED / ROLLBACK'
            echo '======================================'
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}