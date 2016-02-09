# Installing Alces Clusterware

## Supported platforms

Alces Clusterware currently supports the following platforms/distributions:

* Enterprise Linux 6 distributions: RHEL, CentOS, Scientific Linux (`el6`)
* Enterprise Linux 7 distributions: RHEL, CentOS, Scientific Linux (`el7`)

## Prerequisites

The install scripts handle the installation of all required packages from your distribution and will install on a minimal base.  For Enterprise Linux distributions installation of the `@core` and `@base` package groups is sufficient.

## Basic Installation

Clusterware is a system-level package and must be installed by the `root` user.

1. Become root.

   ```bash
   sudo -s
   ```

2. Set the `cw_DIST` environment variable to match the distribution on which you are installing. Currently supported options are `el6` and `el7`:

     ```bash
     export cw_DIST=el7
     ```

3. Invoke installation by piping output from `curl` to `bash`:

   ```bash
   curl -sL http://git.io/clusterware-installer | /bin/bash
   ```

   If you want to you can download the script first.  You might want to do this if you want to inspect what it's going to do, or if you're nervous about it being truncated during download:

   ```bash
   curl -sL http://git.io/clusterware-installer > /tmp/bootstrap.sh
   less /tmp/bootstrap.sh
   bash /tmp/bootstrap.sh
   ```

4. After installation, you can logout and login again in order to set up the appropriate shell configuration, or you can source the shell configuration manually:

   ```bash
   source /etc/profile.d/alces-clusterware.sh
   ```

## Advanced installation parameters

Additional environment variables may be set to influence the installation process.

### Build from upstream source

Set the `cw_BUILD_fetch_handling` variable to indicate that you want to build from upstream source code rather than installing prebuilt binaries for your distribution.  Choose `source` to download and build components from upstream sources, or `dist` to use prebuilt binaries downloaded from Amazon S3.
   
```bash
export cw_BUILD_fetch_handling=source
curl -sL http://git.io/clusterware-installer | /bin/bash
```

### Build from existing directory

Set the `cw_BUILD_source_dir` variable to point to an existing clone of the repository.  If a clone isn't available in the path you specify the path will be used to house the downloaded code rather than the default `/tmp/clusterware` temporary directory.

```bash
cd /usr/src
git clone https://github.com/alces-software/clusterware
export cw_BUILD_source_dir=/usr/src/clusterware
/usr/src/clusterware/scripts/bootstrap
```

### Build from an alternative branch

Set the `cw_BUILD_source_branch` variable with the name of the branch you wish to build.  Defaults to `master`. e.g.:

```bash
export cw_BUILD_source_branch=0.1.0
curl -sL http://git.io/clusterware-installer | /bin/bash
```

### Download source from an alternative URL

Set the `cw_BUILD_source_url` variable with the URL to a tarball of the Clusterware source code in `tar.gz` format.  Defaults to `https://github.com/alces-software/clusterware/archive/<branch>`. e.g.:

```bash
export cw_BUILD_source_url=http://symphony-app.mgt.symphony.local/clusterware/clusterware.tar.gz
curl -sL http://symphony-app.mgt.symphony.local/clusterware/bootstrap | /bin/bash
```

### Download binary dependencies from an alternative lcoation

Set the `cw_BUILD_dist_url` variable with a base URL for suitable tarballs.  Defaults to `https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/clusterware/dist`. e.g.:

```bash
export cw_BUILD_dist_url=http://symphony-app.mgt.symphony.local/clusterware/dist
export cw_BUILD_source_url=http://symphony-app.mgt.symphony.local/clusterware/clusterware.tar.gz
curl -sL http://symphony-app.mgt.symphony.local/clusterware/bootstrap | /bin/bash
```

### Download public repository dependencies from an alternative lcoation

Set the `cw_BUILD_repo_url` variable with a base URL for suitable tarballs.  Defaults to unset.  e.g.:

```bash
export cw_BUILD_repo_url=http://symphony-app.mgt.symphony.local/clusterware
export cw_BUILD_dist_url=http://symphony-app.mgt.symphony.local/clusterware/dist
export cw_BUILD_source_url=http://symphony-app.mgt.symphony.local/clusterware/clusterware.tar.gz
curl -sL http://symphony-app.mgt.symphony.local/clusterware/bootstrap | /bin/bash
```

## Not yet fully supported

### Install Alces Clusterware in an alternative location

Set the `cw_BUILD_target_dir` variable with the filesystem location for installation of Alces Clusterware.  Defaults to `/opt/clusterware`. e.g.:

```bash
export cw_BUILD_target_dir=/opt/sw/cluster/clusterware
curl -sL http://git.io/clusterware-installer | /bin/bash
```
