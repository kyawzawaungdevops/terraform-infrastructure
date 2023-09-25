pipeline {
    agent any

    stages {
        stage('Terraform Init') {
            steps {
                withCredentials([
                    [ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY' ]
                ]) {
                    script {
                        // Install and initialize Terraform

                        // Run 'terraform init' to initialize the project
                        
                  
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    [ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY' ]
                ]) {
                    script {
                        // Run 'terraform plan' to create an execution plan
                        sh "terraform plan"
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    [ $class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws_credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY' ]
                ]) {
                    script {
                        // Apply the Terraform execution plan (use 'auto-approve' for non-interactive execution)
                
                        sh 'terraform apply -auto-approve'
                        sh 'terraform destroy -auto-approve'
                        
                    }
                }
            }
        }
    }
}
