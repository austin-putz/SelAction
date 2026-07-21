# Makefile for SelAction on macOS

# Compiler
FC = gfortran

# Compiler flags
FFLAGS = -Wall -fallow-argument-mismatch

# Linker
LD = gfortran

# Linker flags
LDFLAGS = 


# Source files
SRCS = seltools.f90 selparameters.f90 selroutines.f90 selovlp.f90 selinbreeding.f90 seldiscrete.f90 mssel.f90

# Object files
OBJS = $(SRCS:.f90=.o)

# Target executable
TARGET = mssel

# Default target
all: $(TARGET)

# Rule to build the executable
$(TARGET): $(OBJS)
	$(FC) $(FFLAGS) -o $(TARGET) $(OBJS) $(LDFLAGS)

# Rule to build object files
%.o: %.f90
	$(FC) $(FFLAGS) -c $<

# Clean up build files
clean:
	rm -f $(OBJS) $(TARGET) *.mod

.PHONY: all clean
