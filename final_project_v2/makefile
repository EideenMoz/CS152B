# ====================================================================
# GLOBAL CONFIGURATION VARIABLES (Your Single Source of Truth)
# ====================================================================
DOWNSAMPLE ?= 16
INPUT_WAV  = my_audio.wav
OUTPUT_MEM = audio_data.mem

# The pipeline outputs handled by the Makefile
HEADER_CONFIG = audio_config.vh
HEADER_FIR    = fir_coefficients.vh
SCRIPT        = wav2mem.py

# ====================================================================
# BUILD TARGETS
# ====================================================================

.PHONY: all generate clean

all: generate

generate: $(INPUT_WAV) $(SCRIPT)
	@echo --- Executing Asset Pipeline ---
	python $(SCRIPT) $(INPUT_WAV) $(OUTPUT_MEM) -d $(DOWNSAMPLE) --hc $(HEADER_CONFIG) --hf $(HEADER_FIR)
	@echo --- Generation Complete! Ready for Vivado compilation. ---

clean:
	rm -f $(OUTPUT_MEM) $(HEADER_CONFIG) $(HEADER_FIR)
	@echo Cleaned all generated assets and Verilog header configurations.