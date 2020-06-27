# Groovy
The following project showcases writing such a Groovy script to achieve complete automation that the DevOps team need.
Pre-process:
I] Before starting the project make sure that the Jenkins package is updated. Use yum update jenkins command to update it.
  II] Download the following Jenkins plugins:
   a)PostBuildScript
   b)Job DSL

Project:
1] Dockerfiles for HTML and PHP containers
HTML:

'''javascript
FROM centos

RUN yum install httpd -y

COPY *.html /var/www/html/

EXPOSE 80

CMD /usr/sbin/httpd -DFOREGROUND && tail -f /dev/null

'''
