FROM ubuntu:lunar

WORKDIR /home/rust-for-linux_study

# Install packages
RUN apt update && \
    apt install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/unstable -y \
    && apt upgrade -y

RUN apt install -y git flex bison \
    clang llvm lld build-essential \
    curl libelf-dev bc cpio qemu-kvm \
    telnet netcat-traditional neovim \
    unzip cmake

# Configure nvim
RUN mkdir -p ~/.config
RUN mkdir -p ~/.local
RUN git clone https://github.com/KimWang906/nvim_for_rust.git ~/.config/nvim

# Install lazygit
WORKDIR /root
RUN LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar xf lazygit.tar.gz lazygit && \
    install lazygit /usr/local/bin

# Get Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone Linux & Busybox
WORKDIR /home/rust-for-linux_study
RUN git clone --depth=1 https://github.com/Rust-for-Linux/linux.git
RUN git clone --depth=1 https://github.com/mirror/busybox.git

# Configure Linux
WORKDIR /home/rust-for-linux_study/linux
RUN rustup override set $(scripts/min-tool-version.sh rustc)
RUN rustup component add rust-src rustfmt clippy
RUN cargo install --locked --version $(scripts/min-tool-version.sh bindgen) bindgen
RUN make LLVM=1 allnoconfig qemu-busybox-min.config rust.config
RUN make LLVM=1 rustavailable
RUN sed -i 's/# CONFIG_SAMPLES_RUST is not set/CONFIG_SAMPLES_RUST=y/' .config
RUN make LLVM=1 -j8
RUN make LLVM=1 -j8 rust-analyzer

# Configure Busybox
WORKDIR /home/rust-for-linux_study/busybox
RUN make defconfig
RUN sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
RUN make -j8 && make install

WORKDIR /home/rust-for-linux_study/busybox/_install
RUN mkdir -p etc/init.d
RUN cp ../examples/inittab etc/ && \
    sed -i '/# Start an "askfirst" shell on \/dev\/tty2-4/,+3d; /# \/sbin\/getty invocations for selected ttys/,+2d' \
    etc/inittab
RUN mkdir -p usr/share/udhcpc
RUN cp ../examples/udhcp/simple.script \
    usr/share/udhcpc/default.script
RUN echo 'mkdir -p proc \
mount -t proc none /proc \
ifconfig lo up \
uphcpc -i eth0 \
mkdir -p /dev/ \
mount -t devtmpfs none /dev \
mkdir -p /dev/pts \
mount -t devpts none /dev/pts \
telnet' >> etc/init.d/rcS

WORKDIR /home/rust-for-linux_study
