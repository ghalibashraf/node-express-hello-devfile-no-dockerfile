pipeline {
  agent any                 // runs on any available agent

  stages {
    stage('Clone the Repository') {
      steps {
        // this works because Jenkinsfile is in the same repo
        checkout scm
      }
    }

    stage('Build, Tag & Push') {
      steps {
        // build image and tag it 'latest' in our local registry
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        sh 'docker build -t localhost:5000/node-hello-app:latest .'
        // push that image
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        sh 'docker push localhost:5000/node-hello-app:latest'
      }
    }

    stage('Verify') {
      steps {
        // run the image
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        sh 'docker run -d --name ci-test -p 8080:8080 localhost:5000/node-hello-app:latest'
        // wait for it to start
        // SHOULD THIS SLEEP TIME ALSO BE AN ENVIRONMENT VARIABLE?
        sh 'sleep 5'
        // test response for hello endpoint
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        sh 'curl -f http://localhost:8080/hello'
      }
    }
  }

  post {
    always {
      // always doing a cleanup of the image
      // adding an or true to ensure exit code 0
      sh 'docker rm -f ci-test || true'
    }
  }
}
