# -*- coding: utf-8 -*-
"""
Created on Tue Oct 22 15:01:44 2024

@author: jmarti2

MNE-BIDS-Pipeline configuration file for analysing VEP and SSVEP data for the
HELIOS-BD project. Check the documentation online for further options and more
detailed explanations of the configuration parameters.

"""
##############################################################
# Set these values appropriately before running the pipeline 
subjects = ['2006']                                          
task = 'ssvep'                                               
##############################################################

# Sets the appropriate output directories
bids_root = fr"C:\helios_bids_{task}"
deriv_root = fr"C:\helios_bids_{task}\derivatives\mne-bids-pipeline-{task}"
subjects_dir = None

# Use to exclude subjects
exclude_subjects = []

ch_types = ["eeg"]
data_type = "eeg"
eeg_reference = "average"  # EEG reference to use
eeg_template_montage = (
    "biosemi64"  # Apply 64-channel Biosemi 10/20 template montage:
)
analyze_channels = "ch_types"
plot_psd_for_runs = "all"  # For which runs to add a power spectral density (PSD) plot to the generated report.
random_state = (
    42  # Passed to ICA and decoding algos to ensure reproduicibility
)
# Break detection
find_breaks = (
    True  # Automatically find break periods, and annotate them as BAD_break.
)
min_break_duration = 15.0
t_break_annot_start_after_previous_event = 5.0
t_break_annot_stop_before_next_event = 5.0

# Filtering
l_freq = 0.1  # The low-frequency cut-off in the highpass filtering step.
h_freq = 40.0  # The high-frequency cut-off in the highpass filtering step.
notch_freq = (50)  # Notch filter frequency. More than one frequency can be supplied
epochs_decim = 4  # Decimate epochs to 256 Hz
conditions = [
    "Lum",
    "LM",
    "S",
    "Lum/1",
    "Lum/2",
    "Lum/3",
    "Lum/4",
    "LM/1",
    "LM/2",
    "LM/3",
    "LM/4",
    "S/1",
    "S/2",
    "S/3",
    "S/4",
]

# Set the task specific parameters
if task == 'vep':
    epochs_tmin = -0.2  # The beginning of an epoch, relative to the respective event, in seconds.
    epochs_tmax = 0.8  # The end of an epoch, relative to the respective event, in seconds.
elif task == 'ssvep':
    epochs_tmin = -0.2
    epochs_tmax = 2.5
else:
    raise RuntimeError(f"Task {task} not currently supported")
    
baseline = (-0.1, 0)  # Beginning of epoch until time point zero

# Artifact removal
spatial_filter = "ica"  # Use ica
ica_reject = "autoreject_local"  # Find local (per channel) thresholds and repair epochs before fitting ICA
ica_algorithm = "picard-extended_infomax"
ica_l_freq = 1.0
ica_max_iterations = 500
ica_n_components = 64 - 1
ica_decim = None
reject = "autoreject_local"  # Before and after ICA recommended

# Sensor level analysis
contrasts = [("Lum", "S"), ("Lum", "LM"), ("LM", "S")]

if task == 'vep':
    decode = True
    decoding_time_generalization = True  # ?
    decoding_time_generalization_decim = 1
elif task =='ssvep':
    decode = False
else:
    raise RuntimeError(f"Task {task} not currently supported")

# No source estimation
run_source_estimation = False

# Execution
n_jobs = 4