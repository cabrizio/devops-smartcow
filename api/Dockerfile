FROM centos:7


WORKDIR /app
COPY requirements.txt requirements.txt
RUN yum install git wget gcc -y
RUN yum install python3 python3-devel -y
RUN pip3 install -r requirements.txt
COPY . .
CMD [ "python3", "app.py" ]