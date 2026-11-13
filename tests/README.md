# Tests

`test_01` reproduces a full myBrainSeq analysis with the public test dataset.

PipeTester expands `${TEST_DIR}` to this directory and `${WORKSPACE_ROOT}` to the
parent directory of the test workspace. The large FASTQ files and the Bowtie
index are not stored in this repository; place the contents of the public test
dataset under:

```text
${WORKSPACE_ROOT}/MyBrain-Seq/test_01/data/
```

The dataset is available at:

- http://static.sing-group.org/software/myBrainSeq/downloads/test-data-1.0.zip

For a manual run, replace `${TEST_DIR}` and `${WORKSPACE_ROOT}` with absolute
paths and execute:

```bash
./myBrainSeq run tests/test_01/compi.parameters --add-params "--num-tasks 5"
```

The expected scientific behaviour is the same as the previous Compi pipeline:
same task order, same input files, same output names and same R analysis code
(except for the documented bug fixes in the migration history).
