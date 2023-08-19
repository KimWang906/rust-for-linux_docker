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
    unzip cmake wget gnupg

RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - 
RUN apt-get install -y nodejs

# Install Hack Nerd Fonts
WORKDIR /home
RUN wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip
RUN mkdir Hack
RUN unzip Hack.zip -d Hack/
RUN mkdir -p /usr/share/fonts/truetype
RUN install -m644 Hack/*.ttf /usr/share/fonts/truetype/
RUN rm -rf /home/Hack

# Configure nvim
RUN mkdir -p ~/.config
RUN mkdir -p ~/.local
RUN git clone https://github.com/KimWang906/NvChad ~/.config/nvim
RUN nvim --headless -c 'TSInstall c rust python dockerfile' -c 'qa'

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
RUN make LLVM=1 -j$(nproc)
RUN make LLVM=1 -j$(nproc) rust-analyzer
RUN ./scripts/clang-tools/gen_compile_commands.py

# Configure Busybox
WORKDIR /home/rust-for-linux_study/busybox
RUN make defconfig
RUN sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
RUN make -j$(nproc) && make install

WORKDIR /home/rust-for-linux_study/busybox/_install
RUN mkdir -p etc/init.d
RUN cp ../examples/inittab etc/ && \
    sed -i '/# Start an "askfirst" shell on \/dev\/tty2-4/,+3d; /# \/sbin\/getty invocations for selected ttys/,+2d' \
    etc/inittab
RUN mkdir -p usr/share/udhcpc
RUN cp ../examples/udhcp/simple.script \
    usr/share/udhcpc/default.script
RUN echo 'mkdir -p proc\n \
    mount -t proc none /proc\n \
    ifconfig lo up\n \
    udhcpc -i eth0\n \
    mkdir -p /dev/\n \
    mount -t devtmpfs none /dev\n \
    mkdir -p /dev/pts\n \
    mount -t devpts none /dev/pts\n \
    telnetd -l localhost 8080\n' >> etc/init.d/rcS
RUN chmod a+x etc/init.d/rcS

WORKDIR /home/rust-for-linux_study
