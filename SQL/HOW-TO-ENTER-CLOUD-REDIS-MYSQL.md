### WSL을 이용한 Redis,MySQL SSH 터널링(로컬 포워딩)

#### 세팅이 끝난 후 사용법
```shell
#세팅이 끝난 후 사용법
#모든 포트포워딩 종료
sudo pkill ssh
sudo pkill autossh
ssh -f -N -L 6379:10.0.2.202:6379 root@175.45.201.90
autossh -M 0 -f -N -L 6379:localhost:6379 root@175.45.201.90
ssh -f -N -L 3307:10.0.2.202:3306 root@175.45.201.90
autossh -M 0 -f -N -L 3307:localhost:3306 root@175.45.201.90
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