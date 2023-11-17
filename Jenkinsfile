pipeline{
    agent any
    tools {
        maven 'm3'
        docker 'docker'
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
        stage('Contenerize'){
            docker.withRegistry("docker.io/mlabecki/spring-petclinic", docker_login){
                docker.build("spring-petclinic").push("latest")
            }
        }
    }
    post{
        always{
            archiveArtifacts artifacts: 'target/checkstyle-result.xml', fingerprint: true
        }
    }

}
