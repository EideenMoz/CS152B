import wave
import struct
import argparse
import sys
import os
import re

# 1,800 Kbits (225 Kilobytes)
MAX_SAMPLES = 112500

def update_verilog_params(verilog_file, max_addr, downsample_factor):
    """Update MAX_ADDR and DOWNSAMPLE_FACTOR in the Verilog file."""
    try:
        with open(verilog_file, 'r') as f:
            content = f.read()
        
        # Replace MAX_ADDR parameter
        content = re.sub(
            r'localparam MAX_ADDR = \d+;',
            f'localparam MAX_ADDR = {max_addr};',
            content
        )
        
        # Replace DOWNSAMPLE_FACTOR parameter
        content = re.sub(
            r'localparam DOWNSAMPLE_FACTOR = \d+;',
            f'localparam DOWNSAMPLE_FACTOR = {downsample_factor};',
            content
        )
        
        with open(verilog_file, 'w') as f:
            f.write(content)
        
        print(f"Updated {verilog_file}:")
        print(f"  - MAX_ADDR = {max_addr}")
        print(f"  - DOWNSAMPLE_FACTOR = {downsample_factor}")
    except FileNotFoundError:
        print(f"Warning: Could not find {verilog_file} to update parameters.")

def wav_to_mem(input_wav, output_mem, downsample_factor, auto_update_verilog=None):
    try:
        with wave.open(input_wav, 'rb') as wav_file:
            channels = wav_file.getnchannels()
            sample_width = wav_file.getsampwidth()
            num_frames = wav_file.getnframes()
            
            if sample_width != 2:
                sys.exit("Error: Audio must be 16-bit.")
            
            # Calculate the new frame count based on the downsample factor
            new_num_frames = num_frames // downsample_factor
            
            if new_num_frames > MAX_SAMPLES:
                sys.exit(f"Error: Downsampled file is still too large! \n"
                         f"Contains {new_num_frames} samples. \n"
                         f"The Basys 3 maximum is {MAX_SAMPLES} samples.")
            
            raw_data = wav_file.readframes(num_frames)
            bytes_per_frame = channels * sample_width
            
            sample_count = 0
            with open(output_mem, 'w') as mem_file:
                # The step size in the range() function acts as our downsampler
                for i in range(0, num_frames, downsample_factor):
                    frame_start = i * bytes_per_frame
                    sample = struct.unpack_from('<h', raw_data, frame_start)[0]
                    hex_sample = format(sample & 0xFFFF, '04X')
                    mem_file.write(hex_sample + '\n')
                    sample_count += 1
                    
            if channels > 1:
                print(f"Note: Detected {channels} channels. Extracted Left channel.")
            print(f"Success! Downsampled by a factor of {downsample_factor}x.")
            print(f"Extracted {new_num_frames} samples (Original: {num_frames}).")
            print(f"Output saved to: {output_mem}")
            
            # Auto-update Verilog file if specified
            if auto_update_verilog:
                max_addr = sample_count - 1
                update_verilog_params(auto_update_verilog, max_addr, downsample_factor)
            
    except FileNotFoundError:
        sys.exit(f"Error: Could not find the input file '{input_wav}'")
    except wave.Error as e:
        sys.exit(f"Error reading WAV file: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert and downsample a WAV file to a MEM file.")
    parser.add_argument("input_wav", help="Path to the input .wav file")
    parser.add_argument("output_mem", help="Path to the output .mem file")
    
    # New argument to control the downsampling rate (defaults to 1, meaning no downsampling)
    parser.add_argument("-d", "--downsample", type=int, default=1, 
                        help="Factor to downsample by (e.g., 2 halves the sample rate).")
    
    # New argument to auto-update Verilog file
    parser.add_argument("-v", "--verilog", type=str, default="audio_top.v",
                        help="Path to audio_top.v file to auto-update with MAX_ADDR and DOWNSAMPLE_FACTOR.")
    
    args = parser.parse_args()
    wav_to_mem(args.input_wav, args.output_mem, args.downsample, args.verilog)