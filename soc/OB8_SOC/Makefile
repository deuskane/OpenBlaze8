ifeq ("$(ASYLUM_INFRA_HOME)","")
$(error Environment variable "ASYLUM_INFRA_HOME" must be set)
endif

IP_DEPS       = pbi_OpenBlaze8		\
		pbi_GPIO		\
		pbi_vga_controller	\
		pbi_uart		\
		clock_divider

include $(ASYLUM_INFRA_HOME)/mk/ip.mk
