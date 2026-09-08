# Glossary

## MGB

*Modelo de Grandes Bacias*, the large-scale hydrological model implemented in
this repository. The abbreviation is retained as the model's established name.

## HRU / URH

Hydrological response unit. Older Portuguese material uses *Unidade de Resposta
Hidrológica* (URH); source and English documentation use HRU.

## Catchment and minibasin

The computational unit in the drainage network. Legacy inputs and publications
may use *minibacia*. This repository uses *catchment* for the computational
unit and *subbasin* for a group of catchments.

## Upstream and downstream

The English terms corresponding to *montante* and *jusante*. A downstream
catchment receives routed flow; an upstream catchment contributes flow.

## Stage-area-volume table

A per-catchment lookup table relating water-surface elevation (*cota*), flooded
area, and stored volume. These tables support inertial flood routing.

## Retained runtime names

Historical filenames such as `infomgb.sim`, `mini.gtp`, `paruso.cal`,
`albiaf.fix`, `chuvabin.pbi`, `medias_cru.bin`, `cota_area.flp`, and
`nosolo.txt` remain unchanged because they are part of the runtime interface.
