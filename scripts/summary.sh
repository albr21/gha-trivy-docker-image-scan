set -e

while [ "$#" -gt 0 ]; do
  case "$1" in
    --docker-image) DOCKER_IMAGE="$2"; shift 2 ;;
    --results-path) RESULTS_PATH="$2"; shift 2 ;;
    *) echo "::error::Invalid option $1"; exit 1 ;;
  esac
done

# === Validate Options ===
if [ -z "$RESULTS_PATH" ]; then
  echo "::error::Usage: $0 --docker-image-name <docker_image_name> --results-path <results_path>"
  exit 1
fi

# === Retrieve scan information from Trivy results ===
echo "📊 Getting Trivy scan results..."
CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$RESULTS_PATH")
HIGH=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$RESULTS_PATH")
MEDIUM=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$RESULTS_PATH")
LOW=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="LOW")] | length' "$RESULTS_PATH")
UNKNOWN=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="UNKNOWN")] | length' "$RESULTS_PATH")
TOTAL=$(jq '[.Results[].Vulnerabilities[]?] | length' "$RESULTS_PATH")

# === Display the scan results as GitHub Summary ===
{
  echo "## Security scan results: $DOCKER_IMAGE"
  echo ""
  echo "| Critical ⛔ | High 🔴 | Medium 🔶 | Low 🟡 | Unknown ⚠️ | Total 🔬 |"
  echo "|:---------:|:---------:|:---------:|:---------:|:---------:|:---------:|"
  echo "| $CRITICAL | $HIGH | $MEDIUM | $LOW | $UNKNOWN | $TOTAL |"
  echo ""
  echo "<details>"
  echo "<summary>Vulnerabilities details</summary>"
  echo ""
  echo ""
  echo "| CVE | Severity | Package | Installed | Fixed |"
  echo "|-----|----------|---------|-----------|-------|"

  jq -r '
    .Results[]?.Vulnerabilities[]? |
    [
      .VulnerabilityID,
      .Severity,
      .PkgName,
      .InstalledVersion,
      (.FixedVersion // "-")
    ] | @tsv
  ' "$RESULTS_PATH" | while IFS=$'\t' read -r cve sev pkg inst fixed
  do
    echo "| $cve | $sev | $pkg | $inst | $fixed |"
  done

  echo ""
  echo "</details>"
} >> "$GITHUB_STEP_SUMMARY"
