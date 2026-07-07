# ============================================================
# Merge hub_distance_full.csv (key: GEOID) with
# SPMA_index_variables.csv (key: fips), both county-level.
# Keys are normalized to 5-digit county FIPS strings before joining.
# ============================================================
library(data.table)

base <- "D:/0 Project/2026-Data-Viz-Challenge/data/"

# hub_distance_full.csv is malformed: the last column `geometry` is an
# UNQUOTED R vector `c(x, y)`, whose internal comma splits every row into
# 13 fields vs. 12 headers. All 3144 rows split identically, so we read
# positionally (skip the header, assign our own names) and drop geometry.
names_hub <- c("rowidx","GEOID","state","county_name","distance_nearest_hub_mile",
               "nearest_hub_name","nearest_hub_id","hub_county_geoid","hub_county_name",
               "hub_products","hub_desert","centroid_x","centroid_y")
hub <- fread(file.path(base, "outcome/hub_distance_full.csv"),
             skip = 1, header = FALSE, fill = TRUE, quote = "\"",
             colClasses = "character")
stopifnot(ncol(hub) == length(names_hub))
setnames(hub, names_hub)
hub[, rowidx := NULL]
hub[, distance_nearest_hub_mile := as.numeric(distance_nearest_hub_mile)]
# clean the split centroid back into numbers (projected county centroid)
hub[, centroid_x := as.numeric(gsub("[^0-9.eE+-]", "", centroid_x))]
hub[, centroid_y := as.numeric(gsub("[^0-9.eE+-]", "", centroid_y))]

spma <- fread(file.path(base, "source/SPMA_index_variables.csv"),
              colClasses = list(character = "fips"))

# ---- normalize both keys to a 5-digit county FIPS string ----
hub[,  county_fips := sprintf("%05d", as.integer(GEOID))]
spma[, county_fips := sprintf("%05d", as.integer(fips))]

cat("hub_distance rows:", nrow(hub), "| unique county_fips:", uniqueN(hub$county_fips), "\n")
cat("SPMA rows        :", nrow(spma), "| unique county_fips:", uniqueN(spma$county_fips), "\n")

# ---- diagnostics: key overlap ----
only_hub  <- setdiff(hub$county_fips,  spma$county_fips)
only_spma <- setdiff(spma$county_fips, hub$county_fips)
cat("counties in both      :", length(intersect(hub$county_fips, spma$county_fips)), "\n")
cat("only in hub_distance  :", length(only_hub),
    if (length(only_hub))  paste0(" e.g. ", paste(head(only_hub, 5),  collapse = ", ")) else "", "\n")
cat("only in SPMA          :", length(only_spma),
    if (length(only_spma)) paste0(" e.g. ", paste(head(only_spma, 5), collapse = ", ")) else "", "\n")

# ---- merge (inner join on county_fips) ----
merged <- merge(hub, spma, by = "county_fips",
                all = FALSE, suffixes = c("_hub", "_spma"))
setcolorder(merged, "county_fips")
cat("\nmerged rows:", nrow(merged), "| columns:", ncol(merged), "\n")

out <- file.path(base, "outcome/hub_distance_SPMA_merged.csv")
fwrite(merged, out)
cat("saved:", out, "\n")
