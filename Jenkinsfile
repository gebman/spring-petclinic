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
        stage('Containerize'){
            steps{
                script{
                        withDockerRegistry(credentialsId: 'docker_login') {
                            sh """
                            docker build -t mlabecki/spring-petclinic:${env.BUILD_ID} . 
                            docker push mlabecki/spring-petclinic:${env.BUILD_ID}
                            """
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
