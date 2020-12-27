# esa-export-v2-viewer

# Usage

1. Download exported zip files to `zip_files` on current directory
  ```
  zip_files
    ├── esa_foo-team_md_v2_2020-12-26_09-39-46_posts.zip
    ├── esa_foo-team_md_v2_2020-12-26_09-39-46_files_0.zip
    ├── esa_foo-team_md_v2_2020-12-26_09-39-46_files_1.zip
    ...
  ```
2. `docker run --rm -it -p 4567:4567 -v $PWD/zip_files:/app/zip_files fukayatsu/esa-export-v2-viewer:0.0.1`
3. Open http://localhost:4567 on browser


# Development

- `docker build -t esa-export-v2-viewer .`
- `docker tag esa-export-v2-viewer fukayatsu/esa-export-v2-viewer:0.0.1`
- `docker push fukayatsu/esa-export-v2-viewer:0.0.1`
