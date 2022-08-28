#!/bin/sh

################################
#                              #
#  Multicontainer project      #
#  Consist of:                 #
#  1. database                 #
#  2. backend                  #
#  3. frontend                 #
#                              #
################################

#################
# Database part #
#################

mkdir -pv /home/student/local/postgresql
sudo semanage fcontext -a -t container_file_t '/home/student/local/postgresql(/.*)?'
sudo restorecon -R /home/student/local/postgresql
podman unshare chown 27:27 /home/student/local/postgresql
# podman login registry.redhat.io
podman run \
	--name container-database-postgresql \
	-d \
	-p 5432:5432 \
	-v /home/student/local/postgresql:/var/lib/psql/data \
	-e POSTGRESQL_USER=user1 \
	-e POSTGRESQL_PASSWORD=mypa55 \
	-e POSTGRESQL_DATABASE=openmusicv1app \
	registry.access.redhat.com/rhscl/postgresql-96-rhel7

################
# Backend part #
################

podman pull ubi8/nodejs-14
git clone https://github.com/ffrmns/openmusic-app-back-end/
cd openmusic-app-back-end
git checkout v1
cd ..

mkdir s2i-node
mv openmusic-app-back-end s2i-node
echo "FROM ubi8/nodejs-14
ADD openmusic-app-back-end .
RUN npm install
ENV PGUSER user1
ENV PGPASSWORD mypa55
ENV PGDATABASE openmusicv1app
ENV PGHOST localhost
ENV PGPORT 5432
ENV HOST localhost
ENV PORT 5000
RUN npm run migrate up
CMD npm run -d start-dev
" > s2i-node/Containerfile
podman build -t image-s2i-node s2i-node
# It's port is 5000
podman run \
	--name=container-backend-node \
	-d \
	--network=host \
	image-s2i-node

#################
# Frontend part #
#################

podman exec -it container-database-postgresql psql --dbname openmusicv1app -c "INSERT INTO albums VALUES(1,'Viva la Vida',2008)"
podman exec -it container-database-postgresql psql --dbname openmusicv1app -c "INSERT INTO songs VALUES(1, 'life in Technicolor', 2008, 'Coldplay', 'Pop', 120)"

podman pull registry.access.redhat.com/ubi8/nginx-120
git clone https://github.com/sclorg/nginx-container
cd nginx-container/examples/1.20/

echo '<!DOCTYPE html><html lang="en"><head> <meta charset="UTF-8"> <meta http-equiv="X-UA-Compatible" content="IE=edge"> <meta name="viewport" content="width=device-width, initial-scale=1.0"> <title>Document</title></head><body> <h1>Consume Open Music API v1</h1> <h1>Album 1</h1> <p>Raw json</p><pre> <p id="rawjsonalbum"></p> </pre> <h1>Songs List</h1> <p>Raw json</p><pre> <button>add</button> <p id="rawjsonsongs"></p> </pre> <script src=app.js></script></body></html>' > ~/nginx-container/examples/1.20/test-app/index.html

echo 'fetch("http://localhost:5000/albums/1") .then((response)=> response.json()) .then((data)=>{console.log(data); document.getElementById("rawjsonalbum").innerHTML=JSON.stringify(data);});fetch("http://localhost:5000/songs") .then((response)=> response.json()) .then((data)=>{console.log(data); document.getElementById("rawjsonsongs").innerHTML=JSON.stringify(data);});' > ~/nginx-container/examples/1.20/test-app/app.js

echo 'FROM registry.access.redhat.com/ubi8/nginx-120

# Add application sources
ADD test-app/nginx.conf "${NGINX_CONF_PATH}"
ADD test-app/nginx-default-cfg/*.conf "${NGINX_DEFAULT_CONF_PATH}"
ADD test-app/nginx-cfg/*.conf "${NGINX_CONFIGURATION_PATH}"
ADD test-app/*.html test-app/*.js .

# Run script uses standard ways to run the application
CMD nginx -g "daemon off;"
' > Containerfile

podman build -t nginx-app .
podman run \
	--name=container-frontend-nginx \
	-d \
	--net=host \
	nginx-app
# it's port is 8080

##############
#  References
#  1. https://catalog.redhat.com/software/containers/ubi8/nodejs-14/5ed7887dd70cc50e69c2fabb?container-tabs=overview
# 2. https://catalog.redhat.com/software/containers/ubi8/nginx-120/6156abfac739c0a4123a86fd
