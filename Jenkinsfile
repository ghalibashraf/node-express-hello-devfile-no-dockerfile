pipeline {
    agent any                 // runs on any available agent

    options {
        timestamps()          // timestamper plugin
    }

    stages {
        stage('Clone the Repository') {
            steps {
            // this works because Jenkinsfile is in the same repo
            echo 'Checking out source code.'
            checkout scm
        }
    }

    stage('Build, Tag & Push') {
      steps {
        // build image and tag it 'latest' in our local registry
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        echo 'Building and tagging docker image.'
        sh 'docker build -t registry:5000/node-hello-app:latest .'
        // push that image
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        echo 'Pushing image to local registry.'
        sh 'docker push registry:5000/node-hello-app:latest'
      }
    }

    stage('Verify') {
      steps {
        echo 'Starting test.'
        // run the image
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        echo 'Running docker image from local registry.'
        sh 'docker run -d --name ci-test -p 8080:8080 registry:5000/node-hello-app:latest'
        // wait for it to start
        // SHOULD THIS SLEEP TIME ALSO BE AN ENVIRONMENT VARIABLE?
        echo 'Waiting for it to start.'
        sh 'sleep 5'
        // test response for hello endpoint
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        echp 'Hitting the hello endpoint.'
        sh 'curl -f http://docker:8080/hello'
      }
    }
  }

  post {
    always {
      // always doing a cleanup of the image
      // adding an or true to ensure exit code 0
      echo 'Cleaning test docker image.'
      sh 'docker rm -f ci-test || true'
    }
  }
}
