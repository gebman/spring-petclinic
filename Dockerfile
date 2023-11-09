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
WORKDIR /root/petclinic
COPY --from=build /root/build/target/*.jar /root/petclinic/petclinic.jar
EXPOSE 8080
CMD [ "java", "-jar", "petclinic.jar" ]