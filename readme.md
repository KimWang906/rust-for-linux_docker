# Rust-for-Linux Docker

## Setup

Windows

```sh
docker build --network host -t rust-for-linux-23.04:0.0 .
docker run --name rust-for-linux --net host -i -t rust-for-linux-23.04:0.0
```

Linux

```sh
docker build --network host -t rust-for-linux-23.04:0.0 `pwd`
docker run --name rust-for-linux --net host -i -t rust-for-linux-23.04:0.0
```

## Run Linux

```sh
qemu-system-x86_64 -nographic -kernel vmlinux -initrd ../busybox/ramdisk.img \
-nic user,model=rtl8139,hostfwd=tcp::5555-:23,hostfwd=tcp::5556-:8080
```
