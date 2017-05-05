ifeq ("$(ASYLUM_INFRA_HOME)","")
$(error Environment variable "ASYLUM_INFRA_HOME" must be set)
endif

IP_DEPS       = pbi_PicoBlaze		\
		pbi_GPIO		\
		pbi_vga_controller	\
		pbi_timer		\
		clock_divider

include $(ASYLUM_INFRA_HOME)/mk/ip.mk
