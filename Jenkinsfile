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
        // stage("Test"){
        //     steps{
        //         sh "mvn clean test"
        //     }
        // }
        stage('Build'){
            steps{
                sh "mvn clean package -DskipTests"
            }

        }
        stage('Contenerize'){
            steps{
                script{
                        withDockerRegistry(credentialsId: 'docker_login', url: 'https://docker.io/mlabecki/spring-petclinic') {
                            sh 'ls'
                            sh 'pwd'
                        }                     
                    }
                }
        }
    }
    post{
        always{
            archiveArtifacts artifacts: 'target/checkstyle-result.xml', fingerprint: true
        }
    }
}
