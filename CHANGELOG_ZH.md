## 0.0.1

* 发布第一个版本，支持v1，v1.1，v2.2，v2.3，v2.4的ID3标签解析

## 0.0.3

* 修复部分解码时的BUG
* 支持ID3V1、ID3V1.1编码

## 0.0.5

* 修复部分解码时的BUG
* 支持ID3V2.3编码，你可以修改或添加歌曲名称[title]，艺术家[artist]，专辑[album]，封面图[picture]，编码格式[encoding]，以及一些用户自定义信息[userDefines]

## 0.0.6

* 修复ID3v2.3编码时的bug，该bug会导致字节组变大而越界。 

## 0.0.7
* 修复latin1在解析字节数组只有0x00导致异常的问题
* 修复v1 `genre` 字段为默认255时数组越界的问题

## 0.0.8
* 统一导出library及文件

## 0.0.9
* 优化`ID3MetataInfo`的`getTagMap()`接口返回数据，限制为基本类型。方便使用者以键值对的方式取值。

## 0.0.10
* 【重要】修复一个在**v2.3**上的严重BUG。该BUG的出现时机为：先编码，再解码，由于frame的计算为高位为0，而2.3在解码时计算frame大小的方式为高位为1。最终导致出现无效字符串，这个现象是因为编码器无法编码0x00导致的。

## 1.0.0
* 完善文档和注释

## 1.0.1 & 1.0.2 & 1.0.3
* 规范了变量和类的命名。并且添加了一些注释。