FROM centos:7
WORKDIR /usr/src/app
COPY package*.json ./
RUN yum install git wget gcc curl -y
RUN curl -sL https://rpm.nodesource.com/setup_14.x | bash -
RUN yum install nodejs -y
RUN npm install
COPY . .
CMD [ "npm", "start" ]
