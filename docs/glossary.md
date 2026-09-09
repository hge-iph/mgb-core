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

## Canonical runtime names

The runtime interface uses descriptive English filenames and keys. Historical
names are listed only in the [breaking-change migration table](migration.md);
they are not accepted as aliases.
