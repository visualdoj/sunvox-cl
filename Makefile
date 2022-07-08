default : build ;

help :
	@echo Usage:
	@echo make build
	@echo make clean

.SUFFIXES:

.SECONDARY:

.PHONY : usage build

FPC_FLAGS := -vq -O2 -Oodfa -gl

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
PASS:=(exit 0)
clean :
	rmdir /s /q .build || $(PASS)
	rmdir /s /q bin    || $(PASS)
MKDIRP:=mkdir
else
EXEEXT:=
PASS:=true
MKDIRP:=mkdir -p
clean :
	rm -rf .build || $(PASS)
	rm -rf bin    || $(PASS)
endif

.PHONY : .build
.build :
	$(MKDIRP) .build || $(PASS)

.PHONY : bin
bin :
	$(MKDIRP) bin || $(PASS)

.PHONY : .build/tool
.build/tool : .build
	cd .build && $(MKDIRP) tool || $(PASS)

SUNVOXCL:=bin/sunvox-cl$(EXEEXT)
build : prepare_build .build bin
	cd src && fpc $(FPC_FLAGS) -Sew -FE../bin -FU../.build sunvox-cl.pas

ifneq ($(wildcard ../sunvox-cl_external/Makefile.inc),)
  include ../sunvox-cl_external/Makefile.inc
else
prepare_build : ;
endif
