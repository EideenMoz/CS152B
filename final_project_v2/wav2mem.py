import wave
import struct
import argparse
import sys

# 1,800 Kbits (225 Kilobytes)
MAX_SAMPLES = 112500

def wav_to_mem(input_wav, output_mem, downsample_factor):
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
            
            with open(output_mem, 'w') as mem_file:
                # The step size in the range() function acts as our downsampler
                for i in range(0, num_frames, downsample_factor):
                    frame_start = i * bytes_per_frame
                    sample = struct.unpack_from('<h', raw_data, frame_start)[0]
                    hex_sample = format(sample & 0xFFFF, '04X')
                    mem_file.write(hex_sample + '\n')
                    
            if channels > 1:
                print(f"Note: Detected {channels} channels. Extracted Left channel.")
            print(f"Success! Downsampled by a factor of {downsample_factor}x.")
            print(f"Extracted {new_num_frames} samples (Original: {num_frames}).")
            print(f"Output saved to: {output_mem}")
            
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
    
    args = parser.parse_args()
    wav_to_mem(args.input_wav, args.output_mem, args.downsample)