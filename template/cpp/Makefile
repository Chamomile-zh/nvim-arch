CXX = g++
TARGET = Main
SRC = $(wildcard *.cpp)
OBJ = $(patsubst %.cpp, %.o,$(SRC))
 
CXXFLAGS = -c -Wall
 
$(TARGET): $(OBJ)
	$(CXX) -o $@ $^ #$@:当前规则的目标名，$^:所有依赖文件
 
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $< -o $@ #:对于每个cpp，编译为.o

test: $(TARGET)
	./$(TARGET)
 
clean:
	rm -f *.o $(TARGET)

.PHONY: clean test
