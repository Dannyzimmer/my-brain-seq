# Pipeline dependencies

The canonical pipeline runs on the host and uses Singularity/Apptainer for the
analysis tools. The container images are pulled as SIF files from the URIs
declared in `resources/vendors/containers/containers.json` (Docker Hub and
Quay.io).

## Runtime

- Python 3 (entrypoint, `compipar_validator`, `compipar_bridge.py`).
- Singularity or Apptainer (SIF execution and SIFManager).
- Compi 1.5.2, vendored in `resources/compi-1.5.2/`.
- `curl` and `gunzip` (database preparation).

## Container images

- `pegi3s/r_deseq2`.
- `pegi3s/r_edger`.
- `pegi3s/r_enhanced-volcano`.
- `quay.io/biocontainers/cutadapt` (Cutadapt 1.16).
- `pegi3s/fastqc`.
- `pegi3s/bowtie1`.
- `pegi3s/feature-counts`.
- `pegi3s/samtools_bcftools` (used for alignment conversion and for BAM stats).
- `pegi3s/r_data-analysis`.
- `pegi3s/r_venn-diagram`.
- `pegi3s/r_network`.
- `pegi3s/multiqc`.

The exact image tags and SIF file names are defined in
`resources/vendors/containers/containers.json`. They are not pipeline
parameters; a custom `containersJSON` must contain literal tags and paths.

## Annotation databases

- DIANA TarBase annotations (tested with v8).
- Reactome annotations (tested with release 83).
- Reactome interactions file.

The `data-preparation` task downloads the same files that were previously baked
into the Docker image. They are stored under `databasesDir`.
