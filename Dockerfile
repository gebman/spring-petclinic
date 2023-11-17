FROM amazoncorretto:17-al2-native-headless
WORKDIR /root/petclinic
COPY target/*.jar /root/petclinic/
EXPOSE 8080
CMD [ "java", "-jar", "petclinic.jar" ]