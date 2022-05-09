.DEFAULT_GOAL := scan

deps:
				brew install --cask docker
				brew install k3d kubectl argo
.PHONY:deps

test:
				argo submit -n argo --watch https://raw.githubusercontent.com/argoproj/argo-workflows/master/examples/hello-world.yaml
.PHONY:test

scan:
				argo submit -n argo --watch scan.yaml
.PHONY:scan

# Assumes your context is already appropriately set to an existing cluster
up:
				kubectl create ns argo
				kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml
				kubectl create secret -n argo docker-registry registry1 \
					--docker-server=registry1.dso.mil \
					--docker-username=${REGISTRY1_USERNAME} \
					--docker-email=${REGISTRY1_EMAIL} \
					--docker-password=${REGISTRY1_PASSWORD}
				kubectl apply -n argo -f pvc.yaml
.PHONY:up

down:
				kubectl delete ns argo
.PHONY:down

# currently have to manually edit the registry1 secret to add `config.json` key
k3dup:
				mkdir -p /tmp/k3dvol
				k3d cluster create argoscanner2
				kubectl create ns argo
				kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml
				kubectl create secret -n argo docker-registry registry1 \
					--docker-server=registry1.dso.mil \
					--docker-username=${REGISTRY1_USERNAME} \
					--docker-email=${REGISTRY1_EMAIL} \
					--docker-password=${REGISTRY1_PASSWORD}
				kubectl apply -n argo -f pvc.yaml
.PHONY:k3up

k3ddown:
				k3d cluster delete argoscanner2
				kill $$(pgrep kubectl)
.PHONY:k3ddown

uiup:
				kubectl -n argo port-forward deployment/argo-server 2746:2746 &
				open https://localhost:2746
.PHONY:uiup

uidown:
				kill $$(pgrep kubectl)
.PHONY:uidown
