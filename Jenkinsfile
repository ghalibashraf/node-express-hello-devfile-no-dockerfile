pipeline {
    agent any                 // runs on any available agent

    options {
        timestamps()          // timestamper plugin
    }

    environment {
      REGISTRY = 'http://registry:5000'           // local docker registry
      IMAGE = "${REGISTRY}/node-hello-app:latest" // image to push
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
        echo 'Building and tagging docker image: $IMAGE.'
        script {    // script syntax needed for defining and assigning variable
        def img = docker.build(IMAGE)

        echo 'Pushing image $IMAGE to local registry.'
        // using withRegistry() docker plugin method
        docker.withRegistry(REGISTRY){
          img.push()    // push built image
        }

        }
        // Not using the following commands anymore since plugin has better methods (above)
        // sh 'docker build -t registry:5000/node-hello-app:latest .'
        // sh 'docker push registry:5000/node-hello-app:latest'
      }
    }

    stage('Verify') {
      steps {
        echo 'Starting test.'
        // run the image
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        echo 'Running docker image from local registry.'
        sh 'docker run -d --name ci-test -p 8080:8080 $REGISTRY/node-hello-app:latest'
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
