#!/bin/bash
set -e

# Configuration
REPO_URL="https://github.com/apache/superset.git"
REPO_DIR="superset_repo"
KAG_DIR="superset_kag"
LOG_FILE="gkg_index.log"

echo "=== Apache Superset KAG Generation Script ==="

# 1. Install gkg if not present
if ! command -v gkg &> /dev/null; then
    echo "gkg not found. Installing..."
    export PATH="$HOME/.local/bin:$PATH"
    if ! command -v gkg &> /dev/null; then
        curl -fsSL https://gitlab.com/gitlab-org/rust/knowledge-graph/-/raw/main/install.sh | bash
        export PATH="$HOME/.local/bin:$PATH"
    fi
else
    echo "gkg is already installed."
fi

# 2. Clone the repository
if [ -d "$REPO_DIR" ]; then
    echo "Removing existing repository directory..."
    rm -rf "$REPO_DIR"
fi
echo "Cloning Apache Superset (depth 1)..."
git clone --depth 1 "$REPO_URL" "$REPO_DIR"

# 3. Run gkg index
echo "Indexing repository... (This may take a while)"
# We run gkg index and capture stdout/stderr to a log file
if cd "$REPO_DIR" && gkg index > "../$LOG_FILE" 2>&1; then
    echo "Indexing completed successfully."
else
    echo "Indexing failed. Check $LOG_FILE for details."
    # We don't exit here immediately because gkg might produce partial results or exit with non-zero on minor errors
    # But for a robust script, we should probably check if output exists.
fi
cd ..

# 4. Analyze logs for critical errors
echo "Analyzing logs..."
ERR_COUNT=$(grep -c "ERROR" "$LOG_FILE" || true)
WARN_COUNT=$(grep -c "WARN" "$LOG_FILE" || true)
echo "Found $ERR_COUNT errors and $WARN_COUNT warnings in $LOG_FILE."
if [ "$ERR_COUNT" -gt 0 ]; then
    echo "Sample errors:"
    grep "ERROR" "$LOG_FILE" | head -n 5
fi

# 5. Identify and Move Artifacts
# gkg output structure is usually ~/.gkg/gkg_workspace_folders/<hash>/<hash>
# We need to find the latest created directory in ~/.gkg/gkg_workspace_folders
LATEST_GKG_DIR=$(find ~/.gkg/gkg_workspace_folders -mindepth 2 -maxdepth 2 -type d -name "parquet_files" | xargs dirname | sort -k 1 -r | head -n 1)

if [ -z "$LATEST_GKG_DIR" ]; then
    echo "Error: Could not locate generated KAG artifacts in ~/.gkg"
    exit 1
fi

echo "Found artifacts at: $LATEST_GKG_DIR"

if [ -d "$KAG_DIR" ]; then
    echo "Cleaning up existing KAG directory..."
    rm -rf "$KAG_DIR"
fi
mkdir -p "$KAG_DIR"

echo "Moving artifacts to $KAG_DIR..."
cp -r "$LATEST_GKG_DIR"/* "$KAG_DIR/"

# 6. Verify Output
if [ -f "$KAG_DIR/database.kz" ] && [ -d "$KAG_DIR/parquet_files" ]; then
    SIZE=$(du -sh "$KAG_DIR" | awk '{print $1}')
    echo "Success! KAG generated in $KAG_DIR (Size: $SIZE)"
else
    echo "Error: KAG artifacts missing in $KAG_DIR"
    exit 1
fi

# 7. Clean up
echo "Cleaning up source repository..."
rm -rf "$REPO_DIR"

echo "Done."
