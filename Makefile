USERNAME := mfando
APP_NAME := k8s-go-app-static
VERSION := 0.0.1

PROJECT := github.com/MaxFando/k8s-go-app-static

run:
	go install -ldflags="-X '$(PROJECT)/version.Version=$(VERSION)' \
	-X '$(PROJECT)/version.Commit=$(GIT_COMMIT)'" && $(APP_NAME)

build_container:
	docker build --build-arg=GIT_COMMIT=$(GIT_COMMIT) --build-arg=VERSION=$(VERSION) --build-arg=PROJECT=$(PROJECT) -t docker.io/$(USERNAME)/$(APP_NAME):$(VERSION) .

run_container:
	docker run -p8080:8080 $(USERNAME)/$(APP_NAME):$(VERSION)

push_container:
	docker push docker.io/$(USERNAME)/$(APP_NAME):$(VERSION)

apply:
	kubectl -n g3-max apply -f manifest.yaml