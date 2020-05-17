# Module Federation

## 介绍

Module Federation是为了解决独立应用之间代码共享问题。可以在项目内动态加载其他项目的代码，同步可以共享依赖。

Module Federation里有两个主要概念host和remote。每个项目可以是host也可以是remote，也可以两个都是。

## 配置

> 以下测试来自webpack@5.0.0-beta.16

### host

host需要配置remote列表和shared模块（其实这个也可以不用配置的。后面讲另外一种）
```javascript
// webapck
const ModuleFederationPlugin = require("webpack").container
  .ModuleFederationPlugin;

plugins : [
  new ModuleFederationPlugin({
    remotes: ['remote'], // 需要引用的remote列表
    shared: ["react", "react-dom"] // 共享的模块 也可以用overrides
  })
  // ...
]
```

### remote

remote需要配置项目名（name），打包方式（library），打包后的文件名（filename），提供override API
供的模块（exposes），和host共享的模块（shared）。
```javascript
// webapck
const ModuleFederationPlugin = require("webpack").container
  .ModuleFederationPlugin;

plugins : [
  new ModuleFederationPlugin({
    new ModuleFederationPlugin({
      name: "remote",
      library: { type: "var", name: "remote" },
      filename: "remoteEntry.js",
      exposes: {
        'Button': './src/Button.tsx',
      },
      shared: ["react", "react-dom"],
    }),
  })
  // ...
]
```

配置就完成了。接下来就是怎么用了。

## 使用

### 引入remote entry

在index.html里面引用 remote entry

```html
<html>
  <head>
    <script src="http://localhost:3002/remoteEntry.js"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

### 使用组件

```tsx
const RemoteButton = React.lazy(() => import("app2/Button"));

<React.Suspense fallback="Loading Button">
  host
  <RemoteButton />
</React.Suspense>
```

> 以上代码都可以在我抄的[demo](https://github.com/fengziyu/module-federation-examples)中看到

## 原理

ModuleFederationPlugin主要做了三件事：

  - 如何共享依赖：使用OverridablesPlugin
  - 如何公开模块：使用ContainerPlugin
  - 如何引用模块：使用ContainerReferencePlugin

> 以下编译后的代码都为 开发环境，library type为var时。

### OverridablesPlugin

该插件使指定的模块可重写（overridable）

### ContainerPlugin

该插件为指定的公开模块创建entry。同步使用OverridablesPlugin。 向容器使用者提供override API

entry js执行后会在window上挂一下对象，该对象有两个方法，get和override。get方法用来获取模块。override用来从host获取公共依赖。

entry js 如下
```javascript
var remote;remote = (() => {
  // ...
})()
```

remote对象里面get和override方法，如下：
```javascript
// get获取模块
var get = (module) => {
   return (
    __webpack_require__.o(moduleMap, module)
     ? moduleMap[module]()
     : Promise.resolve().then(() => {
      throw new Error('Module "' + module + '" does not exist in container.');
   })
 );
};
// override导入公共依赖
var override = (override) => {
   Object.assign(__webpack_require__.O, override);
};
```

### ContainerReferencePlugin

该插件将指定引用的外部包（remote）添加的容器中。并允许容器导入远程模块。在导入时会调用向容器使用者提供override，为远程模块提供公共依赖。

导入远程模块时，先获取到entry js在window上挂载的对象，先执行override，之后执行get。

打包时会在代码时添加remote方法.方法里面主要是下面这段：
```javascript
var promise = __webpack_require__(data[0])(__webpack_require__(data[1])).get(data[2]);
```
data[0]是执行override。data[1]是外部包名。data[2]是模块名

打包后的把引用外部包添加到容器中。添加的代码如下：
```javascript
// main.js

/***/ "webpack/container/reference/remote":
/*!*************************!*\
  !*** external "remote" ***!
  \*************************/
/*! unknown exports (runtime-defined) */
/*! exports [maybe provided (runtime-defined)] [maybe used (runtime-defined)] */
/*! runtime requirements: module */
/***/ ((module) => {

"use strict";
eval("module.exports = remote;\n\n//# sourceURL=webpack://@basic/host/external_%22remote%22?");
```

## 其他

### host可以不配置

从打包后的代码可以看出，直接取window上的对象就可以获取对应的模块
类似下面这种方法
```javascript
const loadComponent = (remote, module) => {
  return async () => {
    const factory = await window[remote].get(module);
    return factory();
  }
}
const Component = React.lazy(loadComponent(system.name, system.module))
```
> 完整代码可以看我抄的[demo](https://github.com/fengziyu/module-federation-examples/blob/master/dynamic-system-host/host/src/App.tsx)

### 自己感觉的不足

优点很多，我就不写了，写一些自己看到的不足吧（不一定是真的！！！）

- 直接把包挂在window上，就有点太直接了。
- 公共依赖共享，只能是host给remote提供。两个remote之间是不能共享的。

## 参考

[module-federation-examples](https://github.com/module-federation/module-federation-examples)

[Official Docs from](https://github.com/webpack/changelog-v5/blob/master/guides/module-federation.md)



