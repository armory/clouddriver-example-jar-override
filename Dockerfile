ARG baseimage
FROM ${baseimage} as baseimage
FROM busybox:uclibc

RUN addgroup -S -g 10111 spinnaker
RUN adduser -S -G spinnaker -u 10111 spinnaker
WORKDIR /home/spinnaker

ARG basename
COPY --from=baseimage /opt/${basename}/bin/ ./bin/
COPY --from=baseimage /opt/${basename}/lib/ ./lib/

RUN rm -rf ./lib/liquibase-core-*.jar ./lib/mysql-connector-java-*.jar
RUN wget -P ./lib/ 'https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar' && \
    wget -P ./lib/ 'https://repo1.maven.org/maven2/org/liquibase/liquibase-core/4.3.5/liquibase-core-4.3.5.jar'

RUN find ./lib -name '*.jar' -print0 | tr '\0' : | sed 's|./lib/|$APP_HOME/lib/|g;s|^|CLASSPATH=$APP_HOME/config:|;s|:$||' >> newclasspath && \
    mv ./bin/${basename} ./bin/${basename}.bk && \
    awk '/^CLASSPATH=/ && 0==f++ { system("cat newclasspath"); next }; {print} ' ./bin/${basename}.bk > ./bin/${basename} && \
    rm -rf newclasspath && \
    chmod -R uog+r ./lib/ ./bin/ && \
    chmod uog+x ./bin/${basename}

USER spinnaker
CMD [ "find", ".", "-type", "f", "-exec", "cp", "{}", "/target/extra-lib/", "+" ]

