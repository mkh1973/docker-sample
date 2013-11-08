# Sample Dockerfile for a Java webapp running on Tomcat + Apache

FROM centos:6.4

MAINTAINER Chris Birchall (chris.birchall@gmail.com)

# Java installation.
#
# You have to either start with an image that has Java 7 pre-installed, 
# or manually download Java once, host it somewhere, and wget it.
# RUN wget -O /tmp/jdk-7u45-linux-x64.rpm http://foo/jdk-7u45-linux-x64.rpm
ADD ./jdk /tmp
RUN rpm -i /tmp/jdk-7u45-linux-x64.rpm
RUN rm /tmp/jdk-7u45-linux-x64.rpm

# Tomcat 7
#
# Not available on yum, so install manually
RUN wget -O /tmp/apache-tomcat-4.0.47.tar.gz http://ftp.meisei-u.ac.jp/mirror/apache/dist/tomcat/tomcat-7/v7.0.47/bin/apache-tomcat-7.0.47.tar.gz
RUN cd /usr/local && tar xzf /tmp/apache-tomcat-4.0.47.tar.gz
RUN ln -s /usr/local/apache-tomcat-4.0.47 /usr/local/tomcat
RUN rm /tmp/apache-tomcat-7.0.47.tar.gz

# Other stuff can be installed with yum
# (Note that git is quite old. If you want 1.8.x, install from source.)
RUN yum -y update
RUN yum -y install httpd git

# Download Maven
RUN wget -O /tmp/apache-maven-3.1.1-bin.tar.gz http://ftp.jaist.ac.jp/pub/apache/maven/maven-3/3.1.1/binaries/apache-maven-3.1.1-bin.tar.gz
RUN cd /usr/local && tar xzf /tmp/apache-maven-3.1.1-bin.tar.gz
RUN ln -s /usr/local/apache-maven-3.1.1 /usr/local/maven
RUN rm /tmp/apache-maven-3.1.1-bin.tar.gz

# Copy Apache config files
ADD ./apache-conf /etc/httpd/conf.d

# Copy start script
ADD ./start-script /usr/local
CMD chmod a+x /usr/local/start-everything.sh

# Set the start script as the default command (this will be overriden if a command is passed to Docker on the commandline).
# Note that we tail Tomcat's log in order to keep the process running
# so that Docker will not shutdown the container. This is a bit of a hack.
CMD /usr/local/start-everything.sh && tail -F /usr/local/tomcat/logs/catalina.out

# Clone the application itself
RUN cd /usr/local && git clone https://github.com/cb372/ninja-sample.git

# Environment variables
ENV JAVA_HOME /usr/java/latest
ENV CATALINA_HOME /usr/local/tomcat
ENV MAVEN_HOME /usr/local/maven
ENV APP_HOME /usr/local/ninja-sample

# Build the app once, so we can include all the dependencies in the image
RUN cd /usr/local/ninja-sample && /usr/local/maven/bin/mvn -Dmaven.test.skip=true package

# Forward HTTP ports
EXPOSE 80:80 443:443 8080:8080

