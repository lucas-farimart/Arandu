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
all: run

#========================================================
#                 COMANDOS DE SIMULACAO
#========================================================
run:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running simulation..."
	$(XRUN) $(XRUN_FLAGS) $(SRCS) -top $(TOP) $(WAVE_FLAGS)

gui:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) $(SRCS) -top $(TOP) -gui 

#========================================================
#                 SIMULACOES SECUNDARIAS
#========================================================

booth:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Booth simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/booth_radix4.sv ../tb/tb_booth.sv \
	-top tb_booth -gui 

stack:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Neuron stack simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	../rtl/neuron_stack.sv ../tb/tb_stack.sv \
	-top tb_stack -gui 

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
	-f npu.lst \
	-top tb_npu -gui 

core:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running Arandu CORE simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	-f core.lst \
	-top tb_core -gui 

memctrl:
	clear
	@mkdir -p $(WAVE_DIR)
	@echo "Running DRAM memory controller simulation (GUI)..."
	$(XRUN) $(XRUN_FLAGS) \
	-f mem_ctrl.lst \
	-top tb_mem_ctrl -gui 

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