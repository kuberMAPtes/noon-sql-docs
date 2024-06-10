### WSL을 이용한 Redis,MySQL SSH 터널링(로컬 포워딩)

#### 세팅이 끝난 후 사용법
```shell
#세팅이 끝난 후 사용법
#모든 포트포워딩 종료
sudo pkill ssh
sudo pkill autossh
ssh -f -N -L 6379:10.0.2.202:6379 root@175.45.201.90
autossh -M 0 -f -N -L 6379:10.0.2.202:6379 root@175.45.201.90
ssh -f -N -L 3307:10.0.2.202:3306 root@175.45.201.90
autossh -M 0 -f -N -L 3307:10.0.2.202:3306 root@175.45.201.90
#현재 포트포워딩 규칙 확인
ps aux | grep 'ssh'
#
```
#### 세팅1 우분투,라이브러리 설치 및 ssh터널링
```bash
파워셀관리자모드로 키고 리눅스와 우분투 설치,
wsl --install
sudo apt-get update
sudo apt install autossh
sudo apt install vim
#Redis 명령 줄 클라이언트를 설치,Redis 서버 설치는 안했음
sudo apt install redis-cli
#이건 netstate 명령어 쓸 때임 
sudo apt install net-tools 
ssh -f -N -L 6379:10.0.2.202:6379 root@175.45.201.90
#비번입력 : 드라이브 >구현>최현준:api-key

#얘는 연결 끊어지면 자동연결해주는 놈
autossh -M 0 -f -N -L 6379:localhost:6379 root@175.45.201.90

#테스트해보기
redis-cli -h localhost -p 6379
SET mykey "HELLO REDIS"
GET mykey
PING
#MySQL도 똑같이 설치 가능
ssh -f -N -L 3307:10.0.2.202:3306 root@175.45.201.90
autossh -M 0 -f -N -L 3307:localhost:3306 root@175.45.201.90
```
#### 세팅2 배스천서버에 키 등록(자동 로그인)
```
자동 비밀번호 입력

ssh-keygen -t rsa -b 4096 -C "osumaniaddict527@gmail.com"

ssh-copy-id root@175.45.201.90

cat /root/.ssh/id_rsa


vim ~/.ssh/config

Host bastion
    HostName 175.45.201.90
    User root
    IdentityFile ~/.ssh/id_rsa
    ForwardAgent yes

Host remote
    HostName hyeonjun.local
    User choi
    IdentityFile ~/.ssh/id_rsa
    ProxyJump bastion
    LocalForward 6379 localhost:6379
```


만약에 우분투VM을 안쓰고 cmd에서 한다면..? 비추천
---
### 윈도우에서 하기..
로컬머신에서 SSH 키 생성을 한다.

먼저 Windows 환경에서 Windows 파일 시스템을 Bash 쉘로 조작할 수 있는 Git Bash를 설치한다.

```bash
ssh-keygen -t rsa -b 4096 -C "osumaniaddict527@gmail.com(개인이메일주소넣어주세요)"

하고 엔터 3번하기(비밀번호 관련내용)

ssh-copy-id root@175.45.201.90

cat user/osuma/.ssh/id_rsa.pub

vim ~/.ssh/config


이렇게 작성하면 된다. 아래에 내가 작성한 예시데이터를 보는게 이해가 빠르다. 
Host bastion
    HostName bastion_host
    User user
    IdentityFile ~/.ssh/id_rsa
    ForwardAgent yes

Host remote
    HostName remote_host
    User remote_user
    IdentityFile ~/.ssh/id_rsa
    ProxyJump bastion
    LocalForward 6379 localhost:6379

hostname 명령어를 입력하여 remote_host를 찾고
cmd켜서 echo %USERNAME% 명령어를 입력하여 remote_user를 찾는다.
다시 bash로 돌아와서

Host bastion
    HostName 175.45.201.90
    User root
    IdentityFile ~/.ssh/id_rsa
    ForwardAgent yes

Host remote
    HostName hyeonjun.local
    User choi
    IdentityFile ~/.ssh/id_rsa
    ProxyJump bastion
    LocalForward 6379 localhost:6379

그리고 나서 ssh root@175.45.201.90을 하면 비밀번호 입력 없이 자동로그인이 된다.
```

#### 의미:

- `ssh-keygen`: SSH 키 쌍(공개 키와 개인 키)을 생성하는 도구입니다.
- `-t rsa`: RSA 알고리즘을 사용하여 키를 생성합니다. RSA는 널리 사용되는 암호화 알고리즘입니다.
- `-b 4096`: 키의 크기를 4096비트로 설정합니다. 일반적으로 2048비트가 기본값이지만, 4096비트는 더 강력한 보안을 제공합니다.
- `-C "your_email@example.com"`: 생성된 키에 주석(Comment)을 추가합니다. 이는 키를 식별하는 데 도움이 되며, 이메일 주소를 사용하여 키를 식별할 수 있습니다.



로컬 포워딩과 ProxyJump를 자동으로 설정?????/ 무슨말이야
