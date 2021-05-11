# Instruction to execute and run the backend and frontend apps

## Backend running in python

In order to execute this app we need to install python, no version has been speified, so I used th last release
 - python38

Also the requirements.txt has been compiled adding 
 - psutil==5.7.2
 - flask_cors==3.0.10

this two components are needed in order to catch resource metrics from the instance/pod/container.

## FrontEnd running in nodesjs 14.x
I have picked the version nodejs 14.x (pretty much the recommended), and as per instruction I have executed the npm cmds in order to run the app:
 - npm install
 - npm run-script build
 - npm start





## Docker
###BackEnd

As first step I have created dedicate Dockerfile with standard parameters and as base OS centos:7, and a base suite of packages such as:
 - gcc
 - git
 - wget

I used a simple and basic format, in order to keep it clear and clean, also to make our life easy I have created a make file to be use as:
 - make docker-build (in order to build our docker image)
 - make docker-run (to run the container on port 5000/default)
 - make docker-tag (if needed we can tag the img as v1.0)
 - make docker-stop (it stops the container named python-docker-smartcow)

The docker-run will execute the  ```CMD [ "python3", "app.py" ]```

###FrontEnd

As first step I have created dedicate Dockerfile with standard parameters and as base OS centos:7, and a base suite of packages such as:
 - gcc
 - git
 - wget

I used a simple and basic format, in order to keep it clear and clean, also to make our life easy I have created a make file to be use as:
 - make docker-build (in order to build our docker image)
 - make docker-run (to run the container on port 3000/default)
 - make docker-tag (if needed we can tag the img as v1.0)
 - make docker-stop (it stops the container named node-docker-smartcow)

The docker-run will execute the  ```CMD [ "npm", "start" ]```, also all the time that we build the img the ```RUN npm run-script build``` will be executed.


##Docker Compose
As final step everything has been wrapped up into a docker compose, in order to facilitate the spin up of all the dependencies, as per request the docker-compose start
a nginx instance too, and it does reverse proxy exposing port 8080 for the frontend and 8081 for the backend.
To execute the docker-compose run ```docker-compose build && docker-compose up -d```.
The nginx will be listening on 0.0.0.0:8080 and 0.0.0.0:8081, you can explore it via browser 
 - http://127.0.0.1:8080
 - http://127.0.0.1:8081

To stop the env ```docker-compose stop && docker-compose rm -a```

##K8s
I have created a simple list of yaml files in order to deploy the apps into minikube or any k8s cluster, the image are being 
pull from my personal docker-hub (public available).
All the yaml configuration files are under the k8s/ folder, and this is the sequence of cmds to use:
    1) kubectl create namespace smartcow
    2) kubectl apply -f  python-docker-smartcow.yaml (creates the backend app)
    3) kubectl apply -f  node-docker-smartcow.yaml (creates the frontend app)
    4) kubectl apply -f nginx-k8s-smartcow.yaml (create the nginx-ingress)

The app is deployed using the clusterIP and exposing only the servicePort or containerPort, because we wanted to use nginx 
I did not configure the NodePort, but instead an nginx-igress has been configured with an host association:
    - backend-smartcow.dev
    - frontend-smartcow.dev
We can test using curl as well ```curl http://backend-smartcow.dev/stats```
If in a test environment, we need to get the cluster IP (if minikube run ```minikube ip```) and add the entries into the /etc/hosts file,
otherwise if we want to keep the app without the nginx-ingress, we can add the NodePort line and get the app url running 
```minicube service <service_name> --url```




## AWS Cloud deploy
As cloud provider I picked up AWS and as service I usually use EKS, it does a good integration with terraform, so I wrote
a simple terraform block in order to deploy an EKS cluster with all the dependencies needed, such as policy, iam role etc...
All those info can be collected as best practise from AWS official documentation, I just wrapped and customized for the 
dev purpose.
The EKS cluster name is ```smartcow-eks``` and it has its own VPC with public subnet. I also configured the autoscaling block 
allowing a Max number of nodes to 2 and Min number of nodes to 1, this value can be changed anytime.
I have created a makefile that can be used as:
    - make terraform-init (to initialize the terraform and download the plugin needed )
    - make terraform-plan (preview of what will be installed)
    - make terraform-apply (deploy all the resources)
    - make terraform-destroy (destroy all the resources part of the tfstate)

For terraform I have not used the best practise, such as using a remote S3 backend to store the tfstate, and as you noted 
I haven't advertised my AWS_API_KEY, for the simple reason that I use AWS_PROFILE.



