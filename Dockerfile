FROM centos
RUN yum install httpd -y
RUN yum install php -y

COPY *.php /var/www/html/

RUN echo "/usr/sbin/httpd" >> /root/.bashrc

RUN source /root/.bashrc

EXPOSE 80

CMD /usr/sbin/httpd -DFOREGROUND


