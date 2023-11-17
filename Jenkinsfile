pipeline{
    agent any
    tools {
        maven 'm3'
    }
    stages{
        
        stage('Build'){
            steps{
            sh "mvn clean package"
            }
        }
        // stage('Contenerize'){

        // }
    }


}