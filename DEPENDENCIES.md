# Pipeline dependencies

The canonical pipeline runs on the host and uses Singularity/Apptainer for the
analysis tools. The container images are pulled as SIF files from Docker Hub
using `docker://` URIs.

## Runtime

- Python 3 (entrypoint, `compipar_validator`, `compipar_bridge.py`).
- Singularity or Apptainer (SIF execution and SIFManager).
- Compi 1.5.2, vendored in `resources/compi-1.5.2/`.
- `curl` and `gunzip` (database preparation).

## Container images

- `pegi3s/r_deseq2` (default `1.32.0_v2`).
- `pegi3s/r_edger` (default `3.36.0`).
- `pegi3s/r_enhanced-volcano` (default `1.12.0`).
- `pegi3s/cutadapt` (default `1.16`).
- `pegi3s/fastqc` (default `0.11.9`).
- `pegi3s/bowtie1` (default `1.2.3`).
- `pegi3s/feature-counts` (default `2.0.0`).
- `pegi3s/samtools_bcftools` (defaults `1.9` and `1.10`).
- `pegi3s/r_data-analysis` (default `4.1.1_v3`).
- `pegi3s/r_venn-diagram` (default `1.7.0`).
- `pegi3s/r_network` (default `4.1.1_v2_v3`).
- `pegi3s/multiqc` (default `1.14.0`).

The image versions are public parameters (`rDeseq2Version`, `rEdgerVersion`,
`rEnhancedVolcanoVersion`, `cutadaptVersion`, `fastqcVersion`, `bowtieVersion`,
`featureCountsVersion`, `samtoolsVersion`, `samtoolsBamstatsVersion`,
`rdatanalysisVersion`, `rVennVersion`, `rNetworkVersion`, `multiqcVersion`).

## Annotation databases

- DIANA TarBase annotations (tested with v8).
- Reactome annotations (tested with release 83).
- Reactome interactions file.

The `data-preparation` task downloads the same files that were previously baked
into the Docker image. They are stored under `databasesDir`.
