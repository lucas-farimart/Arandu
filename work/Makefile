#========================================================
#                   VARIAVEIS DE CONFIG
#========================================================
SRCS       = -f rtl.lst
TOP        = tb_neurons
BUILD_DIR  = xcelium.d
WAVE_DIR   = waves
XRUN       = xrun
XRUN_FLAGS = -sv -64 -access +rwc -timescale 1ns/1ns
WAVE_FLAGS = -input waves.tcl # ainda nao existe 

# Alvo padrao
all: help

#========================================================
#                 COMANDOS DE SIMULACAO
#========================================================
arandu:
	clear
	@echo "Running Arandu simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) -f ./rtl.lst \
	-top tb_arandu -gui 

help:
	clear
	@echo "" 
	@echo "Arandu DNN accelerator"
	@echo "" 
	@echo "|-------------------|---------------|" 
	@echo "| MODULO/SUBMODULO  | COMANDO MAKE  |"
	@echo "|-------------------|---------------|"
	@echo "| Arandu (top)      | arandu        |"
	@echo "| booth             | booth         |"
	@echo "| neuron stack      | stack         |"
	@echo "| dual stack        | dual          |"
	@echo "| NPU               | npu           |"
	@echo "| arandu core       | core          |"
	@echo "|-------------------|---------------|"
	@echo "" 

#--------------------------------------
#  CONTROL/DATA MODULES
#--------------------------------------

ctrl:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Arandu Control simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) -f ./lists/ctrl.lst \
	-top tb_ctrl -gui 

memctrl:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Memory controller simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	-f ./lists/mem_ctrl.lst \
	-top tb_mem_ctrl -gui 

#--------------------------------------
#  PROCESSING MODULES
#--------------------------------------

neuron:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Tiny Neuron simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/tiny_neuron.sv ../tb/tb_tinyneuron.sv \
	-top tb_tinyneuron -gui 

npu:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Arandu NPU simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	-f ./lists/npu.lst \
	-top tb_npu -gui 

core:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Arandu CORE simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	-f ./lists/core.lst \
	-top tb_core -gui 

elab-core:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Arandu CORE with SRAMs (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	+define+USE_SRAM \
	-elaborate \
	-f ./lists/core.lst 

core-sram:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Arandu CORE with SRAMs (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	+define+USE_SRAM \
	-f ./lists/core.lst \
	-top tb_core -gui 

sram-sub:
	clear
	@echo "Running SRAM memory subsystem simulation..."
	$(XRUN) $(XRUN_FLAGS) \
	-f ./lists/sram-sub.lst \
	-top tb_sram_subsystem \
	+define+USE_SRAM

#========================================================
#                COMANDOS UTEIS EXTRAS
#========================================================

debug:
	@mkdir -p $(WAVE_DIR)
	$(XRUN) $(XRUN_FLAGS) $(SRCS) -top $(TOP) -messages -linedebug -access +rwc $(WAVE_FLAGS)

clean:
	rm -rf $(BUILD_DIR) *.log *.history $(WAVE_DIR) *.shm

erros:
	rm -f erros.log
	grep "*E" xrun.log >> erros.log
	vim erros.log

rebuild: clean run