# 最终可执行文件名
TARGET := Main

# 项目目录结构
SRCDIR   := src       # 源文件根目录（可任意嵌套子目录）
INCDIR   := include   # 头文件根目录
BUILDDIR := build     # 中间产物目录（.o / .d 依赖文件）
BINDIR   := bin       # 可执行文件输出目录

# 编译器：g++ / clang++ 一键切换
CXX := g++

# 基础编译选项
# C++标准、警告等级、头文件路径、宏定义都写在这里
CXXFLAGS := -std=c++20 -Wall -Wextra -Wpedantic -Wshadow -Wconversion -g
CXXFLAGS += -I$(INCDIR)

# 基础链接选项（库搜索路径）
LDFLAGS :=

# 手动指定链接库
# 例如 -lpthread -ldl 等；pkg-config 自动管理的库不用写在这里
LDLIBS := -lpthread

# pkg-config 自动依赖包
# 直接填写包名，自动解析头文件路径 + 链接库，多个用空格分隔
# 示例：PKGS := fmt spdlog openssl zlib
PKGS :=

# Debug / Release 模式切换
# 默认 Debug：带调试符号、无优化、开启断言
# make DEBUG=0 即为 Release 模式
DEBUG ?= 1
ifeq ($(DEBUG), 1)
    CXXFLAGS += -O0 -DDEBUG
else
    CXXFLAGS += -O2 -DNDEBUG
endif


# pkg-config 自动注入编译与链接参数
ifneq ($(PKGS),)
    CXXFLAGS += $(shell pkg-config --cflags $(PKGS))
    LDLIBS += $(shell pkg-config --libs $(PKGS))
endif

# 递归扫描 src 目录下所有 .cpp 源文件（支持任意层级子目录）
SRCS := $(shell find $(SRCDIR) -type f -name "*.cpp")

# 映射生成 .o 目标文件路径，保持与源码一致的目录结构
OBJS := $(patsubst $(SRCDIR)/%.cpp, $(BUILDDIR)/%.o, $(SRCS))

# 自动头文件依赖文件（.d）
DEPS := $(OBJS:.o=.d)

# 最终可执行文件完整路径
TARGET_BIN := $(BINDIR)/$(TARGET)


.PHONY: all clean run compiledb

# 默认目标：编译生成可执行文件
all: $(TARGET_BIN)

# 链接阶段：所有 .o 链接成最终可执行文件
$(TARGET_BIN): $(OBJS) | $(BINDIR)
	$(CXX) $(LDFLAGS) $^ -o $@ $(LDLIBS)

# 编译阶段：单个 .cpp -> .o，同时生成头文件依赖 .d
$(BUILDDIR)/%.o: $(SRCDIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -MMD -MP -c $< -o $@

# 创建输出目录（order-only 依赖，避免目录时间戳触发全量重编）
$(BINDIR) $(BUILDDIR):
	mkdir -p $@

# 引入自动生成的头文件依赖
-include $(DEPS)

# 生成 clangd 所需的 compile_commands.json 编译数据库
compiledb:
	@rm -f compile_commands.json
	bear -- make -B all

# 编译并运行程序
run: $(TARGET_BIN)
	./$(TARGET_BIN)

# 清理所有构建产物
clean:
	rm -rf $(BUILDDIR) $(BINDIR)
	rm -f compile_commands.json
