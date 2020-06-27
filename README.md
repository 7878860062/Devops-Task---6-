# Task 6
0 notifications total 






Skip to search 
Skip to main content 
 
Close jump menu 

 
LinkedIn

 

Primary Navigation 

new new feed updates notifications

Home
1
1 new 1 new network update. notification

My Network

Jobs

Messaging
14
14 new 14 new notifications. notifications

Notifications
 
Me


Work


Try Premium Free for 1 Month
 
DevOps Assembly Lines: Groovy for Automation
Published on June 18, 2020 
 
Ninad Deogaonkar 
Summer Intern at LinuxWorld Informatics Pvt Ltd
8 articles 
 
Follow

For defining a Pipeline in SCM, a Jenkinsfile is a text file that contains the meaning of a Jenkins Pipeline and is registered with source control. The Jenkinsfile can also serve as a marker file, meaning that if Jenkins sees a Jenkinsfile as part of your project's source code, it understands that this is a project/branch that Jenkins can run. It also understands implicitly which Source Control Management (SCM) project and branch it needs to work with.
Groovy is the most widely used language for writing a Jenkinsfile as it helps working at higher levels of abstraction and provides a higher-level abstraction to all functionalities.
The following project showcases writing such a Groovy script to achieve complete automation that the DevOps team need.
Pre-process:
I] Before starting the project make sure that the Jenkins package is updated. Use yum update jenkins command to update it.
II] Download the following Jenkins plugins:
PostBuildScript
Job DSL

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

spec:
  storageClassName: manual
  
  capacity:
    storage: 10Gi
  
  accessModes:
    - ReadWriteOnce
  
  hostPath:
    path: "/mnt/sda1/data/http/"

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


PHP Server:
PersistentVolume:
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

PersistentVolumeClaim:
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


3] Deployments:
We need to create deployments on which the containers will be deployed. We Mount the /var/log/httpd/ directory in each container so as to store the log data permanently
HTML:
apiVersion: apps/v1
kind: Deployment

metadata:
  name: http-dep


spec:
  replicas: 3
  
  selector:
    matchLabels:
      app: webapp


  template:
    metadata: 
      name: http-dep 
      labels:
        app: webapp


    spec: 
      volumes:
        - name: http-pv
          persistentVolumeClaim:
            claimName: http-pv-claim
      containers: 
        - name: http-dep
          image: dockerninad07/apache-server
          volumeMounts:
            - mountPath: "/var/log/httpd/"
              name: http-pv

PHP:
apiVersion: apps/v1
kind: Deployment

metadata:
  name: php-dep


spec:
  replicas: 3
  selector:
    matchLabels:
      app: webapp


  template:
    metadata: 
      name: php-dep 
      labels:
        app: webapp


    spec: 
      volumes:
        - name: php-pv
          persistentVolumeClaim:
            claimName: php-pv-claim

      containers: 
        - name: php-dep
          image: dockerninad07/apache-php-server
          volumeMounts:
            - mountPath: "/var/log/httpd/"
              name: php-pv


4] Service:
We need to create a service for our deployment to assign a customized Port address to our Deployment.
Service:
apiVersion: v1
kind: Service

metadata:
  name: my-service

spec:
  type: NodePort
  
  selector: 
    app: webapp
  
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30100

This will assign Port 30100 to our deployment. You can assign any port number in the range 30000-32767 if using the NodePort type.
As we have our configurations ready, we need to write the Groovy script to create Jobs inside Jenkins.

Groovy Script:
We need to write a groovy script for creating a chain of Jobs inside Jenkins
Job 1: Code_interpreter
This Job will interpret the language of the committed code. On interpreting the language of the code, it will build the corresponding Docker image from the Dockerfile provided with the code. After the build is done, it will push the built image to the corresponding DockerHub repository.
job("Code_Interpreter") {


  description("Code Interpreter Job")
  
  steps {
  
   scm {
     git {
       extensions {
         wipeWorkspace()
       }
     }
   }
    
   scm {
     github("Ninad07/Groovy", "master")
   }


   triggers {
     scm("* * * * *")
   }


   shell("if ls | grep php; then sudo cp -rvf * /groovy/image/php/; else sudo cp * /groovy/image/html; fi")


   if(shell("ls /groovy/code/ | grep php | wc -l")) {


     dockerBuilderPublisher {
       dockerFileDirectory("/groovy/image/html")
       fromRegistry {
         url("dockerninad07")
         credentialsId("4de5b343-12cc-4a68-9e1c-8c4d1ce40917")
       }
       cloud("Local")
    
       tagsString("dockerninad07/apache-server")
       pushOnSuccess(true)
       pushCredentialsId("8fb4a5df-3dab-4214-a8ec-7f541f675dcb")
       cleanImages(false)
       cleanupWithJenkinsJobDelete(false)
       noCache(false)
       pull(true)
     }    
      
   }
   
   else {
     
     dockerBuilderPublisher {
       dockerFileDirectory("/groovy/image/php")
       fromRegistry {
         url("dockerninad07")
         credentialsId("4de5b343-12cc-4a68-9e1c-8c4d1ce40917")
       }
       cloud("Local")


       tagsString("dockerninad07/apache-php-server")
       pushOnSuccess(true)
       pushCredentialsId("8fb4a5df-3dab-4214-a8ec-7f541f675dcb")
       cleanImages(false)
       cleanupWithJenkinsJobDelete(false)
       noCache(false)
       pull(true)
     } 
   }
  }
}



Job 2: Kubernetes_Deployment
This Job will take inputs from the Code_Interpreter Job to know the code language and will create the volumes, deployments and the services using the configuration files we had created earlier.
job("Kubernetes_Deployment") {


  description("Kubernetes job")
    
  triggers {
    upstream {
      upstreamProjects("Code_Interpreter")
      threshold("SUCCESS")
    }  
  }


  steps {
    if(shell("ls /groovy/code | grep php | wc -l")) {


      shell("if sudo kubectl get deployments | grep html-dep; then sudo kubectl rollout restart deployment/html-dep; sudo kubectl rollout status deployment/html-dep; else if kubectl get pvc | grep http-pv-claim; then sudo kubectl delete pvc --all; kubectl create -f /groovy/dep/http_pv_claim.yml; else sudo kubectl create -f /groovy/dep/http_pv_claim.yml; fi; if sudo kubectl get pv | grep http-pv; then sudo kubectl delete pv --all; sudo kubectl create -f /groovy/dep/http_pv.yml; else sudo kubectl create -f /groovy/dep/http_pv.yml; fi; kubectl create -f /groovy/dep/http_dep.yml; kubectl create -f /groovy/dep/service.yml; kubectl get all; fi")       


  }


    else {


      shell("if sudo kubectl get deployments | grep php-dep; then sudo kubectl rollout restart deployment/php-dep; sudo kubectl rollout status deployment/php-dep; else if kubectl get pvc | grep php-pv-claim; then sudo kubectl delete pvc --all; kubectl create -f /groovy/dep/php_pv_claim.yml; else sudo kubectl create -f /groovy/dep/php_pv_claim.yml; fi; if sudo kubectl get pv | grep php-pv; then sudo kubectl delete pv --all; sudo kubectl create -f /groovy/dep/php_pv.yml; else sudo kubectl create -f /groovy/dep/php_pv.yml; fi; kubectl create -f /groovy/dep/php_dep.yml; kubectl create -f /groovy/dep/service.yml; kubectl get all; fi")


    }
  }
}



Job 3: Application_Monitoring
This Job will monitor our running application, every minute. It will retrieve the running state code from the application. If the code is 200, that means the application is running properly, then the Job will end with exit code 0. but if the code is 500 pointing out to some error, the Job will end with an exit code 1, thereby triggering the next Job.
job("Application_Monitoring") {
  
  description("Application Monitoring Job")


  triggers {
     scm("* * * * *")
   }


  steps {
    
    shell('export status=$(curl -siw "%{http_code}" -o /dev/null 192.168.99.106:30100); if [ $status -eq 200 ]; then exit 0; else python3 email.py; exit 1; fi')

  }
}



Job 4: Redeployment
If the Application_Monitoring Job exits with an error code 1, this job gets triggered. It will relaunch all the containers and Deployments on which the application was running. It will do this by simply triggering the Code_Interpreter Job.
job("Redeployment") {


  description("Redeploying the Application")


  triggers {
    upstream {
      upstreamProjects("Application_Monitoring")
      threshold("FAILURE")
    }
  }
  
  
  publishers {
    postBuildScripts {
      steps {
        downstreamParameterized {
  	  	  trigger("Code_Interpreter")
        }
      }
    }
  }
}


That was the end of the script.
The complete Groovy Script is shared in the GitHub link below

For running this Script, we need to create a Seed_Job inside Jenkins.
Before applying the script, make sure to configure a Local cloud inside Jenkins. This is because the Docker plugin build the Docker images on the specific Clouds provided.
Go to Jenkins > Manage Jenkins > Manage Nodes and Clouds > Configure Clouds > Add a new cloud and provide the credentials and the Docker Server URL of your Local system.


Jenkins:

Job: Seed_Job
Configure the seed job as follows


A

Here we can see our final website running properly with a Continuous Automation Chain running behind the scenes.
I hope my article has proved to be informative to the readers. In case of any queries or suggestions, message me or comment below.
Thank you
