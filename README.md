
# Task 6
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
        }}
        
 ![p1](https://user-images.githubusercontent.com/48556545/85924337-54388800-b8af-11ea-9959-ee64daa315f5.jpg)
![p2](https://user-images.githubusercontent.com/48556545/85924338-56024b80-b8af-11ea-97fc-5555afce286d.jpg)

  # Job 2: Kubernetes_Deployment

This Job will take inputs from the Code_Interpreter Job to know the code language and will create the volumes, deployments and the services using the configuration files we had created earlier.

 


      shell("if sudo kubectl get deployments | grep html-dep; then sudo kubectl rollout restart deployment/html-dep; sudo kubectl rollout status deployment/html-dep; else if kubectl get pvc | grep http-pv-claim; then sudo kubectl delete pvc --all; kubectl create -f /groovy/dep/http_pv_claim.yml; else sudo kubectl create -f /groovy/dep/http_pv_claim.yml; fi; if sudo kubectl get pv | grep http-pv; then sudo kubectl delete pv --all; sudo kubectl create -f /groovy/dep/http_pv.yml; else sudo kubectl create -f /groovy/dep/http_pv.yml; fi; kubectl create -f /groovy/dep/http_dep.yml; kubectl create -f /groovy/dep/service.yml; kubectl get all; fi")       


  }


    else {


      shell("if sudo kubectl get deployments | grep php-dep; then sudo kubectl rollout restart deployment/php-dep; sudo kubectl rollout status deployment/php-dep; else if kubectl get pvc | grep php-pv-claim; then sudo kubectl delete pvc --all; kubectl create -f /groovy/dep/php_pv_claim.yml; else sudo kubectl create -f /groovy/dep/php_pv_claim.yml; fi; if sudo kubectl get pv | grep php-pv; then sudo kubectl delete pv --all; sudo kubectl create -f /groovy/dep/php_pv.yml; else sudo kubectl create -f /groovy/dep/php_pv.yml; fi; kubectl create -f /groovy/dep/php_dep.yml; kubectl create -f /groovy/dep/service.yml; kubectl get all; fi")
         

          }
        }
      }

![p3](https://user-images.githubusercontent.com/48556545/85924360-6dd9cf80-b8af-11ea-9fe5-1d56b6dbf2cc.jpg)
![p4](https://user-images.githubusercontent.com/48556545/85924361-6e726600-b8af-11ea-828e-6a609983a049.jpg)




## Job 3: Application_Monitoring
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



![p5](https://user-images.githubusercontent.com/48556545/85924362-6fa39300-b8af-11ea-84cf-75e338dc12a4.jpg)
![p6](https://user-images.githubusercontent.com/48556545/85924363-70d4c000-b8af-11ea-9056-8ea84c4fdfd7.jpg)

## Job 4: Redeployment
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

![p7](https://user-images.githubusercontent.com/48556545/85924365-716d5680-b8af-11ea-80d3-5deac0b955e2.jpg)
![p8](https://user-images.githubusercontent.com/48556545/85924346-63b7d100-b8af-11ea-9b5c-ce57da9b147c.jpg)
![p9](https://user-images.githubusercontent.com/48556545/85924349-661a2b00-b8af-11ea-88d3-b73eac0607ca.jpg)
## Job: Seed_Job
Configure the seed job as follows

![p8](https://user-images.githubusercontent.com/48556545/85924346-63b7d100-b8af-11ea-9b5c-ce57da9b147c.jpg)
![p9](https://user-images.githubusercontent.com/48556545/85924349-661a2b00-b8af-11ea-88d3-b73eac0607ca.jpg)
As soon as the developer commits and pushes the dsl.groovy script to the GitHub repository, the Seed_Job gets triggered
![p10](https://user-images.githubusercontent.com/48556545/85924350-674b5800-b8af-11ea-95b8-55d7ab072d55.jpg)
![p11](https://user-images.githubusercontent.com/48556545/85924351-67e3ee80-b8af-11ea-94bb-844cd933ed94.jpg)

![p12](https://user-images.githubusercontent.com/48556545/85924352-69151b80-b8af-11ea-8cb8-088c6bf4b925.jpg)

![p13](https://user-images.githubusercontent.com/48556545/85924354-69adb200-b8af-11ea-9078-06cc4e0ced54.jpg)

![p14](https://user-images.githubusercontent.com/48556545/85924355-6adedf00-b8af-11ea-9f7b-f0a3d3363d2f.jpg)

![p15](https://user-images.githubusercontent.com/48556545/85924356-6b777580-b8af-11ea-82c3-ff16652642dc.jpg)

![p16](https://user-images.githubusercontent.com/48556545/85924357-6d413900-b8af-11ea-9b4e-8eaf923390cc.jpg)

![p17](https://user-images.githubusercontent.com/48556545/85924359-6dd9cf80-b8af-11ea-95a8-e6d4a70885ee.jpg)







