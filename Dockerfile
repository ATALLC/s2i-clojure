# s2i-clojure
FROM openshift/base-centos7
MAINTAINER Mike Piech <mpiech@redhat.com>

ENV BUILDER_VERSION 1.0

LABEL io.k8s.description="Platform for building Clojure apps" \
      io.k8s.display-name="Clojure s2i 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,clojure"

RUN yum -y install java-1.8.0-openjdk-devel && yum clean all
RUN curl -O https://download.clojure.org/install/linux-install-1.10.0.411.sh && chmod +x linux-install-1.10.0.411.sh && ./linux-install-1.10.0.411.sh

RUN curl https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein -o ${HOME}/lein
RUN chmod 775 ${HOME}/lein
RUN ${HOME}/lein

# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

COPY ./s2i/bin/ /usr/libexec/s2i

RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001

EXPOSE 3000

CMD ["/usr/libexec/s2i/usage"]
