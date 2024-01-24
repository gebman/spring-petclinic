FROM maven:3.9.5-amazoncorretto-17 as build

WORKDIR /root/build
# download dependencies (this can take a long time)
COPY pom.xml .
RUN mvn -B dependency:resolve-plugins dependency:resolve
# build the jar
COPY . .
RUN mvn -B clean package

# Prepare the final image
FROM amazoncorretto:17-al2-native-headless
# ADD https://repo.maven.apache.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.20.0/jmx_prometheus_javaagent-0.20.0.jar /root/petclinic/jmx.jar
WORKDIR /root/petclinic
COPY --from=build /root/build/target/*.jar /root/petclinic/petclinic.jar
# COPY --from=build /root/build/jmx-config.yaml /root/petclinic/config.yaml

EXPOSE 8080
EXPOSE 9090
# CMD ["java", "-javaagent:./jmx.jar=9090:config.yaml", "-jar", "petclinic.jar"]
CMD ["java", "-jar", "petclinic.jar"]