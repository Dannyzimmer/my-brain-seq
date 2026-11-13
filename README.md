<table border="0">
  <tr>
    <td><img src="https://raw.githubusercontent.com/sing-group/my-brain-seq/master/resources/docs/mybrain-seq_logo.png"
         alt="myBrain-Seq logo"
         width="240px"
         style="vertical-align: middle; margin-left: 0;"/></td>
    <td style="vertical-align:middle;">
      <blockquote>
        <p><strong>myBrain-Seq</strong> is a Compi pipeline for miRNA-Seq analysis of neuropsychiatric data.</p>
      </blockquote>
    </td>
  </tr>
</table>

## Repository

- [GitHub](https://github.com/sing-group/my-brain-seq)

## What does myBrain-Seq do?

myBrain-Seq performs a complete analysis of miRNA-Seq data, with particular
interest in neuropsychiatric data. It identifies differentially expressed
microRNAs (DE miRNAs) between two conditions using DESeq2 and EdgeR, integrates
both results, and adds a functional analysis module that helps interpret the
list of DE miRNAs.

The pipeline is organised in four stages:

1. **Preprocessing:** FastQC, Cutadapt (optional), Bowtie, samtools, and
   featureCounts.
2. **Differential expression:** DESeq2, EdgeR, integration of both results,
   Venn diagram, and volcano plots.
3. **Functional analysis:** hierarchical clustering, TarBase/Reactome
   enrichment, and a miRNA-target network expanded with Reactome interactions.
4. **Summarisation:** a single MultiQC report.

When more than two conditions are involved, myBrain-Seq runs all the pairwise
contrasts declared by the user.

<p align="center">
  <img src="https://raw.githubusercontent.com/sing-group/my-brain-seq/master/resources/docs/pipeline_workflow.png" alt="myBrain-Seq workflow" title="myBrain-Seq workflow" width="80%"/>
</p>

## Repository layout

```text
my-brain-seq/
├── myBrainSeq                         # Entrypoint: run, test, templates cparams
├── params-examples/compi.parameters
├── tests/                             # PipeTester test definitions
└── resources/
    ├── compi-1.5.2/                   # Vendored Compi
    ├── data/
    │   ├── messages/                  # msg_main.json, msg_tests.json
    │   └── metadata/                  # parameters.metadata.json, outputs.metadata.json
    ├── env/
    │   ├── config/environment.json
    │   ├── shared/                    # environment.sh, printer.sh, tests.sh
    │   └── tools/                     # EnvHandler, Logger, SIFManager
    ├── pipelines/main.xml             # Task graph
    ├── runners/main.sh                # Compi runner
    ├── scripts/                       # Pipeline tasks and R analysis scripts
    └── vendors/                       # click, compipar_validator, containers.json
```

## Requirements

- Linux.
- Python 3.
- Singularity/Apptainer available in `PATH`.
- Internet access on the first run to pull the container images declared in
  `resources/vendors/containers/containers.json` and download the
  TarBase/Reactome databases.
- Compi is vendored in `resources/compi-1.5.2/`; no system installation is
  required.

The container images are pulled as SIF files from the URIs declared in
`resources/vendors/containers/containers.json` (Docker Hub and Quay.io). The
default image directory is
`${workingDir}/containers/`. The databases are downloaded into
`resources/data/databases/` by the `data-preparation` task. Both locations can
be changed with `containersDir`/`containersJSON` and `databasesDir`.

## Quick start

### 1. Create the working directory

```bash
WORKING_DIR=/path/to/mybrainseq-working-dir
mkdir -p "${WORKING_DIR}/input"
./myBrainSeq templates cparams "${WORKING_DIR}/input"
```

This creates `input/compi.parameters`. Edit it with the paths of your study.

### 2. Fill the input files

The working directory must contain:

```text
/path/to/mybrainseq-working-dir/
├── input/
│   ├── compi.parameters
│   ├── conditions_file.txt
│   └── contrast_file.txt
├── output/
└── logs/
```

`conditions_file.txt` is a TSV file with the sample names, conditions and
labels:

```text
name	condition	label
C019	control	control_1
C020	control	control_2
P012D	PTSD	PTSD_1
P013A	PTSD	PTSD_2
```

Additional columns are treated as covariates and added to the statistical
model:

```text
name	condition	label	sex	alcohol
C019	control	control_1	M	0
C020	control	control_2	M	1
```

`contrast_file.txt` declares the pairwise comparisons:

```text
name
"PTSD-Control" = "PTSD-control"
```

The left side is the label used to name the result directories. The right side
contains the values of the `condition` column, with the reference condition in
second position.

### 3. Validate and run

```bash
./myBrainSeq test "${WORKING_DIR}/input/compi.parameters"
./myBrainSeq run "${WORKING_DIR}/input/compi.parameters"
```

`test` runs `parameter-validation` and `checks` with `runChecks`. `run` performs
the full analysis. Both commands accept `--add-params`:

```bash
./myBrainSeq run "${WORKING_DIR}/input/compi.parameters" --add-params "--num-tasks 5"
```

## Parameters

### Required

| Parameter | Description |
|---|---|
| `workingDir` | Working directory of the project. |
| `gffFile` | miRNA annotation file (GFF/GTF). |
| `conditions` | TSV file with sample names, conditions and labels. |
| `contrast` | TSV file with the pairwise contrasts. |

### Optional

| Parameter | Default | Description |
|---|---|---|
| `fastqDir` | `input/fastq` | Directory containing the FASTQ files. |
| `outDir` | `output` | Output directory relative to `workingDir`. |
| `organism` | `Homo sapiens` | Organism for the functional analysis. |
| `adapter` | `NA` | Adapter sequence; `NA` skips Cutadapt. |
| `genome` | | Reference genome in FASTA. Provide `genome` or `bwtIndex`. |
| `bwtIndex` | | Root name of a pre-built Bowtie index. |
| `bwt_additional_args` | | Extra arguments passed to Bowtie. |
| `gffFeature` | `miRNA` | Annotation feature to use. |
| `gffAttribute` | `Name` | Annotation attribute to use. |
| `ft_additional_args` | | Extra arguments passed to featureCounts. |
| `qvalue` | `0.05` | FDR-corrected p-value threshold. |
| `log2FC` | `0.5` | Absolute log2 fold-change threshold. |
| `distance_method` | `euclidean` | Distance method for hierarchical clustering. |
| `vennFormat` | `png` | Venn diagram format (`png`, `svg`, `tiff`). |
| `selectDEAsoftware` | `both` | Differential expression software (`deseq`, `edger`, `both`). |
| `containersJSON` | `FALSE` | Custom SIFManager containers JSON. |
| `containersDir` | `FALSE` | Directory used to download the SIF images. |
| `databasesDir` | `/resources/data/databases/` | Directory containing TarBase/Reactome files. |
| `tarbaseDB` | `TarBase_v8_download.txt` | TarBase file name. |
| `reactomeDB` | `Ensembl2Reactome.txt` | Reactome Ensembl-to-pathway file. |
| `reactomeInteractionsDB` | `reactome.all_species.interactions.tab-delimited.txt` | Reactome interactions file. |

### Container versions

The image tags and SIF file names are defined once in
`resources/vendors/containers/containers.json`. They are not pipeline
parameters and should not be set in `compi.parameters`. The old `*Version=`
keys from previous releases are no longer accepted and must be removed from
existing `compi.parameters` files. A user-provided `containersJSON` must use
literal image tags and paths. If the pull source changes but the SIF filename is
kept, `container-preparation` compares the source recorded in the SIF labels
with the configured URI and re-downloads stale images.

### Output directories

`fqcOut`, `ctdOut`, `bwtOut`, `bamstOut`, `ftqOut`, `dsqOut`, `edgOut`,
`deaIntOut`, and `mqcOut` can be used to rename the output subdirectories.

### Flags

| Flag | Description |
|---|---|
| `runChecks` | Run parameter and input checks before the analysis. |
| `skipPullDockerImages` | Skip pulling the SIF images (they must already exist). |
| `removeDockerImages` | Remove the registered SIF files after the analysis. |
| `deseqNormalizationHclust` | Normalise counts globally with DESeq2 before clustering. |
| `samtools_keep_sam_files` | Keep the intermediate SAM files. |

## Output

The default output layout is:

```text
output/
├── 1_fastqc/
├── 2_cutadapt/
├── 3_bowtie/
├── 4_bam_stats/
├── 5_feature_counts/
│   └── all-counts.txt
├── 6_deseq2/<contrast>/
├── 6_edger/<contrast>/
├── 6_deseq2+edger/<contrast>/
└── 7_multiqc/
    └── multiqc_report.html
```

Each contrast directory contains the software result tables, volcano plots,
clustering figures, enrichment tables and networks when the corresponding
analysis produces results. The integrated directory also contains the Venn
input table and the integrated DE miRNA list.

## Partial executions

The runner forwards general Compi options before `--`:

```bash
./myBrainSeq run compi.parameters --add-params "--from feature-counts"
./myBrainSeq run compi.parameters --add-params "--until hclust"
./myBrainSeq run compi.parameters --add-params "--single-task fastqc-qc"
./myBrainSeq run compi.parameters --add-params "--num-tasks 2"
```

## Tests

`tests/test_01/test_config.json` defines a full test for PipeTester. The large
FASTQ files and the Bowtie index are not stored in this repository; see
[`tests/README.md`](tests/README.md) for the expected `${WORKSPACE_ROOT}` layout
and the public test dataset link.

## Troubleshooting

- **A SIF image is missing:** run without `skipPullDockerImages` or check
  `containersJSON`/`containersDir`.
- **The database files are missing:** run the `data-preparation` task or set
  `databasesDir` to a directory containing the three expected files.
- **A task is skipped:** check its `*.out.log` and `*.err.log` under
  `workingDir/logs/<timestamp>/tasks/`.
- **Genome index creation on Windows-formatted disks:** create the target index
  directory before running the analysis.

## Publications

- Pérez-Rodríguez, D., Agís-Balboa, R. C., & López-Fernández, H. (2023).
  [MyBrain-Seq: A Pipeline for MiRNA-Seq Data Analysis in Neuropsychiatric
  Disorders](https://doi.org/10.3390/biomedicines11041230). Biomedicines, 11(4),
  Article 4.
- D. Pérez-Rodríguez; M. Pérez-Rodríguez; R.C. Agís-Balboa; H. López-Fernández
  (2022) [Towards a flexible and portable workflow for analyzing miRNA-seq
  neuropsychiatric data: an initial replicability
  assessment](https://doi.org/10.1007/978-3-031-17024-9_4). PACBB 2022.

### Papers using myBrainSeq

- D. Pérez-Rodríguez; M. Arancha Penedo; T. Rivera-Baltanás; T. Peña-Centeno;
  S. Burkhardt; A. Fischer; J. M. Prieto-González; J. M. Olivares Díez;
  H. López-Fernández; R. C. Agís-Balboa (2023) [MiRNA differences related to
  treatment resistant schizophrenia](https://doi.org/10.3390/ijms24031891).
  International Journal of Molecular Sciences, 24(3), 1891.

## Team

MyBrain-Seq is a pipeline developed by the SING and NeuroEpigenetics Lab
groups.

- Daniel Pérez-Rodríguez, daniel.prz.rodriguez@gmail.com
- Hugo López-Fernández, hlfernandez@uvigo.es
- Roberto C. Agís-Balboa, roberto.carlos.agis.balboa@sergas.es

## License

MIT. See [`LICENSE`](LICENSE).
