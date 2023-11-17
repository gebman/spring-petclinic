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
        stage('Contenerize'){
            steps{
                script{
                        sh 'export PATH="$PATH:/usr/local/bin"'
                        docker.withRegistry("https://docker.io/mlabecki/spring-petclinic", 'docker_login'){
                        def image = docker.build("spring-petclinic:latest")
                        image.push()
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