import tkinter as tk
from PIL import Image, ImageDraw
import os
import serial
import time

# Hardware Config 
dataWidth = 8              # Total bits
IntSize = 1                # Integer bits (including sign)
fracBits = dataWidth - IntSize # 7 fractional bits

def DtoB(num, dataWidth, fracBits):
    """Converts a float (0.0 to 1.0) to your 8-bit 2's complement binary string"""
    max_val = (2**(dataWidth-1)) - 1
    min_val = -(2**(dataWidth-1))
    
    val = int(num * (2**fracBits))
    
    if val > max_val: val = max_val
    if val < min_val: val = min_val

    # Convert to 2's Complement Binary (Always returns positive integer for bitwise accuracy)
    if val >= 0:
        d = val
    else:
        d = (2**dataWidth) + val
        
    return d

class DigitDrawer:
    def __init__(self, root):
        self.root = root
        self.root.title("FPGA Digit Drawer & Sender")
        
        self.canvas_size = 280
        self.brush_size = 25 # Perfectly matches MNIST pen thickness
        
        
        self.image = Image.new("L", (self.canvas_size, self.canvas_size), 0)
        self.draw = ImageDraw.Draw(self.image)
        
        
        self.canvas = tk.Canvas(root, width=self.canvas_size, height=self.canvas_size, bg='black')
        self.canvas.pack(pady=10)
        self.canvas.bind("<B1-Motion>", self.paint)
        
    
        control_frame_1 = tk.Frame(root)
        control_frame_1.pack(pady=5)
        
        tk.Label(control_frame_1, text="Expected Label (0-9):").grid(row=0, column=0, padx=5)
        self.label_entry = tk.Entry(control_frame_1, width=5)
        self.label_entry.insert(0, "0")
        self.label_entry.grid(row=0, column=1, padx=5)
        
        tk.Label(control_frame_1, text="File Index:").grid(row=0, column=2, padx=5)
        self.index_entry = tk.Entry(control_frame_1, width=5)
        self.index_entry.insert(0, "0")
        self.index_entry.grid(row=0, column=3, padx=5)

        tk.Label(control_frame_1, text="COM Port:").grid(row=0, column=4, padx=5)
        self.com_entry = tk.Entry(control_frame_1, width=7)
        self.com_entry.insert(0, "COM17") # Default to COM11 based on your config
        self.com_entry.grid(row=0, column=5, padx=5)
        
        # Bottom Controls Frame (Action Buttons) 
        control_frame_2 = tk.Frame(root)
        control_frame_2.pack(pady=5)

        self.btn_clear = tk.Button(control_frame_2, text="1. Clear Canvas", command=self.clear, width=15)
        self.btn_clear.grid(row=0, column=0, padx=10)
        
        self.btn_save = tk.Button(control_frame_2, text="2. Save Data", command=self.save_data, width=15)
        self.btn_save.grid(row=0, column=1, padx=10)

        self.btn_send = tk.Button(control_frame_2, text="3. Send to FPGA", command=self.send_to_fpga, width=15, bg="lightgreen")
        self.btn_send.grid(row=0, column=2, padx=10)
        
        self.status = tk.Label(root, text="Draw a digit, click Save, then Send to FPGA.", fg="blue")
        self.status.pack(pady=5)
        
        self.last_x, self.last_y = None, None
        self.canvas.bind('<ButtonRelease-1>', self.reset_brush)
        self.last_saved_filepath = None

    def paint(self, event):
        x, y = event.x, event.y
        if self.last_x and self.last_y:
            # Draw on the Tkinter canvas with WHITE ink
            self.canvas.create_line((self.last_x, self.last_y, x, y), 
                                    width=self.brush_size, fill='white', 
                                    capstyle=tk.ROUND, smooth=tk.TRUE)
            # Draw on the PIL Image with WHITE ink (255)
            self.draw.line((self.last_x, self.last_y, x, y), 
                           fill=255, width=self.brush_size, joint='curve')
            
        self.last_x, self.last_y = x, y

    def reset_brush(self, event):
        self.last_x, self.last_y = None, None

    def clear(self):
        self.canvas.delete("all")
        # Reset to BLACK background (0)
        self.image = Image.new("L", (self.canvas_size, self.canvas_size), 0)
        self.draw = ImageDraw.Draw(self.image)
        self.status.config(text="Canvas Cleared.", fg="blue")

    def save_data(self):
        try:
            expected_label = int(self.label_entry.get())
            if expected_label < 0 or expected_label > 9:
                raise ValueError
        except ValueError:
            self.status.config(text="Error: Label must be a number 0-9", fg="red")
            return
            
        try:
            file_idx = int(self.index_entry.get())
        except ValueError:
            self.status.config(text="Error: File Index must be an integer", fg="red")
            return

        
        # EXACT MNIST PREPROCESSING ALGORITHM
        bbox = self.image.getbbox()
        if bbox:
            cropped = self.image.crop(bbox)
            max_dim = max(cropped.size)
            scale = 20.0 / max_dim
            new_size = (int(cropped.size[0] * scale), int(cropped.size[1] * scale))
            cropped = cropped.resize(new_size, Image.Resampling.LANCZOS)
            
            final_img = Image.new("L", (28, 28), 0)
            paste_x = (28 - new_size[0]) // 2
            paste_y = (28 - new_size[1]) // 2
            final_img.paste(cropped, (paste_x, paste_y))
        else:
            final_img = Image.new("L", (28, 28), 0)

        # Extract pixel values
        pixels = list(final_img.getdata())
        
        save_dir = r"C:\Users\SAMUDRALA HAREESH\Desktop\test_data1"
        if not os.path.exists(save_dir):
            os.makedirs(save_dir)
            
        filename = f"test_data_{file_idx:04d}.txt"
        self.last_saved_filepath = os.path.join(save_dir, filename)
        
        # Write to file exactly matching the original test data format
        with open(self.last_saved_filepath, 'w') as f:
            for p in pixels:
                normalized_pixel = p / 255.0
                dInDec = DtoB(normalized_pixel, dataWidth, fracBits)
                bin_str = bin(dInDec)[2:]
                f.write(bin_str + '\n')
                
            label_bin = bin(expected_label)[2:]
            f.write(label_bin + '\n')
            
        self.status.config(text=f"Saved {filename}. Ready to Send!", fg="green")
        
        # Auto-increment the index field
        self.index_entry.delete(0, tk.END)
        self.index_entry.insert(0, str(file_idx + 1))

    def send_to_fpga(self):
        if not self.last_saved_filepath or not os.path.exists(self.last_saved_filepath):
            self.status.config(text="Error: Please 'Save Data' first!", fg="red")
            return

        com_port = self.com_entry.get().strip()
        baud_rate = 115200

        # Update UI to show sending status
        self.status.config(text=f"Sending to FPGA on {com_port}... Please wait.", fg="orange")
        self.root.update() # Force UI update so it doesn't freeze visually

        try:
            with open(self.last_saved_filepath, 'r') as f:
                lines = [line.strip() for line in f.readlines() if line.strip()][:784]

            if len(lines) < 784:
                self.status.config(text="Error: Saved file doesn't have 784 pixels.", fg="red")
                return

            ser = serial.Serial(com_port, baud_rate, timeout=1)
            
            for pixel_bin_str in lines:
                byte_val = int(pixel_bin_str, 2)
                ser.write(bytes([byte_val]))
                time.sleep(0.002) # 2ms delay

            ser.close()
            self.status.config(text=f"✔ Sent successfully to {com_port}! Check 7-Segment Display.", fg="green")

        except serial.SerialException as e:
            self.status.config(text=f"Error: Could not open {com_port}. Check Device Manager.", fg="red")
            print(e)
        except Exception as e:
            self.status.config(text=f"Unexpected Error: {e}", fg="red")
            print(e)

if __name__ == "__main__":
    root = tk.Tk()
    app = DigitDrawer(root)
    root.mainloop()