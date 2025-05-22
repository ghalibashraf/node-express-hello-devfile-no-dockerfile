pipeline {
  agent any                 // runs on any available agent

  options {
    timestamps()            // adds timestamps to the console output
    timeout(time: 10, unit: 'MINUTES')   // Adding timeout to terminate long-running jobs
    buildDiscarder(logRotator(numToKeepStr: '20')) // keeping 20 latest builds 
  }

  triggers {
    pollSCM('H/5 * * * *') // polls the scm every 5 minutes
  }
  
  environment {
    DIND_CONTAINER = 'jenkins-docker'
    BRIDGE_NETWORK = 'jenkins'
    REGISTRY = 'registry:5000'           // local docker registry with port
    IMAGE = 'node-hello-app'             // image to push
    JENKINS_DOCKER_ALIAS = 'docker'      // the alias set for jenkins-docker container
    CONTAINER_PORT = '8080'              // container port the hello app is listening in
    HOST_PORT = '8080'                   // host port mapped to the container port
    TEST_CONTAINER = 'ci-test'           // name for the test hello app container
    WAIT_TIME = 5                        // wait time for app container to start in seconds
  }
  
  stages {
    stage('Pre-check') {
      steps {
        echo "Verifying ${DIND_CONTAINER} container is connected to the ${BRIDGE_NETWORK} docker network."
        def network = sh(
          script: "docker network inspect ${DIND_NETWORK} --format '{{range .Containers}}{{.Name}} {{end}}'",
          returnStdout: true
          ).trim()
        if (!network.contains(BRIDGE_NETWORK)) {
          error "${DIND_CONTAINER} is not connected to the ${BRIDGE_NETWORK} network."
        } else {
          echo "${DIND_CONTAINER} is connected to the ${BRIDGE_NETWORK} network."
        }

        echo 'Verifying DIND container is running.'
        script {
          def container = sh(
            script: "docker ps --filter name=${DIND_CONTAINER} --format '{{.Names}}'", 
            returnStdout: true
            ).trim()
          if (!container) {
            error "${DIND_CONTAINER} CONTAINER NOT FOUND. PLEASE MAKE SURE IT IS RUNNING AND CONNECTED TO ${BRIDGE_NETWORK} DOCKER NETWORK."
          } else {
            echo "${DIND_CONTAINER} container found!"
          }
        }
      }
    }
    
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

    stage('Tests') {
      steps {
        echo 'Running docker image from local registry.'
        sh "docker run -d --name ${TEST_CONTAINER} -p ${HOST_PORT}:${CONTAINER_PORT} ${FULL_IMAGE}"
        // wait for it to start
        // SHOULD THIS SLEEP TIME ALSO BE AN ENVIRONMENT VARIABLE?
        echo 'Waiting for it to start.'
        sh "sleep ${WAIT_TIME}"
        // test response for hello endpoint
        echo 'Hitting the hello endpoint multiple times to verify counter increments.'
        script {
          for(int i = 1; i <= 5; i++){
            echo "Request ${i}"
            sh "curl -s http://${JENKINS_DOCKER_ALIAS}:${HOST_PORT}/hello"
            sleep 1
          }
        }
      }
    }
  }

  post {
    always {
      // always doing a cleanup of the image
      // adding an or true to ensure exit code 0
      echo 'Cleaning test docker image.'
      sh "docker rm -f ${TEST_CONTAINER} || true"
    }
  }
}
