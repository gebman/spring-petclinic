FROM amazoncorretto:17-al2-native-headless
WORKDIR /root/petclinic
COPY ${HOST_PWD}/target/*.jar /root/petclinic/petclinic.jar
EXPOSE 8080
CMD [ "java", "-jar", "petclinic.jar" ]