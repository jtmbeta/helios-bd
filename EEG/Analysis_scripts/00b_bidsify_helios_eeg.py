# -*- coding: utf-8 -*-
"""
Created on Thu May  2 10:14:49 2024

@author: jmarti2

This script creates the HELIOS-BD eeg data structure if it does not exist for 
the specified subject(s). If the data structure does exist, the data for the 
specified subjects are added (or overwritten) in BIDS format. See the following 
references for further detail:

Pernet, C., Appelhoff, S., Flandin, G., Phillips, C., Delorme, A., & 
    Oostenveld, R. (2019). BIDS-EEG: an extension to the Brain Imaging Data 
    Structure (BIDS) Specification for electroencephalography.
    
Appelhoff, S., Sanderson, M., Brooks, T. L., van Vliet, M., Quentin, R., 
    Holdgraf, C., ... & Jas, M. (2019). MNE-BIDS: Organizing 
    electrophysiological data into the BIDS format and facilitating their 
    analysis. Journal of Open Source Software, 4(44).
    
Gramfort, A., Luessi, M., Larson, E., Engemann, D. A., Strohmeier, D.,
   Brodbeck, C., ... & Hämäläinen, M. S. (2014). MNE software for processing
   MEG and EEG data. neuroimage, 86, 446-460.

"""

import pathlib as pl
from pprint import pprint
import json

import numpy as np
import mne
from mne_bids import (
    BIDSPath,
    write_raw_bids,
    make_dataset_description,
)

# %matplotlib qt


# Assuming the helios datastore \\cmvm.datastore.ed.ac.uk\cmvm\scs\groups\HELIOS-BD
# is mapped to Z:\
datastore = pl.Path(r"Z:\Part B")

# Specify which subjects to work with
subjects = [
    "2006"
]

# Can be ['ssvep'], ['vep'], or ['ssvep', 'vep'] depending on which data are
# available for the specified subjects.
task = "vep"

# bids_root = datastore / "helios_bd_eeg" - this is where the data should be 
# written to. If it does not exist, it will be created. 
bids_root = pl.Path(rf"C:\helios_bids_{task}")

# Event lables/codes
event_id = {
    "Lum/1": 1,
    "Lum/2": 2,
    "Lum/3": 3,
    "Lum/4": 4,
    "LM/1": 5,
    "LM/2": 6,
    "LM/3": 7,
    "LM/4": 8,
    "S/1": 9,
    "S/2": 10,
    "S/3": 11,
    "S/4": 12,
    "Bad": 999,
}


# Loop over the subjects
for sub in subjects:
    # Say what is happening
    print(f"***** {sub}: {task} *****")
    
    # Get the BDF filename
    fname = datastore / f"{task.upper()}_data/{sub}_{task.upper()}.bdf"
    
    # Load the raw data
    raw = mne.io.read_raw_bdf(
        input_fname=fname,
        # TODO -- figure out a way to include these in analysis -- on ignore?
        misc=[
            "EXG1",
            "EXG2",
            "EXG3",
            "EXG4",
            "EXG5",
            "EXG6",
            "EXG7",
            "EXG8",
        ],
        infer_types=True,
    )
    
    # Find the events
    events = mne.find_events(
        raw, stim_channel="Status", initial_event=False
    )

    # TODO: double check this with Jasna's scripts
    # Get the conditions as they are not correctly defined
    # trialnum / condition / angle / hit / RT
    result = np.loadtxt(
        datastore / f"{task.upper()}_data/{sub}_{task.upper()}.result"
    )
    # Here we fix any known problems with the events.
    if len(result) != len(events):
        if sub == "1017" and task == "vep":
            # Script froze and some trials at the end of block 11 were lost
            # during a pause, while three of them ocurred when participant
            # was not looking. We will edit the behavioral file accordingly
            # -- first 56 trials in that block are OKand the next three
            # should be discarded - but there were early button presses on
            # each so will be thrown away anyway. No need to do anything
            # else.
            result = np.vstack(
                [result[0 : 66 * 10 + 59, :], result[66 * 11 :]]
            )
        elif sub == "1017" and task == "ssvep":
            # First two trials missing as the participant started the task
            # before we started the recording
            result = result[2:, :]
        elif sub == "1023" and task == "vep":
            # An SSVEP practice block was recorded erroneously at the end
            # as we forgot to stop the VEP recording before starting SSVEP
            events = events[0:792:, :]
        elif sub == "1026" and task == "vep":
            # An SSVEP practice block was recorded erroneously at the end
            # as we forgot to stop the VEP recording before starting SSVEP
            events = events[0:792:, :]
        elif sub == "3001" and task == "vep":
            # An SSVEP practice block was recorded erroneously at the end
            # as we forgot to stop the VEP recording before starting SSVEP
            events = events[0:792:, :]
        elif sub == "3012" and task == "ssvep":
            # Practice trials were recorded erroneoulsy at start of exp
            events = events[16:]
        else:
            print("Incorrect number of events! Please check and fix.")

    # Exclude incorrect trials and those with button presses
    for i in range(len(result)):
        if result[i, 4] != 0:  # If RT is not 0
            events[i, 2] = 999  # Throw away
        elif result[i, 2] == 0:  # If target (horizontal)
            events[i, 2] = 999  # Throw away
        else:
            events[i, 2] = result[i, 1]

    # Do the bids
    bids_path = BIDSPath(subject=sub, task=task, root=bids_root)

    # Set the montage
    bs_montage = mne.channels.make_standard_montage("biosemi64")
    raw.info["line_freq"] = (
        50  # Specify power line frequency as required by BIDS.
    )
    # Write the BIDS
    write_raw_bids(
        raw,
        bids_path=bids_path,
        events=events,
        event_id=event_id,
        montage=bs_montage,
        overwrite=True,
        verbose=False,
    )

# %% Add dataset description

how_to_acknowledge = """\
If you reference this dataset in a publication, please acknowledge its \
authors, etc."""

make_dataset_description(
    path=bids_path.root,
    name=task,
    authors=["Joe Blogs"],
    how_to_acknowledge=how_to_acknowledge,
    acknowledgements="""\
Thanks to recruitment organizations, etc.""",
    data_license="",
    ethics_approvals=[""],  # noqa: E501
    funding=["Wellcome 226787/Z/22/Z"],
    references_and_links=[],
    doi="",
    overwrite=True,
)

desc_json_path = bids_path.root / "dataset_description.json"
with open(desc_json_path, "r", encoding="utf-8-sig") as fid:
    pprint(json.loads(fid.read()))
