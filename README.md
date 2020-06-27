![p1](https://user-images.githubusercontent.com/48556545/85924337-54388800-b8af-11ea-9959-ee64daa315f5.jpg)
![p2](https://user-images.githubusercontent.com/48556545/85924338-56024b80-b8af-11ea-97fc-5555afce286d.jpg)
![p8](https://user-images.githubusercontent.com/48556545/85924346-63b7d100-b8af-11ea-9b5c-ce57da9b147c.jpg)
![p9](https://user-images.githubusercontent.com/48556545/85924349-661a2b00-b8af-11ea-88d3-b73eac0607ca.jpg)
![p10](https://user-images.githubusercontent.com/48556545/85924350-674b5800-b8af-11ea-95b8-55d7ab072d55.jpg)
![p11](https://user-images.githubusercontent.com/48556545/85924351-67e3ee80-b8af-11ea-94bb-844cd933ed94.jpg)
![p12](https://user-images.githubusercontent.com/48556545/85924352-69151b80-b8af-11ea-8cb8-088c6bf4b925.jpg)
![p13](https://user-images.githubusercontent.com/48556545/85924354-69adb200-b8af-11ea-9078-06cc4e0ced54.jpg)
![p14](https://user-images.githubusercontent.com/48556545/85924355-6adedf00-b8af-11ea-9f7b-f0a3d3363d2f.jpg)
![p15](https://user-images.githubusercontent.com/48556545/85924356-6b777580-b8af-11ea-82c3-ff16652642dc.jpg)
![p16](https://user-images.githubusercontent.com/48556545/85924357-6d413900-b8af-11ea-9b4e-8eaf923390cc.jpg)
![p17](https://user-images.githubusercontent.com/48556545/85924359-6dd9cf80-b8af-11ea-95a8-e6d4a70885ee.jpg)
![p3](https://user-images.githubusercontent.com/48556545/85924360-6dd9cf80-b8af-11ea-9fe5-1d56b6dbf2cc.jpg)
![p4](https://user-images.githubusercontent.com/48556545/85924361-6e726600-b8af-11ea-828e-6a609983a049.jpg)
![p5](https://user-images.githubusercontent.com/48556545/85924362-6fa39300-b8af-11ea-84cf-75e338dc12a4.jpg)
![p6](https://user-images.githubusercontent.com/48556545/85924363-70d4c000-b8af-11ea-9056-8ea84c4fdfd7.jpg)
![p7](https://user-images.githubusercontent.com/48556545/85924365-716d5680-b8af-11ea-80d3-5deac0b955e2.jpg)


# Task 1
The following project showcases writing such a Groovy script to achieve complete automation that the DevOps team need.

Pre-process:

   1] Before starting the project make sure that the Jenkins package is updated. Use yum update jenkins command to update it.

   2] Download the following Jenkins plugins:
    
    a.PostBuildScript
   
    b.Job DSL
    Project:
1] Dockerfiles for HTML and PHP containers

HTML:

     FROM centos

     RUN yum install httpd -y
     COPY *.html /var/www/html/
     EXPOSE 80

CMD /usr/sbin/httpd -DFOREGROUND && tail -f /dev/null


PHP:

    FROM centos
    RUN yum install httpd -y
     RUN yum install php -y
    COPY *.php /var/www/html/
     EXPOSE 80

CMD /usr/sbin/httpd -DFOREGROUND && tail -f /dev/null

The webpage code files will be stored in the same path of the Dockerfiles after the Jenkins job downloads them from the GitHub

2] Persistent Volumes and Persistent Volume Claims:
As the containers are running with Apache Web Server, they generate log files. These log files are very sensitive as they are used to monitor any malicious activities on the Servers. To store the log files permanently, we need to create Persistent volumes.

HTML Server:
 PersistentVolume:
 
 
     apiVersion: v1
     kind: PersistentVolume
      metadata:
     name: http-pv
      labels:
      app: webapp


PersistentVolumeClaim:

 
      apiVersion: v1
      kind: PersistentVolumeClaim
       metadata:
          name: http-pv-claim
       spec:
  storageClassName: manual
  
  accessModes:
    - ReadWriteOnce
  
  resources:
    requests:
      storage: 3Gi



spec:
  storageClassName: manual
  
  capacity:
    storage: 10Gi
  
  accessModes:
    - ReadWriteOnce
  
  hostPath:
    path: "/mnt/sda1/data/http/"
    
    
 
 PHP Server:
PersistentVolume:


'''javascript
apiVersion: v1

kind: PersistentVolume

metadata:
  name: php-pv
  
  labels:
    app: webapp

spec:
  storageClassName: manual
  
  capacity:
    storage: 10Gi
  
  accessModes:
    - ReadWriteOnce
  
  hostPath:
    path: "/mnt/sda1/data/php/"
'''

PersistentVolumeClaim:
'''javascript
apiVersion: v1

kind: PersistentVolumeClaim

metadata:
  name: php-pv-claim

spec:
  storageClassName: manual
  
  accessModes:
    - ReadWriteOnce
  
  resources:
    requests:
      storage: 3Gi
'''

    
    

