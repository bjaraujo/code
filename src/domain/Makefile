#
# Makefile to build the domain library - libdomain.a
#

include ../Rules.make

INCS	= static_domain.h dynamic_declarations_domain.h 	\
          dynamic_allocations_domain.h
LIB	= $(LIBDIR)/libdomain${buildtype}.a

MODSRC	= domain.F90

LIBSRC	= part_domain.F90 uv_depths.F90 have_bdy.F90 bdy_spec.F90 print_bdy.F90 \
          mirror_bdy_2d.F90 mirror_bdy_3d.F90

SRC	= $(MODSRC) $(LIBSRC)

MOD   = \
${LIB}(domain.o)


OBJ   = \
${LIB}(part_domain.o)	\
${LIB}(uv_depths.o)	\
${LIB}(have_bdy.o)	\
${LIB}(bdy_spec.o)	\
${LIB}(print_bdy.o)	\
${LIB}(mirror_bdy_2d.o)	\
${LIB}(mirror_bdy_3d.o)

all: modules objects

modules: $(MOD)

objects: $(OBJ)

$(MOD):	$(INCS)

$(OBJ):	$(INCS)

doc: $(SRC)
	$(PROTEX) $(SRC) > $(DOCDIR)/domain.tex
	touch doc

clean:
	$(RM) $(LIB) $(MODDIR)/domain.{m.mod} $(MODDIR)/topo_interface.{m.mod}

realclean: clean
	$(RM) *.o doc

distclean: realclean

#-----------------------------------------------------------------------
# Copyright (C) 2001 - Hans Burchard and Karsten Bolding (BBH)         !
#-----------------------------------------------------------------------
