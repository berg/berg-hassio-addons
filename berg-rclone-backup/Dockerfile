ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

COPY build.sh run.sh /
RUN chmod a+x /build.sh /run.sh
RUN /build.sh

CMD [ "/run.sh" ]