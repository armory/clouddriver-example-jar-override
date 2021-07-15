In a normal opensource installation of clouddriver `/opt/clouddriver/bin/clouddriver` is the startup script that defines the initial
classpath, and the jars are provided from within the given docker image.

In order to customize this dependencies, this repo includes two files which will update mysql & liquibase as a reference.
 * `clouddriver-custom-startup-script.cm.yaml` (a configmap defining a new startup script), and
 * `jarlibs.clouddriver-patch.yaml` (a kustomize patch to tell clouddriver to retrieve the new jars and use the new startup script)

There are the steps to generate these files according to the jars you require

1.  Create a base `clouddriver-custom-startup-script.cm.yaml` by doing the following commands:
    Please keep in mind these commands refer to the latest clouddriver (2.26.6) and you will need to use the version
    in your deployment manifest in k8s. Othewise it will fail with ClassNotFound
  ```
  cid=$(docker create armory/clouddriver:2.26.6)
  docker cp "$cid:/opt/clouddriver/bin/clouddriver" ./
  docker rm $cid
  kubectl create cm clouddriver-custom-startup-script -o yaml --dry-run=client --from-file=$PWD/clouddriver > clouddriver-custom-startup-script.cm.yaml
  ```
2. After creating the base script, edit the classpath to include and remove the jars as required.
   It should be around line 91 (search for first result of `CLASSPATH=`)

  a. Your new jars will be provided in `$APP_HOME/extra-lib` (e.g. mysql-connector)
    ```
    CLASSPATH=$APP_HOME/config:$APP_HOME/extra-lib/mysql-connector-java-8.0.23.jar:[.. ommitted ..]
    ```

  b. Make sure to remove the specific jars you expect to not be there
    ```
    CLASSPATH=[.. ommitted ..]:$APP_HOME/lib/mysql-connector-java-8.0.20.jar:[.. ommitted ..]
    ```

  c. Due to many factors (including k8s, security in containers, and how it detects the project root),
     you will need to manually set variable APP_HOME.
     Overwrite the final definition of APP_HOME
     It should be around line 43 (search for _last_ result of `APP_HOME=`)
    ```
    APP_HOME=/opt/clouddriver
    ```

3. In `jarlibs.clouddriver-patch.yaml` line #20 we download our new dependency jars:

  ```
  cd /opt/clouddriver/extra-lib;
  wget 'https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar'
  ```
