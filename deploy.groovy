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
stage("create dockerfile") {
sh """
tee Dockerfile <<-'EOF'
FROM alpine:latest
RUN apk update && \
    apk add  python3 
# We copy just the requirements.txt first to leverage Docker cache
COPY ./requirements.txt /app/requirements.txt
WORKDIR /app
RUN pip3 install -r requirements.txt
COPY . /app
ENTRYPOINT [ "python3" ]
CMD [ "app.py" ]
EOF
"""
}
stage('Build image') {
customImage = docker.build .
}
stage("Push image") {
docker.withRegistry('https://registry-1.docker.io/v1', 'docker.michal,nagosa96') {
customImage.push()
}
}
}
	
