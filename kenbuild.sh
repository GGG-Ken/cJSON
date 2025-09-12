#change Makefile to select arm32 or arm64 default arm64
#  基础配置：默认架构（可手动指定 ARCH=arm64 切换）
#    使用方法：make ARCH=arm32  # 编译arm32
#             make ARCH=arm64  # 编译arm64

make ARCH=arm64
make ARCH=arm64 install

make ARCH=arm32
make ARCH=arm32 install