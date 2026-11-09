# Lecture 14 - Microservices and Killercoda

Killercoda의 Kubernetes Playground에서 공식 튜토리얼 *Learn Kubernetes Basics* 의 Chapter 1~4를 수행한 실습 기록이다.

실습 환경은 브라우저 안에서 동작하는 일회용 클러스터이며, 세션이 만료되면 가상 머신째 삭제된다. 따라서 이 디렉터리에는 소스 코드 대신 실행 흐름과 재현 명령어를 남긴다.

- 실습 사이트: <https://killercoda.com/kubernetes-scenarios/scenario/playground>
- 튜토리얼 원문: <https://kubernetes.io/docs/tutorials/kubernetes-basics/>
- 사용 이미지: `gcr.io/google-samples/kubernetes-bootcamp:v1`

## 핵심 흐름

### 1. Create a Kubernetes cluster

1. 클러스터의 클라이언트와 서버 버전을 확인한다.
2. Control plane과 CoreDNS의 주소를 확인한다.
3. 노드 목록에서 `controlplane`이 `Ready` 상태인지 확인한다.

### 2. Deploy an app

1. `kubernetes-bootcamp` Deployment를 생성한다.
2. Deployment가 `1/1`이 될 때까지 기다린다.
3. 별도의 터미널에서 `kubectl proxy`를 실행해 API 서버로 가는 통로를 연다.
4. 프록시를 통해 API 버전과 Pod 정보를 조회한다.

### 3. Explore your app

1. Pod의 상태와 상세 정보를 확인한다.
2. 프록시를 통해 Pod가 실행 중인 애플리케이션의 응답을 받는다.
3. 애플리케이션 로그와 컨테이너 환경 변수를 확인한다.
4. 컨테이너 내부로 들어가 `server.js`를 읽고, 컨테이너가 자기 자신에게 요청을 보낸다.

### 4. Expose your app publicly

1. Deployment를 `NodePort` 타입 Service로 노출한다.
2. Service의 ClusterIP와 Endpoints를 확인하고 두 주소로 각각 접속한다.
3. Pod에 `version=v1` 라벨을 붙이고 라벨 셀렉터로 조회한다.
4. Service를 삭제한 뒤 ClusterIP로의 접속이 끊기는 것을 확인한다.
5. 컨테이너 내부에서는 여전히 응답하는 것을 확인한다.

## 재현 명령어

전체 명령은 [`commands.sh`](./commands.sh)에, 실제 실행 결과는 [`practice-log.txt`](./practice-log.txt)에 있다.

## 실습 중 확인한 점

### `minikube` 명령은 사용하지 않는다

튜토리얼 원문은 minikube를 전제로 하지만, Killercoda Playground는 접속 시점에 `controlplane` 노드가 포함된 클러스터가 이미 실행 중이다. `minikube start` 없이 `kubectl version`부터 시작한다.

### `kubectl proxy`는 터미널을 점유한다

프록시는 종료될 때까지 포그라운드에서 실행되므로 터미널이 멈춘 것처럼 보인다. 터미널 상단의 `+` 버튼으로 두 번째 탭을 열어 그곳에서 실행하고, 원래 탭에서 `curl`을 수행한다.

### `-o go-template`에는 `--template`이 필요하다

```bash
# 잘못된 예 - 템플릿 문자열을 Pod 이름으로 해석해 NotFound가 발생한다
kubectl get pods -o go-template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'

# 올바른 예
kubectl get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}'
```

### API 프록시 경로에는 포트를 명시해야 한다

`kubectl create deployment`로 만든 Pod에는 `containerPort`가 선언되지 않아 `Port: <none>` 상태가 된다. 이때 API 서버는 기본값인 80번 포트로 연결을 시도하고 다음과 같이 실패한다.

```
"message": "error trying to reach service: dial tcp 192.168.0.226:80: connect: connection refused"
"reason": "ServiceUnavailable"
"code": 503
```

Pod 이름 뒤에 포트를 붙이면 정상적으로 응답을 받는다.

```bash
curl http://localhost:8001/api/v1/namespaces/default/pods/$POD_NAME:8080/proxy/
```

### Service를 삭제해도 Pod IP는 응답한다

`kubectl delete service`는 Service가 보유한 ClusterIP와 NodePort만 제거하고 Pod 자체는 그대로 둔다. 따라서 삭제 이후에도 Pod IP(`192.168.x.x`)로는 접속이 되고, 노출이 끊긴 것을 확인하려면 ClusterIP(`10.x.x.x`)로 요청해야 한다.

### 세션에는 제한 시간이 있다

Playground 세션은 약 60분 뒤 종료되며 생성한 리소스가 모두 삭제된다. 실습 전에 화면 우측 상단의 남은 시간을 확인한다.
