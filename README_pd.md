# Fruit and Tree Nut: From Orchard to Opportunity

**Small-Producer Market Access (SPMA) Index**\
2026 USDA AMS × AAEA GSS Data Visualization Challenge

Pragati Dahal · Xiaoyi Zhao · Yuanyuan Wen (Virginia Tech)

***

## What this project does

Market access is a persistent challenge for small fresh-produce farmers. Because their
products are perishable, fruit and tree nut growers face higher transportation costs
from cold-chain requirements, higher entry costs and risk in maintaining orchards, and
less bargaining power with large supply chains. **Food hubs** are intermediaries that
aggregate produce from multiple farmers and redistribute it to buyers. Funding for hubs
has grown in recent years, but there is limited evidence on how much they actually
improve market access.

We build a county-level **Small-Producer Market Access (SPMA)** index to estimate that
effect:

$$\text{SPMA}_i = \frac{\text{DTC Sales}_i}{\left(d^{\text{FM}}_i\right)^2} + \frac{\text{Food Hub Intermediated Sales}_i}{\left(d^{\text{Hub}}_i\right)^2}$$

| Term | Definition |
|---|---|
| $\text{DTC Sales}_i$ | `all_sales` × `d2c_sales_pct` / 100 |
| $\text{Food Hub Intermediated Sales}_i$ | `all_sales` × (100 − `d2c_sales_pct`) / 100 |
| $d^{\text{FM}}_i$ | Miles from county centroid to nearest farmers market |
| $d^{\text{Hub}}_i$ | Miles from county centroid to nearest food hub |

Each sales channel is discounted by the squared distance to its outlet, following
standard gravity-model practice which is suitable for fresh produce, where transport
cost and quality loss rise faster than proportionally with distance. Producer locations
are not public, so the county centroid approximates the average haul.

**Deliverables:**

1. A national county-level choropleth map with food hubs overlaid.
2. County-pair spider charts contrasting counties with high vs. low food hub access,
   including a simulation of how access would change if a food hub were added.

***

## 1. Data sources

Raw inputs are in `data/source/`. They are read but never modified by our code.

| Source | File | What it contains | Why it matters |
|---|---|---|---|
| **FAME 2.0 Master Data** | `FAME_MasterData_Feb2026.csv` | Long-format county panel: one row per county × variable × year. We extract 23 variables covering farm sales, sales-channel shares, outlet counts, and county characteristics. | Core dataset for the challenge. Supplies every non-spatial input to the index. |
| **USDA AMS Food Hub Directory** | `foodhub_2026-75161420.xlsx` | Point-level directory of US food hubs. | Hub coordinates produce $d^{\text{Hub}}$, denominator of the intermediated-sales term, and the point overlay on the choropleth. |
| **USDA AMS Farmers Market Directory** | `farmersmarket_2026-623143939.xlsx` | Point-level directory of US farmers markets. | Market coordinates produce $d^{\text{FM}}$, denominator of the direct-to-consumer term. |
| **Census TIGER/Line** (2023) | *not committed — pulled at runtime* | 2023 cartographic-boundary county and state polygons. | County polygons give the centroids anchoring every distance calculation, the `GEOID` that joins spatial data to FAME `fips`, and the map geometry. |
| **2022 Census of Agriculture** | `fruitnut_share.csv` | County-level fruit and tree nut sales, total farm sales, and the fruit/nut share of sales. | Supplies the `Fruit Nut Share` axis in the spider charts. |

**How each source was accessed**

- **FAME 2.0 Master Data** — downloaded from the Data Viz Challenge Dropbox folder
  provided to participants.
- **Food Hub Directory** — `https://www.usdalocalfoodportal.com/fe/fdirectory_foodhub/`.
- **Farmers Market Directory** —
  `https://www.usdalocalfoodportal.com/fe/fdirectory_farmersmarket/`
- **Census TIGER/Line** — downloaded programmatically at runtime via the `tigris` R
  package.
- **2022 Census of Agriculture** — pulled programmatically from the USDA NASS QuickStats
  API (`https://quickstats.nass.usda.gov/api/api_GET/`). Requires a free API key.

***
## 3. Code structure

All code is in `programs/`. Prefixes mark the stage: `cl_` clean · `an_` analysis and figure generation.
Paths are relative, so each file must be knit from its own directory.

| File | Purpose |
|---|---|
| `cl_01_fame.Rmd` | Subsets FAME to 23 variables, takes the latest year per variable, pivots wide → `fame_variables.csv` |
| `cl_01_distance.Rmd` | County centroids + nearest food hub distance → `hub_distance_full.csv` |
| `cl_01_farmersmarket_distance.Rmd` | Nearest farmers market distance, reusing those centroids → `farmersmarket_distance_full.csv` |
| `cl_02_merge.Rmd` | Joins the three cleaned tables → `distance_SPMA_merged.csv` |
| `an_01.Rmd` | Builds the SPMA index → `spma_index.csv` |
| `an_02_spma_simulation.Rmd` | Builds the SPMA index for county comparisons → `spma_index_greenville_lee.csv` \& `spma_index_yakima_okanogan.csv`|
| `fig_01.Rmd` | National choropleth → `fig_01.pdf` |
| `fig_02.Rmd` | County-pair spider charts → `fig_02.pdf` |

Data flows one direction: `data/source/` → `cl_*` → `data/outcome/` → `an_*` →
`figures/`.

***

## 3. Data transformations

### 3.1 Reshaping FAME

*Source file: `cl_01_fame.Rmd`*

FAME arrives in long format: one row per county, per variable, per year, so before we
can use it, it has to become one row per county.

1. **Keep only what we need.** Filter the file down to our 23 variables. A check runs
   first to confirm every variable name we asked for actually exists in the file,
   guarding against typos in the list.

2. **Pick a year for each variable.** No single year covers all 23 variables, so forcing
   a common year would throw away a lot of counties. Instead, each variable contributes
   its most recent available observation for that county.

3. **Reshape from long to wide.** One row per county, one column per variable.

→ `data/outcome/fame_variables.csv`

### 3.2 Distances 

*Source files: `cl_01_distance.Rmd` and `cl_01_farmersmarket_distance.Rmd`*

These two scripts answer one question for every county: **how far would a producer have
to travel to reach the nearest farmers market, and the nearest food hub?**

1. **Find a point for each county.** Download 2023 county boundaries and take the
   centroid of each one. Producer locations are not public, so the centroid stands in
   for the "average" farm in the county.

2. **Put everything on the same map.** Counties and directory listings are converted to
   a common projection — EPSG:5070, an equal-area projection measured in metres and
   designed for the continental US. Distances are only meaningful once both layers sit
   in the same coordinate system. Listings with missing coordinates are dropped.

3. **Measure every county against every outlet.** Compute the full distance matrix from
   each county centroid to each food hub, and separately to each farmers market, then
   keep the smallest distance in each row. That is the nearest outlet. Distances are
   converted from metres to miles.

   The nearest outlet **does not have to be in the same county**. A county with no hub
   of its own is matched to the closest hub across the border, which is the point: we
   are measuring travel distance, not counting what sits inside county lines.

4. **Attach details about the nearest outlet** — which county it sits in, and what
   products it handles.

5. **Flag the hard-to-reach counties.** `hub_desert` marks counties whose nearest hub is
   20+ miles away.

6. **Drop places we cannot measure well.** Territories are excluded. Alaska and Hawaii
   are dropped too, as they fall outside the projection's intended area, so distances
   there come out badly distorted (one Aleutian county produced an implausible
   ~1,000-mile result).

The farmers market script reuses the county centroids saved by the hub script, so both
distances are measured from exactly the same starting points.

→ `data/outcome/hub_distance_full.csv`, `data/outcome/farmersmarket_distance_full.csv`

### 3.3 Putting it together — `cl_02_merge.Rmd`

*Source files: `cl_02_merge.Rmd`*

Three cleaned tables become one analysis table, joined on the county's 5-digit FIPS
code:

| Input | What it brings | Joins on |
|---|---|---|
| `hub_distance_full.csv` | Hub distances, county centroids | `GEOID` |
| `fame_variables.csv` | The FAME variables, one row per county | `fips` |
| `farmersmarket_distance_full.csv` | Farmers market distances | `GEOID` |

FIPS codes are zero-padded to 5 digits first, so that codes with a leading zero survive
the join. The result is 3,144 counties by 46 columns.

→ `data/outcome/distance_SPMA_merged.csv`

### 3.4 Filling gaps in the sales shares

To split a county's sales into "sold direct to consumers" and "sold through an
intermediary," the natural columns are `d2c_sales_pct` and `intermediated_sales_pct`.
The problem: `intermediated_sales_pct` is missing for a large share of counties, while
`d2c_sales_pct` and `all_sales` are among the best-populated variables in FAME.

**So we treat everything not sold direct-to-consumer as intermediated**, that is, we
compute the intermediated share as `100 − d2c_sales_pct` rather than reading the sparse
column directly.

This buys us far more usable counties, and it costs precision: sales that went to a
distant wholesaler, not a local food hub, get counted in the intermediated bucket too.
In counties with large commodity operations, this overstates the sales a food hub could
plausibly be handling.

**One more wrinkle:** a handful of counties report a direct-to-consumer share above 100%
in FAME data, which is impossible and would produce a negative intermediated share.
Those counties are set to missing and drop out of the index.

***


## 4. Building our deliverables

### 4.1 Building the index — `an_01.Rmd`

1. Convert the direct-to-consumer percentage into a proportion.
2. Split total sales into the two channels: DTC sales and intermediated sales.
3. Divide each by the squared distance to its matching outlet, i.e. DTC by the farmers
   market distance, intermediated by the food hub distance.
4. Add the two together. That sum is SPMA.

Counties missing the direct-to-consumer piece are dropped.

**Why the map is drawn on a log scale.** Raw SPMA is dollars divided by squared miles,
so it spans more than ten orders of magnitude: a dense county with high sales and a hub
next door is thousands of times larger than a remote one. Plotted untransformed, the map
is one dark dot on an otherwise blank field. So for display we take `log(SPMA + 1)`,
rescale to a 0–100 range, and cap the color scale at the 95th percentile.

→ `data/outcome/spma_index.csv`

### 4.2 Preparing the choropleth map — `an_02.Rmd`

The national map shades every county by its SPMA score and marks where the food hubs
actually are. Turning the index table into that map takes a few steps:

1. **Get the map shapes.** Download 2023 county and state boundaries and project them to
   EPSG:5070, the same equal-area projection used for the distance calculations, so the
   map is not distorted.

2. **Keep the lower 48.** Alaska, Hawaii, and the territories are dropped. They were
   already excluded from the index, and including them would shrink the continental US
   to a corner of the frame.

3. **Attach the scores to the shapes.** Join the index table to the county polygons on
   FIPS code. Counties with no score stay on the map in grey rather than disappearing —
   a blank county and a low-scoring county mean different things, and the caption reports
   how many are blank.

4. **Plot the food hubs on top.** The hub directory is loaded again, converted to map
   points, and drawn as dots over the shading. This lets a reader see the index and its
   main driver at the same time: dark counties tend to sit near clusters of dots.

5. **Shade the counties.** Fill color comes from the 0–100 rescaled index described in
   §4.1, on a light-to-dark blue scale, with the scale capped at the 95th percentile.

→ `figures/fig_01.pdf`

### 4.3 Preparing the spider charts — `an_03.Rmd`

The spider charts compare two counties across six measures at once. Those measures come
in incompatible units — dollars, miles, percentages — so plotting raw values on shared
axes would be meaningless.

**Every axis is converted to a percentile rank** across all counties in the sample. An
axis value of 0.9 means "this county is in the 90th percentile nationally on this
measure." Distance measures are flipped before ranking, so that on every axis, **further
out always means better access**, otherwise "close to a hub" would point inward while
"high sales" pointed outward, and the shapes would be unreadable.

Axes: Direct To Consumer Share · Close to Foodhub · Close to Farmer's Market · Foodhub
Intermediated Share · SPMA · Fruit Nut Share

A natural follow-up question is what would change if a county gained a food hub, or lost
one. Because SPMA is built from distance to the nearest hub, we can answer that directly:
add a hub to the directory, recompute the distances, and recompute the index. We apply
this to a pair of peach-producing counties in Georgia and South Carolina as well as apple-producing
counties in Washington. The spider chart shows each county's current position and 
its simulated position side by side.

**These are simulated hubs, not planned or proposed ones.** The exercise illustrates how market accessibility 
would change due to establishment of a hub closer to the farms.

→ `figures/fig_02.pdf`

***

## 5. Reproducing our deliverables

**Requirements**

```r
install.packages(c(
  "tidyverse", "sf", "tigris", "units", "tidycensus", "terra",
  "ggplot2", "scales", "ggnewscale", "ggtext", "patchwork",
  "showtext", "sysfonts", "ggimage", "rsvg", "magick", "ragg"
))
devtools::install_github("ricardo-bion/ggradar")   # not on CRAN
```

A free NASS QuickStats API key is also needed to pull the fruit/nut share data
(see §1).

**Steps**

1. Clone the fork, open `2026-Data-Viz-Challenge-main.Rproj`, and confirm `data/source/`
   holds the raw inputs from §1.
2. Set `options(tigris_use_cache = TRUE)` so boundaries download only once.
3. Knit in order:

   ```
   cl_01_fame.Rmd                     →  fame_variables.csv
   cl_01_distance.Rmd                 →  hub_distance_full.csv
   cl_01_farmersmarket_distance.Rmd   →  farmersmarket_distance_full.csv
   cl_02_merge.Rmd                    →  distance_SPMA_merged.csv
   ```

4. Then build the index and the figures:

   ```
   an_01.Rmd   →  spma_index.csv        SPMA index
   an_02.Rmd   →  figures/fig_01.pdf    national choropleth
   an_03.Rmd   →  figures/fig_02.pdf    county spider charts
   ```

***

## 6. Use of generative AI

We used generative AI (Claude) as a general-purpose coding assistant: tidying and reorganizing R code, 
resolving errors, and editing documentation. It was not used to design the index, select variables, or interpret results. 
All outputs were reviewed and verified by the authors.
