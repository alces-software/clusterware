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

2. Set the `alces_OS` environment variable to match the distribution on which you are installing. Currently supported options are `el6` and `el7`:

     ```bash
     export alces_OS=el7
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

Set the `alces_FETCH_HANDLING` variable to indicate that you want to build from upstream source code rather than installing prebuilt binaries for your distribution.  Choose `source` to download and build components from upstream sources, or `dist` to use prebuilt binaries downloaded from Amazon S3.
   
```bash
export alces_FETCH_HANDLING=source
curl -sL http://git.io/clusterware-installer | /bin/bash
```

### Build from existing directory

Set the `alces_SOURCE_DIR` variable to point to an existing clone of the repository.  If a clone isn't available in the path you specify the path will be used to house the downloaded code rather than the default `/tmp/clusterware` temporary directory.

```bash
cd /usr/src
git clone https://github.com/alces-software/clusterware
export alces_SOURCE_DIR=/usr/src/clusterware
/usr/src/clusterware/scripts/bootstrap
```

### Build from an alternative branch

Set the `alces_SOURCE_BRANCH` variable with the name of the branch you wish to build.  Defaults to `master`. e.g.:

```bash
export alces_SOURCE_BRANCH=0.1.0
curl -sL http://git.io/clusterware-installer | /bin/bash
```

### Download source from an alternative URL

Set the `alces_SOURCE_URL` variable with the URL to a tarball of the Clusterware source code in `tar.gz` format.  Defaults to `https://github.com/alces-software/clusterware/archive/<branch>`. e.g.:

```bash
export alces_SOURCE_URL=http://symphony-app.mgt.symphony.local/clusterware/clusterware.tar.gz
curl -sL http://symphony-app.mgt.symphony.local/clusterware/bootstrap | /bin/bash
```

### Download binary dependencies from an alternative lcoation

Set the `alces_DIST_URL` variable with a base URL for suitable tarballs.  Defaults to `https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/clusterware/dist`. e.g.:

```bash
export alces_DIST_URL=http://symphony-app.mgt.symphony.local/clusterware/dist
export alces_SOURCE_URL=http://symphony-app.mgt.symphony.local/clusterware/clusterware.tar.gz
curl -sL http://symphony-app.mgt.symphony.local/clusterware/bootstrap | /bin/bash
```

### Download public repository dependencies from an alternative lcoation

Set the `alces_REPO_URL` variable with a base URL for suitable tarballs.  Defaults to unset.  e.g.:

```bash
export alces_REPO_URL=http://symphony-app.mgt.symphony.local/clusterware
export alces_DIST_URL=http://symphony-app.mgt.symphony.local/clusterware/dist
export alces_SOURCE_URL=http://symphony-app.mgt.symphony.local/clusterware/clusterware.tar.gz
curl -sL http://symphony-app.mgt.symphony.local/clusterware/bootstrap | /bin/bash
```

## Not yet fully supported

### Install Alces Clusterware in an alternative location

Set the `alces_TARGET_DIR` variable with the filesystem location for installation of Alces Clusterware.  Defaults to `/opt/clusterware`. e.g.:

```bash
export alces_TARGET_DIR=/opt/sw/cluster/clusterware
curl -sL http://git.io/clusterware-installer | /bin/bash
```

### Install Gridware in an alternative location

Set the `alces_GRIDWARE_TARGET_DIR` variable with the filesystem location for installation of the Gridware component.  Defaults to `/opt/gridware`. e.g.:

```bash
export alces_GRIDWARE_TARGET_DIR=/opt/sw/packages
curl -sL http://git.io/clusterware-installer | /bin/bash
```

Note that this only affects the Gridware package and configuration tree and does not modify where cache and log files are written (which remain at `/var/cache/gridware` and `/var/log/gridware` respectively).
