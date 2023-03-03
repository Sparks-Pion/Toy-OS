# Toy-OS

### 环境配置

在 `Ubuntu22.10` ​上需要如下依赖

```x86asm
sudo apt install nasm make bochs bochs-x qemu-system-x86 
```

### 编译

编译项目，在 `makefile`​ 所在目录下编译

```x86asm
make all
```

### 运行

这里提供给 `bochs`​ 和 `qemu-system-i386`​ 两种运行方式

```x86asm
make bochs
```

```x86asm
make qemu
```

### 运行结果

​![动画](assets/动画-20230303145235-29qz1x2.gif)​
