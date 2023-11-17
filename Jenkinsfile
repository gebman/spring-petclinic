pipeline{
    agent any
    tools {
        maven 'm3'
    }
    stages{
        
        stage('Checkstyle'){
            steps{
                sh "mvn clean checkstyle:checkstyle"
            }
        }
        stage("Test"){
            steps{
                sh "mvn clean test"
            }
        }
        stage('Build'){
            steps{
                sh "mvn clean package -DskipTests"
            }

        }
        // stage('Contenerize'){

        // }
    }
    post{
        always{
            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            junit 'target/checkstyle-result.xml'
        }
    }

}
