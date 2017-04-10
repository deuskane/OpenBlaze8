ifeq ("$(ASYLUM_RTL_HOME)","")
$(error Environment variable "ASYLUM_RTL_HOME" must be set)
endif

PATH_BUILD	= $(CURDIR)/build
PATH_EXTRACT	?= $(PATH_BUILD)/extract

export PATH_EXTRACT

NAME		= $(notdir $(CURDIR))

FILES_VHDL	+= $(wildcard src/*.vhd) $(wildcard boards/$(BOARD)/*)

extract		: $(PATH_EXTRACT)
		$(foreach deps,$(IP_DEPS),$(MAKE) $(MFLAGS) -C $(ASYLUM_RTL_HOME)/$(deps) extract;)
		cp $(FILES_VHDL) $(PATH_EXTRACT)

clean		:
		rm -fr $(PATH_BUILD)


$(PATH_BUILD) $(PATH_EXTRACT) :
		mkdir -p $@

.PHONY		: 	extract	\
			clean
