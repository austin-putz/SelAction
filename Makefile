# Build SelAction from fortran/ into build/.
#
#   make          build build/selaction
#   make test     build, then run the regression fixtures and error cases
#   make check    every test layer (tests/run_all.sh; parts need R)
#   make strict   strict debug build in build/strict, all tests on it (needs R)
#   make coverage coverage build in build/coverage, line/branch table
#   make clean    remove build/
#
# Every variable can be overridden on the command line, e.g.
#   make BUILD=build/strict FFLAGS="-g -O0 -fcheck=all"
# builds a second copy next to the normal one. make does not notice a
# change of FC or FFLAGS by itself: use another BUILD directory, `make
# clean`, or `make -B` (the test scripts that need special flags use -B).
#
# Works with GNU Make 3.81 (macOS), Linux make and MSYS2 make (Windows).

# make has a built-in default FC (f77), so ?= would never apply to it.
ifeq ($(origin FC),default)
FC := gfortran
endif
FFLAGS ?= -g -O2 -Wall
BUILD  ?= build
SRC    := fortran

# Windows binaries need .exe.
ifeq ($(OS),Windows_NT)
EXE := .exe
else
EXE :=
endif

# Order matters: gfortran compiles left to right, and each module must be
# compiled before anything that USEs it. The main program comes last.
# Add new modules here, in dependency order.
SOURCES := seltools.f90 selparameters.f90 selroutines.f90 selovlp.f90 \
           seldiscrete.f90 selaction.f90

BIN := $(BUILD)/selaction$(EXE)

.PHONY: all test check strict coverage clean help

all: $(BIN)

# -J puts the .mod files in $(BUILD) so fortran/ stays source-only.
$(BIN): $(addprefix $(SRC)/,$(SOURCES)) Makefile
	@mkdir -p $(BUILD)
	$(FC) $(FFLAGS) -J $(BUILD) -o $@ $(addprefix $(SRC)/,$(SOURCES))

test: all
	tests/run_tests.sh $(BUILD)
	tests/run_error_tests.sh $(BUILD)

check:
	BUILD=$(BUILD) tests/run_all.sh

strict:
	tests/tools/strict.sh

coverage:
	tests/tools/coverage.sh

clean:
	rm -rf $(BUILD)

help:
	@echo "make           build $(BIN)"
	@echo "make test      build, then run the regression tests and error cases"
	@echo "make check     run every test layer (golden, errors, strict, ...; needs R)"
	@echo "make strict    strict debug build in build/strict, all tests on it (needs R)"
	@echo "make coverage  coverage build in build/coverage, line/branch table"
	@echo "make clean     remove $(BUILD)/"
