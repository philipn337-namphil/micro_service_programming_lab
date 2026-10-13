# Lecture 10 - Docker Volume and Jenkins

Docker Volume에 Jenkins 데이터를 저장하고, Jenkins 컨테이너를 교체한 뒤에도 설정과 Job이 유지되는지 확인한 실습이다.

## 핵심 흐름

1. `myvol-1` Volume을 생성하고 상세 정보를 확인한다.
2. Jenkins 컨테이너의 `/var/jenkins_home`에 `myvol-1`을 연결한다.
3. Jenkins 초기 설정을 완료하고 `my-ls` Freestyle Job을 만든다.
4. Job의 Execute shell 단계에서 `ls`를 실행하고, Console Output의 `Finished: SUCCESS`를 확인한다.
5. 첫 Jenkins 컨테이너를 중지한 후 같은 Volume을 연결한 새 Jenkins 컨테이너를 실행한다.
6. 기존 관리자 계정과 `my-ls` Job이 그대로 남아 있는지 확인한다.

## 재현 명령어

```powershell
docker volume create myvol-1
docker run --name jenkins-production --detach -p 50000:50000 -p 8080:8080 -v myvol-1:/var/jenkins_home jenkins/jenkins:lts
```

컨테이너를 교체할 때는 기존 Jenkins를 먼저 중지한다. 두 Jenkins 컨테이너가 같은 `JENKINS_HOME` Volume을 동시에 사용하면 데이터가 손상될 수 있다.

```powershell
docker container stop jenkins-production
docker run --name jenkins-production-copy --detach -p 50001:50000 -p 8081:8080 -v myvol-1:/var/jenkins_home jenkins/jenkins:lts
```

초기 관리자 비밀번호, 관리자 계정 비밀번호, 토큰 등 민감정보는 저장소에 기록하지 않는다.
