In a normal opensource installation of clouddriver `/opt/clouddriver/bin/clouddriver` is the startup script that defines the initial
classpath, and the jars are provided from within the given docker image.

In order to customize this dependencies, this repo includes two files which will update mysql & liquibase as a reference.
 * `clouddriver-custom-startup-script.cm.yaml` (a configmap defining a new startup script), and
 * `jarlibs.clouddriver-patch.yaml` (a kustomize patch to tell clouddriver to retrieve the new jars and use the new startup script)

There are the steps to generate these files according to the jars you require

1. Create the docker image which will contain your images.
   e.g clouddriver and orca:
   ```
   docker build --build-arg basename=clouddriver --build-arg baseimage=armory/clouddriver:2.26.6 -t armory/mysql-extra-lib:clouddriver-2.26.6 .
   docker build --build-arg basename=orca --build-arg baseimage=docker.io/armory/orca:2.26.12 -t armory/mysql-extra-lib:orca-2.26.12 .
   ```

   a. Make sure to use the correct baseimage and basename parameters, compare agains the currently k8s deployment. It has to be the same.
   b. Make sure to use another docker image tag instead of `armory/mysql-extra-lib` in the docker build command above
   c. Make sure to download and delete the relevant jars in `Dockerfile` (ln 13)
      ```
      RUN rm -rf ./lib/liquibase-core-*.jar ./lib/mysql-connector-java-*.jar
      RUN wget -P ./lib/ 'https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar' && \
          wget -P ./lib/ 'https://repo1.maven.org/maven2/org/liquibase/liquibase-core/4.3.5/liquibase-core-4.3.5.jar'

      ```

   d. There's the posibility that the CLASSPATH variable changed in the startup script require a specific order.
      In case of problems make sure to compare against the original startup script in the base images.


2. In `jarlibs.clouddriver-patch.yaml`, include each deployment volumes and init containers for each updated service:
   ```
   kustomize:
     clouddriver:
       deployment:
         patchesStrategicMerge:
           - |
             spec:
               template:
                 spec:
                   initContainers:
                     - name: mysql-extra-lib-init
                       image: armory/mysql-extra-lib:clouddriver-2.26.6
                       volumeMounts:
                         - mountPath: /target/extra-lib
                           name: extra-lib-vol
                   containers:
                     - name: clouddriver
                       volumeMounts:
                         - mountPath: /opt/clouddriver/lib
                           name: extra-lib-vol
                         - mountPath: /opt/clouddriver/bin
                           name: extra-lib-vol
                   volumes:
                     - name: extra-lib-vol
                       emptyDir: {}
     orca:
       deployment:
         patchesStrategicMerge:
           - |
             spec:
               template:
                 spec:
                   initContainers:
                     - name: mysql-extra-lib-init
                       image: armory/mysql-extra-lib:orca-2.26.12
                       volumeMounts:
                         - mountPath: /target/extra-lib
                           name: extra-lib-vol
                   containers:
                     - name: orca
                       volumeMounts:
                         - mountPath: /opt/orca/lib
                           name: extra-lib-vol
                         - mountPath: /opt/orca/bin
                           name: extra-lib-vol
                   volumes:
                     - name: extra-lib-vol
                       emptyDir: {}
   ```

