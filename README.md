# longhorn_conda
Conda deployment on Longhorn

## Usage

This is meant to both deploy and maintain the conda environment on a PowerAI system.
User documentation for interacting with the resulting deployment can be found [here](docs/userguide.md).

### Initial deployment

To create a conda installation in `$PWD/conda/4.8.3` run the following:

```shell
# Create base conda
make conda/4.8.3

# Cache packages using 4 cores
make -j 4 update

# Create environments
make environments

# Create LMOD moduels
make modules
```

This creates the following files and directories in your `$PWD`:

- `conda/4.8.3` - conda deployment
- `pkgs_backup.tar.gz` - backup of all cached packages
- `modulefiles` - LMOD modulefiles for environments and packages

### Updating an existing cache

New packages in the IBM WML that are not in `conda/4.8.3/pkgs` will be downloaded, unpackaged, and finally added to `pkgs_backup.tar.gz`

```shell
make -j 4 update
```
