# Compiler settings
CROSS_COMPILE ?=
CC = $(CROSS_COMPILE)gcc
CFLAGS = -Wall -Wextra -g

# Target executable name
TARGET = writer

# Source files
SRC = writer.c

# Object files (automatically derived from source files)
OBJ = $(SRC:.c=.o)

# Default target
all: $(TARGET)

# Linking the object files to create the executable
$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJ)

# Compile C source files to object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up object files and executable
clean:
	rm -f $(OBJ) $(TARGET)

