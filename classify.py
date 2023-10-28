import os
import shutil
import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk
import sys

class ImageClassifierApp:
    def __init__(self, root, directory):
        self.root = root
        self.root.title("Image Classifier App")

        screen_width = root.winfo_screenwidth()
        screen_height = root.winfo_screenheight() - 40  # Reducing 40 pixels to avoid covering taskbar
        self.root.geometry(f"{screen_width}x{screen_height}+0+0")

        button_frame = tk.Frame(root)
        button_frame.pack(side=tk.TOP, fill=tk.X)

        self.keep_button = tk.Button(button_frame, text="Keep", command=self.on_keep, width=20, height=2)
        self.keep_button.pack(side=tk.LEFT, padx=10, pady=10)

        self.discard_button = tk.Button(button_frame, text="Discard", command=self.on_discard, width=20, height=2)
        self.discard_button.pack(side=tk.LEFT, padx=10, pady=10)

        self.directory = directory
        self.images = os.listdir(self.directory)
        self.current_image_index = 0

        self.image_label = tk.Label(root)
        self.image_label.pack(expand=True, fill='both')
        self.image_label.bind('<Configure>', self.resize_image)

        self.show_current_image()

    def show_current_image(self):
        if self.current_image_index < len(self.images):
            image_path = os.path.join(self.directory, self.images[self.current_image_index])
            self.image = Image.open(image_path)
            self.display_image()
        else:
            self.image_label.config(text="No more images")

    def resize_image(self, event):
        self.display_image()

    def display_image(self):
        width, height = self.image_label.winfo_width(), self.image_label.winfo_height()
        if width > 0 and height > 0:
            img_width, img_height = self.image.size
            ratio = min(width / img_width, height / img_height)
            new_width = int(img_width * ratio)
            new_height = int(img_height * ratio)
            if new_width > img_width or new_height > img_height:
                new_width = min(img_width, width)
                new_height = min(img_height, height)
            if new_width > 0 and new_height > 0:
                resized_image = self.image.resize((new_width, new_height))
                photo = ImageTk.PhotoImage(resized_image)
                self.image_label.config(image=photo)
                self.image_label.image = photo

    def on_keep(self):
        self.move_image("keep")
        self.show_next_image()

    def on_discard(self):
        self.move_image("discard")
        self.show_next_image()

    def move_image(self, destination):
        image_path = os.path.join(self.directory, self.images[self.current_image_index])
        dest_directory = os.path.join(self.directory, destination)
        if not os.path.exists(dest_directory):
            os.makedirs(dest_directory)
        shutil.move(image_path, dest_directory)

    def show_next_image(self):
        self.current_image_index += 1
        self.show_current_image()

def main():
    if len(sys.argv) != 2:
        print("Usage: python image_classifier.py path_to_your_image_directory")
        root = tk.Tk()
        root.withdraw()  # Hide the root window
        directory = filedialog.askdirectory()  # Prompt user to select a directory
        root.destroy()  # Destroy the root window after directory selection
        if not directory:  # If no directory selected, exit the program
            print("No directory selected. Exiting.")
            return

        root = tk.Tk()
        app = ImageClassifierApp(root, directory)
        root.mainloop()
    else:
        directory = os.path.abspath(os.path.normpath(sys.argv[1]))
        root = tk.Tk()
        app = ImageClassifierApp(root, directory)
        root.mainloop()

if __name__ == "__main__":
    main()
