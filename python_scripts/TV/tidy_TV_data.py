# script for converting matlab output to format suited for $readmemH() SystemVeriog function
import re
import os

########################################################################################################################
# HELPERS                                                                                                              #
########################################################################################################################

# functions for processing waves and saving them to files
def convert_and_write_to_file(dir_path, file_obj):
    for key, value in file_obj.get_waves().items():
        value_split = value.split()
        with open(dir_path+key, "w") as file:
            for element in value_split:
                file.write(f'{element}\n')

def convert_th_and_write_to_file(dir_path, file_obj):
    for key, value in file_obj.get_waves().items():
        value_split = []
        for val in value:
            value_split.append(val)
        with open(dir_path+key, "w") as file:
            for element in value_split:
                file.write(f'{element}\n')

# class for storing unprocessed waves and its filenames
class Wave_file:
    def __init__(self, name):
        self.wave = {}
        self.waves_cnt = 0
        self.name = name

    def add_wave(self, name, vals):
        if name not in self.wave.keys():
            self.wave[name] = vals # dict({name : vals})
            self.waves_cnt = self.waves_cnt + 1
    
    def get_waves(self, switch=None):
        if switch == "vals":
            return self.wave.values()
        elif switch == "names" or switch == "keys":
            return self.wave.keys()
        else:
            return self.wave
            
    def info(self):
        return (f'file type: {self.name}', f'number of waves in file: {self.waves_cnt}')

########################################################################################################################
# MAIN CODE                                                                                                            #
########################################################################################################################
TV_DIRECTORY = "../../matlab/TV/"
PROCESSED_TV_DIR = "./PROCESSED_TV/"

directory = os.fsencode(TV_DIRECTORY)

width_file    = Wave_file("width variable wave file")
width_th_file = Wave_file("width variable wave thresholds file")
amp_file      = Wave_file("amplitude variable wave file")
amp_th_file   = Wave_file("amplitude variable wave thresholds file")

for file in os.listdir(directory):
    filename = os.fsdecode(file)
    file_path = TV_DIRECTORY+filename
    if "width" in filename:
        if "threshold" in filename:
            with open(file_path, "r") as file_readable:
                width_th_file.add_wave(filename, file_readable.read())
        else:
            with open(file_path, "r") as file_readable:
                width_file.add_wave(filename, file_readable.read())
    elif "amplitude" in filename:
        if "threshold" in filename:
            with open(file_path, "r") as file_readable:
                amp_th_file.add_wave(filename, file_readable.read())
        else:
            with open(file_path, "r") as file_readable:
                amp_file.add_wave(filename, file_readable.read())


convert_and_write_to_file(PROCESSED_TV_DIR, width_file)
convert_and_write_to_file(PROCESSED_TV_DIR, amp_file)
convert_th_and_write_to_file(PROCESSED_TV_DIR, amp_th_file)
convert_th_and_write_to_file(PROCESSED_TV_DIR, width_th_file)