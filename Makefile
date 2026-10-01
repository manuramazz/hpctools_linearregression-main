# =============================================================================
# Makefile — linear regression baseline
#
# One binary per (compiler, optimization level):
#   make CC=gcc OPT=O0        -> bin/linreg_gcc_O0
#   make CC=icx OPT=Ofast     -> bin/linreg_icx_Ofast
#   make all CC=icc           -> the 4 levels (O0 O2 O3 Ofast) for icc
#
# The compiler must be available in PATH (module load ... beforehand).
# Every level above O0 adds -march=native, so build on the node that runs it.
# =============================================================================

# Make predefines CC=cc; use gcc unless CC is given explicitly.
ifeq ($(origin CC),default)
  CC = gcc
endif
OPT ?= O0

SRCS   = linreg.c rng.c gemm.c gemv.c gaussian.c
HDRS   = gaussian.h gemm.h gemv.h rng.h timer.h
BINDIR = bin
OPTS   = O0 O2 O3 Ofast

ifeq ($(OPT),O0)
  OPTFLAGS = -O0
else
  OPTFLAGS = -$(OPT) -march=native
endif

# gnu11 (not c11): rng.c needs M_PI and timer.h needs clock_gettime
CFLAGS = -std=gnu11 -Wall $(OPTFLAGS)
LDLIBS = -lm

TARGET = $(BINDIR)/linreg_$(notdir $(CC))_$(OPT)

.PHONY: build all clean

build: $(TARGET)

$(TARGET): $(SRCS) $(HDRS) Makefile | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $(SRCS) $(LDLIBS)

all:
	@for o in $(OPTS); do $(MAKE) --no-print-directory build CC=$(CC) OPT=$$o || exit 1; done

$(BINDIR):
	mkdir -p $@

clean:
	rm -rf $(BINDIR)
