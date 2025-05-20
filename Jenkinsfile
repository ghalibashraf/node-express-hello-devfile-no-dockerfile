pipeline {
  gent any                 // runs on any available agent

  options {
    timestamps()          // timestamper plugin
  }
  
  environment {
    REGISTRY = 'registry:5000'           // local docker registry with port
    IMAGE = 'node-hello-app'             // image to push
  }
  
  stages {
    stage('Clone the Repository') {
      steps {
        // this works because Jenkinsfile is in the same repo
        echo 'Checking out source code.'
        checkout scm
      }
    }

    stage('Determine Tag') {
      steps {
        script {
          VERSION = "${env.BUILD_NUMBER}" // To keep all version numbers unique
          FULL_IMAGE = "${REGISTRY}/${IMAGE}:${VERSION}"
          echo "Image tag: ${FULL_IMAGE}"
        }
      }
    }
    
    stage('Build, Tag & Push') {
      steps {
        script {
          echo "Building and tagging ${FULL_IMAGE}"
          def img = docker.build(FULL_IMAGE)

          echo "Pushing ${FULL_IMAGE} to local registry."
          docker.withRegistry("http://${REGISTRY}"){
            img.push() 
          }
        }
      }
    }

    stage('Verify') {
      steps {
        echo 'Starting test.'
        // run the image
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        echo 'Running docker image from local registry.'
        sh "docker run -d --name ci-test -p 8080:8080 ${FULL_IMAGE}"
        // wait for it to start
        // SHOULD THIS SLEEP TIME ALSO BE AN ENVIRONMENT VARIABLE?
        echo 'Waiting for it to start.'
        sh 'sleep 5'
        // test response for hello endpoint
        // NEED TO REMOVE THESE AND INSERT VARIABLES HERE ONCE I CONFIRM THIS WORKS
        echo 'Hitting the hello endpoint.'
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
