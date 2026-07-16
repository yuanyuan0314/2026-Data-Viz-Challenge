# Fruit and Tree Nut: From Branch to Buyer

**Small-Producer Market Access (SPMA) Index**
2026 USDA AMS × AAEA GSS Data Visualization Challenge

Pragati Dahal · Xiaoyi Zhao · Yuanyuan Wen (Virginia Tech)

---

## Overview

Fresh fruit and tree nut growers face steep barriers to market: perishable products, cold-chain costs, and limited bargaining power with large buyers. **Food hubs** aggregate produce from small farms and connect it to buyers, but evidence on how much they improve market access is thin.

We build a county-level **Small-Producer Market Access (SPMA) index** that combines two channels of sales — direct-to-consumer and food-hub intermediated — each discounted by the distance a producer would travel to reach the nearest outlet. The gravity-style distance discount reflects that transport cost and quality loss rise steeply with distance for fresh produce.

$$\text{SPMA}_i = \frac{\text{DTC Sales}_i}{\left(d^{\text{FM}}_i\right)^2} + \frac{\text{Hub Sales}_i}{\left(d^{\text{Hub}}_i\right)^2}$$

**Deliverables**

1. **`fig_01.pdf`** — national county-level choropleth of SPMA, with food hub locations overlaid.
2. **`fig_02.pdf`** — county-pair spider charts comparing high- and low-access counties, including a simulation of how access would shift if a food hub were added nearby.

---

## Data

| Source | Role |
|---|---|
| FAME 2.0 Master Data | County-level sales and direct-to-consumer shares |
| USDA AMS Food Hub Directory | Food hub locations |
| USDA AMS Farmers Market Directory | Farmers market locations |
| Census TIGER/Line (2023) | County boundaries and centroids |
| 2022 Census of Agriculture (NASS QuickStats) | Fruit and tree nut share of sales |

Distances are measured from county centroids to the nearest outlet, since producer locations are not public. Analysis covers the continental US.

---

## Code

Code lives in `programs/`, with `cl_` files handling cleaning and `an_` files producing the index and figures. Data flows one direction:

```
data/source/  →  cl_*  →  data/outcome/  →  an_*  →  figures/
```

| File | Output |
|---|---|
| `cl_01_fame.Rmd` | `fame_variables.csv` |
| `cl_01_distance.Rmd` | `hub_distance_full.csv` |
| `cl_01_farmersmarket_distance.Rmd` | `farmersmarket_distance_full.csv` |
| `cl_02_merge.Rmd` | `distance_SPMA_merged.csv` |
| `an_01.Rmd` | `spma_index.csv` |
| `an_02.Rmd` | `figures/fig_01.pdf` |
| `an_03.Rmd` | `figures/fig_02.pdf` |

---

## Reproducing

```r
install.packages(c(
  "tidyverse", "sf", "tigris", "units", "tidycensus", "terra",
  "ggplot2", "scales", "ggnewscale", "ggtext", "patchwork",
  "showtext", "sysfonts", "ggimage", "rsvg", "magick", "ragg"
))
devtools::install_github("ricardo-bion/ggradar")   # not on CRAN
```

A free NASS QuickStats API key is required. Open the `.Rproj`, confirm `data/source/` holds the raw inputs, then knit the `cl_*` files in order followed by `an_01`–`an_03`. Each file is knit from its own directory.

---

## Use of generative AI

*[section to be completed]*
