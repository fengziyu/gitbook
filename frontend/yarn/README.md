## yarn

### 问题

#### 1. yarn 2 升级网络问题

1. 可以手动下载js文件。
2. 把js放到项目 .yarn/releases 目录下
3. 在 .yarnrc文件中添加
```
yarn-path ".yarn/releases/berry.js"
```
