# gha-trivy-docker-image-scan

GitHub Action to scan Docker Images for vulnerabilities using containerized [Trivy](https://trivy.dev/).

## Usage

```yaml
steps:
  - name: Scan Docker Image for Vulnerabilities
    uses: albr21/gha-trivy-docker-image-scan@1.0.0
    with:
      image-name: <image_name>
      image-tag: <image_tag>
      output-directory: <output_directory>
      output-filename: <output_filename>
      docker-registry: <docker_registry>
      docker-username: <docker_username>
      docker-password: <docker_password>
      docker-sock: <docker_sock>
      trivy-docker-image-name: <trivy_docker_image_name>
      trivy-docker-image-tag: <trivy_docker_image_tag>
      trivy-scan-severity: <trivy_scan_severity>
      trivy-skip-db-update: <trivy_skip_db_update>
      fail-on-vulnerability: <fail_on_vulnerability>
```

## Contributing

Check out the [CONTRIBUTING](CONTRIBUTING.md) file for guidelines on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
