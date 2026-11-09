#!/usr/bin/env bash
# Lecture 14 - Learn Kubernetes Basics Chapter 1~4
#
# Killercoda Kubernetes Playground에서 한 줄씩 실행한 명령이다.
# 중간에 두 번째 터미널 탭과 사람이 눈으로 확인해야 하는 단계가 있으므로
# 이 파일을 통째로 실행하지 않는다.

############################################
# Chapter 1 - Create a Kubernetes cluster
############################################
# Playground에는 클러스터가 이미 실행 중이므로 minikube 명령은 사용하지 않는다.

kubectl version
kubectl cluster-info
kubectl get nodes          # controlplane 이 Ready 인지 확인

############################################
# Chapter 2 - Deploy an app
############################################

kubectl create deployment kubernetes-bootcamp \
  --image=gcr.io/google-samples/kubernetes-bootcamp:v1

kubectl get deployments    # READY 가 1/1 이 될 때까지 반복 확인

# --- 두 번째 터미널 탭(+ 버튼)에서 실행하고 켜 둔다 ---
# kubectl proxy
# ----------------------------------------------------

curl http://localhost:8001/version

export POD_NAME=$(kubectl get pods -o go-template \
  --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo Name of the Pod: $POD_NAME

# Pod 자체의 메타데이터를 JSON으로 조회한다
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME/

############################################
# Chapter 3 - Explore your app
############################################

kubectl get pods
kubectl describe pods

export POD_NAME=$(kubectl get pods -o go-template \
  --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
echo Name of the Pod: $POD_NAME

# Pod가 실행 중인 애플리케이션의 응답을 받는다.
# create deployment로 만든 Pod은 containerPort가 없어 기본 80으로 가면 503이 나므로
# 포트 8080을 명시한다.
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME:8080/proxy/

kubectl logs $POD_NAME
kubectl exec "$POD_NAME" -- env

# 컨테이너 내부로 진입
kubectl exec -ti $POD_NAME -- bash
#   cat server.js
#   curl http://localhost:8080
#   exit

############################################
# Chapter 4 - Expose your app publicly
############################################

kubectl get pods
kubectl get services

kubectl expose deployment/kubernetes-bootcamp --type="NodePort" --port 8080

kubectl get services
kubectl describe services/kubernetes-bootcamp
#   IP:         <ClusterIP>     로 노출된 주소
#   Endpoints:  <PodIP>:8080    실제 Pod 주소

export NODE_PORT="$(kubectl get services/kubernetes-bootcamp \
  -o go-template='{{(index .spec.ports 0).nodePort}}')"
echo "NODE_PORT=$NODE_PORT"

# 위 describe 결과에서 읽은 값을 직접 넣는다. Killercoda에는 minikube ip가 없다.
# curl <Endpoints IP>:8080
# curl <ClusterIP>:8080

kubectl describe deployment
kubectl get pods -l app=kubernetes-bootcamp
kubectl get services -l app=kubernetes-bootcamp

export POD_NAME="$(kubectl get pods -o go-template \
  --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')"
echo "Name of the Pod: $POD_NAME"

kubectl label pods "$POD_NAME" version=v1
kubectl describe pods "$POD_NAME"      # Labels 에 version=v1 추가 확인
kubectl get pods -l version=v1

# Service 제거
kubectl delete service -l app=kubernetes-bootcamp
kubectl get services

# ClusterIP로는 더 이상 연결되지 않는다 (의도된 결과)
# curl <ClusterIP>:8080

# 컨테이너 내부에서는 여전히 응답한다
kubectl exec -ti $POD_NAME -- curl localhost:8080
