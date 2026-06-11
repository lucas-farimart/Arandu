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
all: arandu

#========================================================
#                 COMANDOS DE SIMULACAO
#========================================================
arandu:
	clear
	@echo "" 
	@echo "Arandu DNN accelerator"
	@echo " -> Ainda em fase de testes dos submodulos:"
	@echo "" 
	@echo "|---------------|---------------|" 
	@echo "| SUBMODULO     | COMANDO MAKE  |"
	@echo "|---------------|---------------|"
	@echo "| booth         | booth         |"
	@echo "| neuron stack  | stack         |"
	@echo "| dual stack    | dual          |"
	@echo "| NPU           | npu           |"
	@echo "| arandu core   | core          |"
	@echo "|---------------|---------------|"
	@echo "" 

fsm:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running FSM simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/fsm_gpt.sv ../tb/tb_fsm.sv \
	-top tb_fsm -gui 

fsm_dual:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running FSM + Dual Stack simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/fsm_gpt.sv ../rtl/dual_stack.sv ../tb/tb_fsm_dual.sv \
	-top tb_fsm_dual -gui 

ctrl:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Arandu Control simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) -f ./lists/ctrl.lst \
	-top tb_ctrl -gui 

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
	-f ./lists/rtl.lst \
	-top tb_core -gui 

memctrl:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Memory controller simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	-f ./lists/mem_ctrl.lst \
	-top tb_mem_ctrl -gui 

booth:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Booth simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/booth_radix4.sv ../tb/tb_booth.sv \
	-top tb_booth -gui 

#--------------------------------------
#  DATA MODULES
#--------------------------------------

stack:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Neuron stack simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/neuron_stack.sv ../tb/tb_stack.sv \
	-top tb_stack -gui 

dual:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Dual stack simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/dual_stack.sv ../rtl/neuron_stack.sv ../tb/tb_dual.sv \
	-top tb_dual -gui 

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