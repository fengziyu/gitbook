
## Step 1: 准备阶段

### 注册一个OAuth Application

打开[https://github.com/settings/applications/new](https://github.com/settings/applications/new)，填写信息完成注册

![注册OAuth app](\assets\registerOAuthApp.png)
![OAuth app 信息](\assets\OAuthAppInfo.png)

Client ID和Client Secret在drone运行的时候用

### 编写docker-compose

```yml
version: '3'

services:
  reverse-proxy:
    image: traefik:v2.1
    # --api.insecure=true 开启 web ui
    # --providers.docker 监听docker
    command: --api.insecure=true --providers.docker
    ports:
      # HTTP 接口
      - "80:80"
      # Web UI 接口（需要启用 --api.insecure=true）
      - "8080:8080"
    volumes:
      # 这样Traefik就可以监听Docker事件
      - /var/run/docker.sock:/var/run/docker.sock
    labels:
      # Web UI 访问地址
      - "traefik.http.routers.api.rule=Host(`traefik.fengziyu.top`)"
      - "traefik.http.routers.api.service=api@internal"
      - "traefik.http.routers.api.middlewares=auth"
      - "traefik.http.middlewares.auth.basicauth.users=test:$$apr1$$H6uskkkW$$IgXLP6ewTrSuBkTrqE8wj/"
    networks:
      - web

  drone:
    image: drone/drone:1
    container_name: drone
    volumes:
      - /var/lib/drone:/data
    environment:
      DRONE_GITHUB_SERVER: https://github.com
      # 上一步得到的值
      DRONE_GITHUB_CLIENT_ID: ${DRONE_GITHUB_CLIENT_ID}
      DRONE_GITHUB_CLIENT_SECRET: ${DRONE_GITHUB_CLIENT_ID}
      # RPC秘钥
      DRONE_RPC_SECRET: ${DRONE_RPC_SECRET}
      # 访问的域名
      DRONE_SERVER_HOST: drone.fengziyu.top
      DRONE_SERVER_PROTO: http
      # 设置初始的管理员，文档：https://docs.drone.io/server/user/admin/#create-additional-admins
      DRONE_USER_CREATE: username:fengziyu,admin:true
    restart: always
    networks:
      - web
    # labels 是traefik用
    labels:
      - "traefik.docker.network=web"
      - "traefik.enable=true"
      - "traefik.http.routers.drone.rule=Host(`drone.fengziyu.top`)"

  drone-agent:
    image: drone/agent:1
    container_name: drone-agent
    restart: always
    networks: 
      - web
    depends_on:
      - drone  #依赖drone_server，并在其后启动
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:rw
    environment:
      - DRONE_RPC_PROTO=http
      - DRONE_RPC_HOST=drone.fengziyu.top
      - DRONE_RPC_SECRET=${DRONE_RPC_SECRET}  #RPC秘钥，要与drone_server中的一致
      - DRONE_DEBUG=true

networks:
  web:
    external: true
```


- traefik：是一种反向代理服务器。支持服务发现与负载均衡。
- drone：基于容器技术的持续交付系统。
- drone-agent：接收来自Drone服务器的指令以执行构建管道。

## Step 2: 运行服务

### 创建容器

```
# docker-compose up -d
Creating drone                   ... done
Creating traefik_reverse-proxy_1 ... done
Creating drone-agent             ... done
# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                        NAMES
5b3ade89c030        drone/agent:1       "/bin/drone-agent"       2 minutes ago       Up 2 minutes                                                     drone-agent
17f7e7c3bd8c        drone/drone:1       "/bin/drone-server"      2 minutes ago       Up 2 minutes        80/tcp, 443/tcp                              drone
2bfbb3c4a514        traefik:v2.1        "/entrypoint.sh --ap…"   2 minutes ago       Up 2 minutes        0.0.0.0:80->80/tcp, 0.0.0.0:8080->8080/tcp   traefik_reverse-proxy_1
```

### 访问测试

#### traefik
![openTraefik](\assets\openTraefik.gif)

#### drone
![openDrone](\assets\openDrone.gif)

### 

#### 激活服务
![activateDrone](\assets\activateDrone.gif)

激活之后在github的Webhooks中就是多一条对应的数据
![gitWebhooks](\assets\gitWebhooks.png)

#### 编写.drone.yml

在项目根目录添加 .drone.yml 文件

```yml
---
kind: pipeline
type: docker
name: default

steps:
  - name: install
    image: node:13.10.1
    commands:
      - node -v
      - npm -v
      - yarn --version
      - yarn install

  - name: build
    image: node:13.10.1
    commands:
      - yarn run build
```

直接推送到仓库项目就会自动编译了。

![initDrone](\assets\initDrone.gif)
