import duckdb
import os

def main():
    kag_dir = "superset_kag"
    parquet_dir = os.path.join(kag_dir, "parquet_files")

    if not os.path.exists(parquet_dir):
        print(f"Error: Parquet directory not found at {parquet_dir}")
        return

    print(f"Connecting to DuckDB and querying Parquet files in {parquet_dir}...")
    con = duckdb.connect()

    # List all parquet files
    files = [f for f in os.listdir(parquet_dir) if f.endswith(".parquet")]
    print(f"Found {len(files)} Parquet files.")

    # Query and print summary for each file
    for file in sorted(files):
        table_name = file.replace(".parquet", "")
        file_path = os.path.join(parquet_dir, file)

        print(f"\n--- Table: {table_name} ---")
        try:
            # Create a view for the parquet file
            con.execute(f"CREATE OR REPLACE VIEW {table_name} AS SELECT * FROM read_parquet('{file_path}')")

            # Get count
            count = con.execute(f"SELECT COUNT(*) FROM {table_name}").fetchone()[0]
            print(f"Row count: {count}")

            # Show schema
            print("Schema:")
            print(con.execute(f"DESCRIBE {table_name}").fetchdf())

            # Show sample data (first 3 rows)
            if count > 0:
                print("Sample data (first 3 rows):")
                print(con.execute(f"SELECT * FROM {table_name} LIMIT 3").fetchdf())

        except Exception as e:
            print(f"Error querying {file}: {e}")

if __name__ == "__main__":
    main()
