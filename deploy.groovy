node('linux'){
def customImage = ""
environment{
    registry = 'michalnagosa96/project'
    registryCredential = 'docker.michal,nagosa96'
    customImage = ''
}
stage('git'){
git branch: 'master',
url:'https://github.com/michalnagosa2/flask-http.git'
}
stage('Build image') {
customImage = docker.build("michalnagosa96/project:tag")
}
stage("Push image") {
docker.withRegistry('https://registry-1.docker.io/v1', 'dockerhub.michal.nagosa') {
customImage.push()
}
}
}
