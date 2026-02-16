# Apache Superset Knowledge Augmented Graph (KAG)

This repository contains the generated Knowledge Augmented Graph (KAG) for the [Apache Superset](https://github.com/apache/superset) codebase.

The graph was generated using the [GitLab Knowledge Graph (gkg)](https://gitlab.com/gitlab-org/rust/knowledge-graph) tool.

## Artifacts

The generated artifacts are located in the `superset_kag/` directory:

*   `database.kz`: The KuzuDB database file containing the graph structure.
*   `parquet_files/`: The raw Parquet files used to build the graph, containing nodes and relationships.

## Usage

### Viewing the Data

You can view the contents of the Parquet files using the provided Python script `view_kag.py`. This script utilizes `duckdb` to query and display the data.

**Prerequisites:**

```bash
pip install duckdb pandas numpy
```

**Running the viewer:**

```bash
python3 view_kag.py
```

This will list all available tables (nodes and relationships), show their row counts, schemas, and sample data.

### Regenerating the Graph

To regenerate the KAG from the latest Superset source code, run the provided shell script:

```bash
./generate_kag.sh
```

This script will:
1.  Check for `gkg` installation (and install if missing).
2.  Clone the latest `apache/superset` repository (depth 1).
3.  Run `gkg index` to generate the graph.
4.  Capture logs to `gkg_index.log`.
5.  Analyze the logs for errors.
6.  Move the generated artifacts to `superset_kag/`.
7.  Clean up the cloned repository.

## Analysis of Generation Process

During the generation process (logged in `gkg_index.log`), the following observations were made:

*   **Errors:** A small number of errors were encountered (typically < 10), primarily related to specific JavaScript syntax that the parser might not fully support (e.g., `TS1109`, unexpected tokens). These errors are localized and do not significantly impact the overall graph quality.
*   **Warnings:** Several warnings were logged, mostly concerning:
    *   **Duplicate Definitions:** Python files defining the same symbol multiple times (e.g., `__init__` methods, specific variables like `params` or `extra`). This is often due to dynamic code patterns or test fixtures.
    *   **Missing Target Definitions:** Relationships pointing to definitions that could not be resolved. This can happen with dynamic imports, external dependencies not present in the repo, or complex test setups.

Despite these warnings, the vast majority of the codebase (thousands of files and definitions) was successfully indexed and linked.
