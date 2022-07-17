ARG GIT_COMMIT
ARG VERSION
ARG PROJECT

FROM golang:1.18 as modules

ADD go.mod go.sum /m/
RUN cd /m && go mod download

FROM golang:1.18 as builder
ARG GIT_COMMIT
ENV GIT_COMMIT=$GIT_COMMIT

ARG VERSION
ENV VERSION=$VERSION

ARG PROJECT
ENV PROJECT=$PROJECT

COPY --from=modules /go/pkg /go/pkg

RUN mkdir -p /src
ADD . /src
WORKDIR /src

RUN useradd -u 10001 k8s-go-app-static

RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 \
    go build -ldflags="-X ${PROJECT}/version.Version=${VERSION} -X ${PROJECT}/version.Commit=${GIT_COMMIT}" -o /k8s-go-app-static ./

RUN mkdir -p /test_static && touch /test_static/index.html
RUN echo "Hello, world from static!" > /test_static/index.html

FROM busybox

ENV PORT 8080
ENV STATICS_PATH /test_static

COPY --from=builder /test_static /test_static
COPY --from=builder /src/config/*.env ./config/

COPY --from=builder /etc/passwd /etc/passwd
USER k8s-go-app-static

COPY --from=builder /k8s-go-app-static /k8s-go-app-static
COPY --from=builder /etc/ssl/certs/ /etc/ssl/certs/

CMD ["/k8s-go-app-static"]