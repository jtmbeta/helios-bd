# -*- coding: utf-8 -*-
"""
Created on Wed May 29 10:36:12 2024

@author: jmarti2

This script uses mne_icalabel to label the ica components. Run this after
running the pipeline, and then run the pipeline again to ensure that the 'bad'
components are removed in the analysis.

Li, A., Feitelberg, J., Saini, A. P., Höchenberger, R., & Scheltienne, M. 
    (2022). MNE-ICALabel: Automatically annotating ICA components with ICLabel 
    in Python. Journal of Open Source Software, 7(76), 4484.
    
Gramfort, A., Luessi, M., Larson, E., Engemann, D. A., Strohmeier, D.,
   Brodbeck, C., ... & Hämäläinen, M. S. (2014). MNE software for processing
   MEG and EEG data. neuroimage, 86, 446-460.

"""

import pandas as pd
import mne
import mne_icalabel


subjects = [
    "2006"
]

#subjects = ["3001","3011","3012"]

# bids_root = op.join("../helios_bd_eeg/derivatives")
# subject = '1005'
task = 'ssvep'

# bids_path = BIDSPath(subject=subject, task=task, root=bids_root)
# mne_icalabel.annotation.write_components_tsv(ica, fname=r'C:\Users\jmarti2\OneDrive - University of Edinburgh\wellcome\helios_bd_eeg\derivatives\mne-bids-pipeline-vep\sub-1005\eeg\sub-1005_task-vep_channels.tsv')

for sub in subjects:
    fname_ica = rf"C:\helios_bids_{task}\derivatives\mne-bids-pipeline-{task}\sub-{sub}\eeg\sub-{sub}_task-{task}_proc-icafit_ica.fif"
    fname_epo = rf"C:\helios_bids_{task}\derivatives\mne-bids-pipeline-{task}\sub-{sub}\eeg\sub-{sub}_task-{task}_epo.fif"
    epo = mne.read_epochs(fname_epo)
    ica = mne.preprocessing.read_ica(fname_ica)
    mne_icalabel.label_components(epo, ica, "iclabel")
    df = pd.read_csv(
        rf"C:\helios_bids_{task}\derivatives\mne-bids-pipeline-{task}\sub-{sub}\eeg\sub-{sub}_task-{task}_proc-ica_components.tsv",
        sep="\t",
    )

    for key in ica.labels_:
        for i in ica.labels_[key]:
            # We can extract the labels of each component and exclude non-brain
            # classified components, keeping ‘brain’ and ‘other’. “Other” is a
            # catch-all that for non-classifiable components. We will stay on 
            # the side of caution and assume we cannot blindly remove these.
            if key in ['brain','other']:
                df.loc[i, "status"] = "good"
            else:
                df.loc[i, "status"] = "bad"

            df.loc[i, "ic_type"] = key
            df.loc[i, "annotate_author"] = "jtm"
            df.loc[i, "annotate_method"] = "iclabel"
    df.to_csv(
        rf"C:\helios_bids_{task}\derivatives\mne-bids-pipeline-{task}\sub-{sub}\eeg\sub-{sub}_task-{task}_proc-ica_components.tsv",
        sep="\t",
        index=False,
    )
