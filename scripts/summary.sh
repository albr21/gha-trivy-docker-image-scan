set -e

while [ "$#" -gt 0 ]; do
  case "$1" in
    --results-path) RESULTS_PATH="$2"; shift 2 ;;
    *) echo "::error::Invalid option $1"; exit 1 ;;
  esac
done

# === Validate Options ===
if [ -z "$RESULTS_PATH" ]; then
  echo "::error::Usage: $0 --results-path <results_path>"
  exit 1
fi

# === Display the scan results as GitHub Summary ===
cat "$RESULTS_PATH" > "$GITHUB_STEP_SUMMARY"