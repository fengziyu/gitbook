## 用户

### 添加用户

#### 命令：
```sql
CREATE USER 'username'@'host' IDENTIFIED BY 'password';
```
- username：创建的用户名
- host：指定该用户在哪个主机上可以登陆，如果是本地用户可用localhost，如果想让该用户可以从任意远程主机登陆，可以使用通配符%
- password：该用户的登陆密码，密码可以为空

#### 例子：
```sql
CREATE USER 'liuyang'@'localhost' IDENTIFIED BY '123456';
CREATE USER 'liuyang'@'192.168.1.101_' IDENTIFIED BY '123456';
CREATE USER 'liuyang'@'%' IDENTIFIED BY '123456';
CREATE USER 'liuyang'@'%' IDENTIFIED BY '';
CREATE USER 'liuyang'@'%';
```

### 授权

#### 命令：
```sql
GRANT privileges ON databasename.tablename TO 'username'@'host'
```
- privileges：用户的操作权限，如SELECT，INSERT，UPDATE等，如果要授予所的权限则使用ALL
- databasename：数据库名
- tablename：表名，如果要授予该用户对所有数据库和表的相应操作权限则可用*表示，如*.*

#### 例子：
```sql
GRANT SELECT, INSERT ON test.user TO 'pig'@'%';
GRANT ALL ON *.* TO 'pig'@'%';
GRANT ALL ON maindataplus.* TO 'pig'@'%'; 
```
> 用以上命令授权的用户不能给其它用户授权，如果想让该用户可以授权，用以下命令:
```sql
GRANT privileges ON databasename.tablename TO 'username'@'host' WITH GRANT OPTION;
```

### 设置与更改用户密码

#### 命令

```sql
SET PASSWORD FOR 'username'@'host' = PASSWORD('newpassword');
```
#### 例子
```sql
SET PASSWORD FOR 'pig'@'%' = PASSWORD("123456");
```

#### 撤销用户权限

#### 命令

```sql
REVOKE privilege ON databasename.tablename FROM 'username'@'host';
```

#### 例子

```sql
REVOKE SELECT ON *.* FROM 'pig'@'%';
```

### 删除用户

#### 命令

```sql
DROP USER 'username'@'host';
```
