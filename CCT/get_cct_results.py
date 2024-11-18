# -*- coding: utf-8 -*-
"""
Created on Tue Jun  4 14:09:39 2024

@author: jmarti2

This script loads the results of the Cambridge Colour (CCT) Test for
each participant, puts them in a DataFrame, and creates a swarm plot.

For further information on the CCT, see:

Mollon, J. D., & Reffin, J. P. (1989). A computer-controlled colour 
    vision test that combines the principles of Chibret and Stilling. 
    J Physiol, 414(5).

"""
import matplotlib.pyplot as plt
import seaborn as sns

import pathlib as pl
import pandas as pd


# Assuming the helios datastore \\cmvm.datastore.ed.ac.uk\cmvm\scs\groups\HELIOS-BD
# is mapped to Z:\
cctpath = pl.Path(r"Z:\Part B\CCT_data")

figures = pl.Path(
    r"C:\Users\jmarti2\OneDrive - University of Edinburgh\wellcome\Figures"
)

files = cctpath.glob("*.txt")
df = []
for f in files:
    subject = f.stem
    print(subject)
    cct = pd.read_table(f, header=None)
    vals = cct.loc[30:32, 0].str.split(",")
    vals = vals.str.get(1).str.strip().to_list()
    df.append(
        {
            "Subject": subject,
            "Protan": int(vals[0]),
            "Deutan": int(vals[1]),
            "Tritan": int(vals[2]),
        }
    )

df = pd.DataFrame(df)
df_long = df.melt(id_vars="Subject", value_vars=["Protan", "Deutan", "Tritan"])
df_long.loc[df_long.Subject.str.startswith("1"), "Group"] = "Control"
df_long.loc[df_long.Subject.str.startswith("8"), "Group"] = "Control"
df_long.loc[df_long.Subject.str.startswith("2"), "Group"] = (
    "Bipolar with Lithium"
)
df_long.loc[df_long.Subject.str.startswith("3"), "Group"] = (
    "Bipolar without Lithium"
)

# Drop deuteranope
df_long = df_long.loc[df_long.Subject!='802']
# Initialize the figure
sns.set_context('poster')
sns.set_style('ticks')
f, ax = plt.subplots(figsize=(4,3))
# Add points to show each observation
sns.swarmplot(
    data=df_long.loc[((df_long.Subject.str.startswith('1'))|(df_long.Subject.str.startswith('8')))],
    x="value",
    y="variable",
    # hue="variable",
    size=4,
    color='blue',
    # palette={
    #     "Protan": "tab:red",
    #     "Deutan": "tab:green",
    #     "Tritan": "tab:blue",
    # },
    edgecolor="gray",
    legend=False,
    ax=ax,
    alpha=.8,
    marker='o'
)

sns.swarmplot(
    data=df_long.loc[df_long.Subject.str.startswith('2')],
    x="value",
    y="variable",
    # hue="variable",
    size=4,
    color='red',
    # palette={
    #     "Protan": "tab:red",
    #     "Deutan": "tab:green",
    #     "Tritan": "tab:blue",
    # },
    edgecolor="gray",
    legend=False,
    ax=ax,
    alpha=.8,
    marker='o'
)

sns.swarmplot(
    data=df_long.loc[df_long.Subject.str.startswith('3')],
    x="value",
    y="variable",
    # hue="variable",
    size=4,
    color='yellow',
    # palette={
    #     "Protan": "tab:red",
    #     "Deutan": "tab:green",
    #     "Tritan": "tab:blue",
    # },
    edgecolor="gray",
    legend=False,
    ax=ax,
    alpha=.8,
    marker='o'
    )
sns.boxplot(data=df_long.loc[((df_long.Subject.str.startswith('1'))|(df_long.Subject.str.startswith('8')))],
            x="value",
            y="variable",

            ax=ax,
            showfliers=False,
            color='gray'
            )

# Tweak the visual presentation
#ax.xaxis.grid(True)
ax.set(ylabel="", xlabel="Score", title="CCT Results")
#sns.despine(trim=True, left=True)
#ax.vlines(100, -0.5, 1.5, ls=':', lw=1, color='k')
#ax.vlines(150, 1.5, 2.5, ls=':', lw=1, color='k')


# Find and annotate outliers. Normal test scores are under 100 for Protan and Deutan
# and under 150 for Tritan
ytick_loc = {v.get_text(): v.get_position()[1] for v in ax.get_yticklabels()}
df_long["ytick_loc"] = df_long.variable.map(ytick_loc)
outliers = df_long[df_long.value.gt(100)].copy()
print(outliers)
# for _, (sub, var, val, y, g) in outliers.iterrows():
#     ax.text(
#         val + 10,
#         y,
#         s=sub,
#         horizontalalignment="left",
#         size="medium",
#         color="black",
#         verticalalignment="center",
#         linespacing=1,
#     )

f.savefig(figures / "CCT_results.svg", bbox_inches='tight')

