#   ----------------------------------------------------------------------------
#   Build variables
#   ----------------------------------------------------------------------------

VERSION			:=	$(shell cat version.txt)
EXE_NAME		:=	example_mpi_and_openmp
BUILD_DATE		:=	$(shell date +"%Y.%m.%d")
COPYRIGHT_YEAR		:=	2012
OSTYPE			:=	$(shell uname -s 2>/dev/null | tr [:upper:] [:lower:])
ARCHTYPE		:=	$(shell uname -m)
ifeq ($(ARCHTYPE),x86_64)
	ARCHTYPE		:=	i686
endif


#   ----------------------------------------------------------------------------
#   List of source files & directories
#   ----------------------------------------------------------------------------

EXE_ARCH_NAME		:=	$(EXE_NAME)-$(OSTYPE)-$(ARCHTYPE)
SRCS_C			:=	main.c
SRCS_CPP		:=	
OUT_DIR			:=	build
SRC_DIR			:=	src
DIST_NAME		:=	$(EXE_NAME)-v$(VERSION)


#   ----------------------------------------------------------------------------
#   Machine-specific flags
#   ----------------------------------------------------------------------------

CFLAGS.linux.i686	:=	
LDFLAGS.linux.i686	:=	-static

CFLAGS.darwin.i686	:=	-D_DARWIN
LDFLAGS.darwin.i686	:=	


#   ----------------------------------------------------------------------------
#   Setup compiler executables
#   ----------------------------------------------------------------------------

CC			:=	mpicc
CPP			:=	mpic++
AR			:=	ar
LINK			:=	mpic++
REFORMAT		:=	astyle


#   ----------------------------------------------------------------------------
#   Setup general compiler flags
#   ----------------------------------------------------------------------------

CFLAGS			+=	-D_VERSION="\"$(VERSION)\"" \
				-D_EXE_NAME="\"$(EXE_ARCH_NAME)\"" \
				-D_BUILD_DATE="\"$(BUILD_DATE)\"" \
				-D_COPYRIGHT_YEAR="\"$(COPYRIGHT_YEAR)\""
REFORMAT_OPTS		:=	--style=linux \
				--pad-oper \
				--pad-paren \
				--pad-header \
				--keep-one-line-statements \
				--convert-tabs \
				--align-pointer=type \
				--align-reference=type \
				-n


#   ----------------------------------------------------------------------------
#   Enable or disable build-time features
#   ----------------------------------------------------------------------------

#CFLAGS			+=	-D_FEATURE
#CINCLUDES		+=	-I$(INC_DIR)


#   ----------------------------------------------------------------------------
#   Setup compiler flags
#   ----------------------------------------------------------------------------

CFLAGS			+=	$(CFLAGS.$(OSTYPE).$(ARCHTYPE))
CFLAGS			+=	-Wall
CFLAGS			+=	-fmessage-length=0
CFLAGS			+=	-O3
CFLAGS			+=	-fopenmp
CFLAGS			+=	-c
CFLAGS_C		:=	-std=gnu99
CFLAGS_CPP		:=
ARFLAGS			:=	rcs
LDFLAGS			+=	$(LDFLAGS.$(OSTYPE).$(ARCHTYPE))
LDFLAGS			+=	-fopenmp


#   ----------------------------------------------------------------------------
#   Intermediate and object files
#   ----------------------------------------------------------------------------

OBJS_C			:=	$(SRCS_C:%.c=$(OUT_DIR)/%.o)
OBJS_CPP		:=	$(SRCS_CPP:%.cpp=$(OUT_DIR)/%.o)
DEPS_C			:=	$(SRCS_C:%.c=$(OUT_DIR)/%.d)
DEPS_CPP		:=	$(SRCS_CPP:%.cpp=$(OUT_DIR)/%.d)
LIB			:=	$(OUT_DIR)/$(EXE_ARCH_NAME).a
EXE			:=	$(OUT_DIR)/$(EXE_ARCH_NAME)


#   ----------------------------------------------------------------------------
#   Makefile targets
#   ----------------------------------------------------------------------------

.PHONY : all clean install exe libs

# if desired output is a library intead of an executable change 'exe' to 'libs'
all: exe

exe: $(EXE)
libs: $(LIB)

clean:
	rm -Rf $(OBJS_C) $(OBJS_CPP) $(DEPS_C) $(DEPS_CPP) $(LIB) $(EXE) $(DIST_NAME) $(DIST_NAME).tgz

dist:
	mkdir -p tmp/$(DIST_NAME)
	cp -r Makefile tmp/$(DIST_NAME)
	cp -r version.txt tmp/$(DIST_NAME)
	cp -r $(SRC_DIR) tmp/$(DIST_NAME)
	cp -r $(EXE) tmp/$(DIST_NAME)
	(cd tmp ; tar czf ../$(DIST_NAME).tgz $(DIST_NAME) )
	rm -rf tmp

reformat:
	$(REFORMAT) $(REFORMAT_OPTS) $(SRC_DIR)/$(SRCS_C)
	#$(REFORMAT) $(REFORMAT_OPTS) $(SRC_DIR)/$(SRCS_CPP)

# include dependencies
ifneq ($(strip $(DEPS_C)),)
-include $(DEPS_C)
endif
ifneq ($(strip $(DEPS_CPP)),)
-include $(DEPS_CPP)
endif

$(EXE): $(LIB)
	$(LINK) $(LDFLAGS) -o $(EXE) $(LIB)

$(LIB): $(OBJS_C) $(OBJS_CPP)
	$(AR) $(ARFLAGS) $(LIB) $(OBJS_C) $(OBJS_CPP)

$(OUT_DIR)/%.o : $(SRC_DIR)/%.c
	$(CC) $(CFLAGS_C) $(CFLAGS) $(CINCLUDES) -MMD -MP -MF"$(OUT_DIR)/$*.d" -MT"$(OUT_DIR)/$*.d" -o $@ $<

$(OUT_DIR)/%.o : $(SRC_DIR)/%.cpp
	$(CPP) $(CFLAGS_CPP) $(CFLAGS) $(CINCLUDES) -MMD -MP -MF"$(OUT_DIR)/$*.d" -MT"$(OUT_DIR)/$*.d" -o $@ $<

$(EXE) :		| $(OUT_DIR)
$(LIB) :		| $(OUT_DIR)
$(OBJS_C) :		| $(OUT_DIR)
$(OBJS_CPP) :		| $(OUT_DIR)

$(OUT_DIR) : 
	mkdir -p $(OUT_DIR)
