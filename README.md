# FPGA-Optimized Separable Linear Phase FIR Filter for MRI & CT Denoising

## 📌 Project Overview

This project implements a high-performance **2D FIR Filter** on an FPGA (Spartan-7) designed specifically to remove noise from medical images (CT and MRI scans).

Medical imaging often suffers from **Quantum (Poisson) Noise** and **Electronic (Gaussian) Noise**, especially in **Low-Dose CT scans** where patient radiation exposure is minimized. This project simulates these specific noise conditions and implements a hardware-efficient **Separable Filter architecture** to restore image clarity without sacrificing edge details.

## 🚀 Key Features

  * **Realistic Noise Simulation:** Uses MATLAB to model "Low-Dose" CT environments (Poisson + Gaussian noise) to test robustness.
  * **Separable Architecture:** Decomposes a computationally expensive 2D convolution ($N \times N$) into two 1D convolutions ($N + N$), significantly reducing hardware multiplier usage.
  * **Linear Phase Response:** Uses symmetric coefficients to ensure zero phase distortion, which is critical for medical diagnosis.
  * **Transpose Buffer:** Implements an efficient memory buffer to handle Row-to-Column data transposition between filtering stages.

## 🛠️ Hardware Architecture

The system follows a pipelined data flow:

1.  **Input:** 8-bit Noisy Pixel Data (from Hex file).
2.  **Stage 1 (Row Filter):** 5-tap Gaussian Low-Pass Filter processes horizontal lines.
3.  **Stage 2 (Transpose Buffer):** Stores the processed rows and reads them out column-wise.
4.  **Stage 3 (Column Filter):** 5-tap Gaussian Low-Pass Filter processes vertical lines.
5.  **Output:** Denoised 8-bit Pixel Data.

## 📂 Project Structure

```
├── MATLAB_Scripts/
│   ├── noise_generation.m       # Generates "Rough" Low-Dose CT images & Hex files
│   ├── image_reconstruction.m   # Converts processed Hex output back to Image
├── RTL/
│   ├── optimized_fir_core.v     # The 1D FIR Filter logic
│   ├── transpose_buffer.v       # Memory buffer for 2D processing
│   ├── top_filter_system.v      # Top-level wrapper connecting Row & Col filters
├── Testbench/
│   ├── tb_fir_filter.v          # Simulation testbench
├── Data/
│   ├── inputHex_ct_lowdose.txt  # Noisy input data
│   ├── output_cleaned.txt       # Processed output data
```

## ⚙️ How to Run

### Step 1: Generate Noisy Input (MATLAB)

1.  Run `noise_generation.m`.
2.  Select a standard CT/MRI image (`.bmp` or `.jpg`).
3.  The script will simulate **Low-Dose Quantum Noise** and generate `inputHex_ct_lowdose.txt`.

### Step 2: Simulate Hardware (Vivado)

1.  Add the RTL files and Testbench to your Vivado project.
2.  Ensure the Testbench points to `inputHex_ct_lowdose.txt`.
3.  Run Behavioral Simulation.
4.  The simulation will generate `output_cleaned.txt`.

### Step 3: Verify Results (MATLAB)

1.  Run `image_reconstruction.m`.
2.  The script reads `output_cleaned.txt` and displays the "Before" vs. "After" images for visual verification.

## 📊 Results

*(You should upload screenshots of your MATLAB plots here showing the Noisy Image vs. the Cleaned Image)*

**Noise Reduction Metrics:**

  * Successfully reduced high-variance Quantum Mottle noise.
  * Maintained structural integrity of key features (bones/tissues).

## 🔧 Tools & Technologies

  * **FPGA:** Xilinx Spartan-7 (XC7S50)
  * **EDA Tool:** Xilinx Vivado 202x
  * **Simulation:** Vivado Simulator
  * **Scripting:** MATLAB (for pre/post-processing)

*Developed by [Sowjanya A][Karthick Kannan S P]*
