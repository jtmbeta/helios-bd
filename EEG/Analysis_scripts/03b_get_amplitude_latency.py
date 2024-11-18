# -*- coding: utf-8 -*-
"""
Created on Mon Jul  1 08:07:56 2024

@author: jmarti2

Get Amplitude and latency measures.

Gramfort, A., Luessi, M., Larson, E., Engemann, D. A., Strohmeier, D.,
   Brodbeck, C., ... & Hämäläinen, M. S. (2014). MNE software for processing
   MEG and EEG data. neuroimage, 86, 446-460.

"""

import pathlib as pl
import re

import mne
from mne_bids import BIDSPath
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


def print_peak_measures(ch, tmin, tmax, lat, amp):
    print(f"Channel: {ch}")
    print(f"Time Window: {tmin * 1e3:.3f} - {tmax * 1e3:.3f} ms")
    print(f"Peak Latency: {lat * 1e3:.3f} ms")
    print(f"Peak Amplitude: {amp * 1e6:.3f} µV")


picks = ["POz", "Oz", "O1", "O2", "Iz"]
p1_tmin, p1_tmax = 0.08, 0.12
n1_tmin, n1_tmax = 0.1, 0.2

contrasts = {
    "Lum/1": 0.035,
    "Lum/2": 0.0626,
    "Lum/3": 0.1119,
    "Lum/4": 0.2,
    "LM/1": 0.008,
    "LM/2": 0.0142,
    "LM/3": 0.0253,
    "LM/4": 0.045,
    "S/1": 0.06,
    "S/2": 0.0972,
    "S/3": 0.1574,
    "S/4": 0.2550,
}

# contrasts = {
#     "Lum/1": 0.0396,
#     "Lum/2": 0.0742,
#     "Lum/3": 0.1390,
#     "Lum/4": 0.2603,
#     "LM/1": 0.0255,
#     "LM/2": 0.0453,
#     "LM/3": 0.0808,
#     "LM/4": 0.1437,
#     "S/1": 0.1359,
#     "S/2": 0.2201,
#     "S/3": 0.3565,
#     "S/4": 0.5775,
# }


bids_root = pl.Path(r"C:\helios_bids_vep")
figures = pl.Path(
    r"C:\Users\jmarti2\OneDrive - University of Edinburgh\wellcome\Figures"
)
bp = BIDSPath(root=bids_root)
files = list(bids_root.rglob('*task-vep_ave.fif'))

grand_df = []
for fpath in files:
    subject = re.findall(r'sub-(\d+)_', str(fpath))[0]
    evks = mne.read_evokeds(fpath)
    results = []
    for e in evks[3:15]:
        e.pick(picks)
        p1_tmin, p1_tmax = 0.08, 0.12
        if "Lum" in e.comment:
            n1_tmin, n1_tmax = 0.1575, 0.2075
        else:
            n1_tmin, n1_tmax = 0.1, 0.2

        # P1
        p1 = e.copy().crop(tmin=p1_tmin, tmax=p1_tmax)
        mean_amp_p1 = p1.data.mean() * 1e6
        peak_ind_p1 = np.unravel_index(
            np.argmax(p1.data, axis=None), p1.data.shape
        )
        peak_amp_p1 = p1.data[peak_ind_p1] * 1e6
        peak_lat_p1 = p1.times[peak_ind_p1[1]]
        peak_p1_ch = p1.ch_names[peak_ind_p1[0]]

        # N1
        n1 = e.copy().crop(tmin=n1_tmin, tmax=n1_tmax)
        mean_amp_n1 = n1.data.mean() * 1e6
        peak_ind_n1 = np.unravel_index(
            np.argmin(n1.data, axis=None), n1.data.shape
        )
        peak_amp_n1 = n1.data[peak_ind_n1] * 1e6
        peak_lat_n1 = n1.times[peak_ind_n1[1]]
        peak_n1_ch = n1.ch_names[peak_ind_n1[0]]

        # Get results together
        results.append(
            {
                "Subject": subject,
                "N1_Mean_Amp": mean_amp_n1,
                "N1_Peak_Amp": peak_amp_n1,
                "N1_Peak_Lat": peak_lat_n1,
                "N1_Peak_ch": peak_n1_ch,
                "P1_Mean_Amp": mean_amp_p1,
                "P1_Peak_Amp": peak_amp_p1,
                "P1_Peak_Lat": peak_lat_p1,
                "P1_Peak_ch": peak_p1_ch,
                "Condition": e.comment,
            }
        )
        df = pd.DataFrame(results)
    grand_df.append(df)
    
grand_df = pd.concat(grand_df)
grand_df["Event_Type"] = grand_df["Condition"].str.split("/").str.get(1)
grand_df["Stim_Type"] = grand_df["Condition"].str.split("/").str.get(0)
grand_df = grand_df.reset_index(drop=True)
grand_df["Contrast"] = grand_df["Condition"].map(contrasts)
grand_df.to_csv(bids_root / "derivatives" / "VEP_amplitudes.csv", index=None)

agg_df = grand_df.groupby(["Stim_Type", "Event_Type"], as_index=False)[
    ["P1_Mean_Amp", "N1_Mean_Amp"]
].mean()
agg_df.to_csv(bids_root / "derivatives" / "ga_VEP_amplitudes.csv", index=None)

# %%NR fits
sns.set_context('poster')
from nakarushton import FitNakaRushton

lumc = sns.color_palette("light:k", n_colors=8, as_cmap=False)[1::2]
lmc = sns.color_palette("light:r", n_colors=8, as_cmap=False)[1::2]
scc = sns.color_palette("light:b", n_colors=8, as_cmap=False)[1::2]

data = pd.read_csv(
    r"C:\helios_bids_vep\derivatives\ga_VEP_amplitudes.csv"
)

#%%

minlum = 0.035
maxlum = 0.2
cslum = np.logspace(np.log10(minlum), np.log10(maxlum), 4)



response = data.loc[data['Stim_Type'] == 'Lum', "P1_Mean_Amp"]
fine_contrast = np.linspace(0, cslum[3], 100)
fit = FitNakaRushton(
    cslum,
    abs(response.values),
    guess=[np.mean(cslum[3]), 2, .01, abs(response.values[3])],
)
predict = fit.eval(fine_contrast)
fig, ax = plt.subplots(figsize=(5,4))
sns.pointplot(
    data=grand_df.loc[grand_df.Stim_Type=='Lum'],
    x="Contrast",
    y="P1_Mean_Amp",
    #hue="Stim_Type",
    marker="o",
    linestyle="",
    #dodge=0.1,
    palette=lumc,
    ax=ax,
    #err_kws=err_kws,
    # log_scale=(10,0),
    native_scale=True,
)
ax.plot(fine_contrast, predict, c='k')
ax.set(ylabel='Mean amplitude ($\mu$V)', title='Lum: P1', xlabel='DKL radius')
fig.savefig(figures / "Lum_nr_p1.svg", bbox_inches='tight')

#%%

minlum = 0.035
maxlum = 0.2
cslum = np.logspace(np.log10(minlum), np.log10(maxlum), 4)


response = data.loc[data['Stim_Type'] == 'Lum', "N1_Mean_Amp"]
fine_contrast = np.linspace(0, cslum[3], 100)
fit = FitNakaRushton(
    cslum,
    abs(response.values),
    guess=[np.mean(cslum[3]), 2, .01, abs(response.values[3])],
)
predict = fit.eval(fine_contrast)
fig, ax = plt.subplots(figsize=(5,4))
sns.pointplot(
    data=grand_df.loc[grand_df.Stim_Type=='Lum'],
    x="Contrast",
    y="N1_Mean_Amp",
    #hue="Stim_Type",
    marker="o",
    linestyle="",
    palette=lumc,
    ax=ax,
    native_scale=True,
)
ax.plot(fine_contrast, predict*-1, c='k')
ax.set(ylabel='Mean amplitude ($\mu$V)', ylim=(-3,0), xlabel='DKL radius', title='Lum: N1')
fig.savefig(figures / "Lum_nr_n1.svg", bbox_inches='tight')

#%% LM N1
minlm = 0.008
maxlm = 0.045
cslm = np.logspace(np.log10(minlm), np.log10(maxlm), 4)


response = data.loc[data['Stim_Type'] == 'LM', "N1_Mean_Amp"]
fine_contrast = np.linspace(0, cslm[3], 100)
fit = FitNakaRushton(
    cslm,
    abs(response.values),
    guess=[np.mean(cslm[3]), 2, .01, abs(response.values[3])],
)
predict = fit.eval(fine_contrast)
fig, ax = plt.subplots(figsize=(5,4))
sns.pointplot(
    data=grand_df.loc[grand_df.Stim_Type=='LM'],
    x="Contrast",
    y="N1_Mean_Amp",
    marker="o",
    linestyle="",
    palette=lmc,
    ax=ax,
    native_scale=True,
)
ax.plot(fine_contrast, predict*-1, c='r')
ax.set(ylabel='Mean amplitude ($\mu$V)', xlabel='DKL radius', title='L-M: N1')
fig.savefig(figures / "LM_nr_n1.svg", bbox_inches='tight')

#%% S
mins = 0.06
maxs = 0.255
css = np.logspace(np.log10(mins), np.log10(maxs), 4)

response = data.loc[data['Stim_Type'] == 'S', "N1_Mean_Amp"]
fine_contrast = np.linspace(0, css[3], 100)
fit = FitNakaRushton(
    css,
    abs(response.values),
    guess=[np.mean(css[3]), 2, .01, abs(response.values[3])],
)
predict = fit.eval(fine_contrast)
fig, ax = plt.subplots(figsize=(5,4))
sns.pointplot(
    data=grand_df.loc[grand_df.Stim_Type=='S'],
    x="Contrast",
    y="N1_Mean_Amp",
    marker="o",
    linestyle="",
    palette=scc,
    ax=ax,
    native_scale=True,
)
ax.plot(fine_contrast, predict*-1, c='b')
ax.set(ylabel='Mean amplitude ($\mu$V)', xlabel='DKL radius', title='S-(L+M): N1')
fig.savefig(figures / "S_nr_n1.svg", bbox_inches='tight')

