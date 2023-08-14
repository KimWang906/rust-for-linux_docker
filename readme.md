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
