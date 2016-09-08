# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - 1.6.0

### Added
- The Gridware package repositories are now automatically updated after a period of time (#121)
- Added HTTP serviceware allowing HTTP-based services to plug in to a central web server (#74)
- Gridware export/import can now patch binary files to handle hard-coded depot paths (#110)
- Added `alces configure hyperthreading` action for modifying hyperthreading behaviour (#164)
- Flight customization profiles can now be retrieved without S3 credentials (clusterware-handlers#34)
- Storage backends and system-wide configurations enabled on the master node are now propogated to all slave nodes (clusterware-handlers#21)
- New `alces sync` tool for synchronizing directories (for e.g. your home directory) to an S3 bucket, with file exclusion and encryption for sensitive files (#92)
- Added Slurm scheduler support (clusterware-handlers#27, clusterware-services#17)
- Added OpenLava scheduler support (clusterware-handlers#28, clusterware-services#20)
- Added TORQUE scheduler support (clusterware-handlers#26, clusterware-services#18)
- Added `--binary-only` option for `gridware install` and `gridware depot install` actions (clusterware#161)
- Gridware depot repositories are now automatically updated after a period of time (#176)
- A new `services/clusterware` modulefile is provided to facilitate access to core Clusterware utilities (clusterware-services#22)
- Introduce `alces customizer` action to allow customizaton profiles to be manually triggered (#143)
- Administrative users are now provided with access to the cluster access key even if they accidentally remove it (#118)
- Gridware package parameters can now be provided with defaults which can be selected via configuration or command-line parameter (#123)
- How-to guides and script templates can now be located in additional locations specified by the CW_DOCPATH environment variable (#127)
- Interactive sessions can now be located in additional locations specified by the CW_SESSIONPATH environment variable (#127)
- Allow configurator to be delayed until a flag file is written to allow more fine-grained control over Clusterware configuration files by cloud-init
- Added PBS Pro scheduler support (clusterware-handlers#39, clusterware-services#26)
- Added support for Ubuntu 16.04 LTS (Xenial Xerus) (clusterware#115)
- Added LXDE session (Ubuntu only) (clusterware-sessions#5)
- Added KDE session (clusterware-sessions#6)
- Clusterware VPN configurations are now provided as handy archives for download (clusterware-handlers#19)
- Added an attractive default web page for HTTP serviceware via new `cluster-www` handler (clusterware-services#27)
- Added a VPN section for HTTP serviceware if `cluster-www` handler is enabled (clusterware-handlers#40)
- The master node can now behave as a NAT gateway for slave nodes (clusterware-handlers#20)
- Scheduler behaviour can be configured using `alces configure scheduler`
- SSL certificates are allocated if `host_naming` strategy for `cluster` is set to `allocate` in `config.yml` (clusterware#184)
- Gridware source packages may be retrieved from Amazon S3 using the `aws` tool (clusterware#198 -- thanks @lurcio)

### Changed
- Environment modules warnings are now suppressed (#169)
- If we don't have permission to set CloudWatch metrics, disable metric scans (#174)
- The algorithm for determining the memory limit (`vmem`) for SGE execution hosts has been simplified to round down to nearest GiB of RAM (clusterware-handlers#31)
- Binary gridware packages and upstream source fallbacks are now retrieved from region-specific buckets (#139)
- Autoscaling has been refactored into a separate handler (clusterware-handlers#36)
- Reported metrics for autoscaling have been updated to facilitate better scaling rules (#111)
- `pdsh` is no longer placed on the `PATH` by default - access is now provided via the `services/pdsh` module (clusterware-services#22)
- EC2-style metadata service address is now blocked for non-superuser accounts
- Remote binary packages are checked to see if they are different from previously downloaded versions and, if so, are redownloaded (#134)
- Apply user-selectible theme for dark/light terminals to all tools (#140)
- Improve feedback from the `alces configure node` tool (#78)
- Updated `alces about` tool to be more flexible
- Updated `s3cmd` to latest development version (1.6.1-ba5196f1f6)
- When using the S3 backend with `alces storage` output now appears during uploads so progress can be monitored (#187)

### Fixed
- `/sys/hypervisor/uuid` now only read if it exists (#148)
- Fix a bug that was allowing Gridware depots to be added to global `modulespath` more than once
- Prevent sessions from failing to start if they are started in quick succession (#84)
- Stop the scheduler queues on the final instance in an autoscaling group from getting stuck in disabled state (clusterware-handlers#37)
- Autocompletion for `gridware depot` actions now suggest depots rather than packages (#159)
- Autocompletion for `service enable` action now suggests components (#177)
- Autocompletion for `handler enable` action no longer includes auxilliary files (#179)
- Added license and readme files to services, storage and sessions repositories (#114)
- Looking up entries in `mappingstab` now strips whitespace from the end of lines (#75)
- Prevent `No such file or directory` errors when using `member_each` function before any members are present (#151)
- Prevent `unable to write 'random state'` error when configuring VPN certificates (#150)
- Cluster name in prompt now matches the branding colour (#188)

## [1.5.3] - 2016-06-16

### Added
- Added `--geometry` parameter to `alces session start` command (#85)
- Added `--latest` parameter to `alces gridware install` command (#101)
- S3cmd is now added to the PATH by default when the serviceware is installed (clusterware-services#21)
- Git may be added to the PATH via a services modulefile if desired (clusterware#180)
- Interactive desktop session sizes may be specified when a session is launched (#85)
- The latest version of a Gridware package can automatically be selected for installation via a command-line argument (#101)

### Changed
- The `cluster-customizer` handler has been enhanced to allow machine type and feature specific profiles to be installed from S3 (clusterware-handlers#33)
- Distro dependency installation is retried if it times out (#178)

### Fixed
- Non-directory files in repository-driven content such as handlers, serviceware etc. are no longer incorrectly displayed (#173)
- Binary installation of packages with parameters no longer fail if requirements cannot be met (#171)
- Packages that require two or more variants of another package now resolve their dependencies correctly (#172)

## [1.5.2] - 2016-05-24

### Added
- Create cluster identification parameters from `identity` parameter when present in `config.yml` (#160)
- Provide new `alces about identity` action to facilitate access to cluster identification parameters (#163)
- Allow binary installation or compilation behaviour to be configured for Gridware package installation (#167)
- Defaults for `config.yml` parameters can be configured within the Clusterware tree (#165)

### Changed
- Interactive GNOME sessions have a new background (clusterware-sessions#7)

### Fixed
- Correct semantic version comparisons when resolving uninstalled package dependencies
- Allow installation of a depot from a depot repository other than the first configured repository (#166)
- Update file permissions on files within the installation directory after performing a Gridware package installation (#106)
- Correct dependency resolution when exporting Gridware packages that have "default" variants

## [1.5.1] - 2016-05-18

### Added
- Clusterware now displays an appropriate cosmetic version number at login (#119)
- Provide a framework to allow anonymous usage data to be gathered (#142)

### Fixed
- Updated Trinity session installation to reflect updated version available upstream (clusterware-sessions#8)
- Corrected a problem that was preventing environment modules from functioning correctly under tcsh
- Prevented a spurious error in the logs when `config.yml` does not contain an `instance` section (#141)
- Display an error rather than raising an exception when `gridware info` is requested for a non-existent package (#155)
- Corrected URLs in core howto guides

## [1.5.0] - 2016-05-15

### Added
- Enhanced tab-completion under `bash` to allow local files to be suggested where appropriate (#82)
- Added [`jo`](https://github.com/jpmens/jo) utility (#72)
- Distribution package repositories (e.g. EPEL) are now handled via a configurable interface (#70)
- Clusters now support auto-scaling by reporting job scheduler metrics and scaling-in idle nodes (clusterware-handlers#24)
- Gridware package requirements can now be automatically installed (#47)
- Updated heuristics for determining bad paths on package export, specifically only reject absolute library paths in ELF binaries (#91)
- Allow files matching specified patterns to be ignored when exporting packages (#95)
- Introduced depot repositories (#87)
- Significantly enhanced depot feature set (export, compile from source) (#42)
- Importing packages automatically imports or compiles package requirements (#100)
- Provide option to import existing binaries at install time (#100)
- The AWS CLI utility now has a serviceware modulefile and is loaded for users by default (clusterware-services#16)
- The Gridware repository has been split into "main" and "volatile" repositories; the "volatile" repository (which is disabled by default) contains all existing Gridware and the "main" repository contains Gridware that has undergone verification for use on Clusterware systems (#89)
- Enhanced the login banner to incorporate an Alces Flight logo in the medium of ASCII art (#102)
- Added `alces configure autoscaling` action (#128)
- If autoscaling is active, show a message at login (#129)
- Depot and package repositories are updated at boot (#132)
- Distro dependency installation for Gridware packages is now available in `/var/log/gridware/depends.log` (#133)
- Allow users to configure how noisy their login banners are (#108)
- User-selectible theme for dark/light terminals (#103)
- Show shorter banner/login messages for non-master instances (#137)
- Created `cluster-customizer` handler to allow additional scripts to be executed during node lifecycle (clusterware-handlers#25, #113)

### Changed
- The algorithm for determining the memory limit (`vmem`) for SGE execution hosts has been updated so as not to exceed total RAM + swap (clusterware-handlers#22)
- The AWS CLI tool has been updated to the latest version (v1.10.19) in order to make use of autoscaling features (clusterware-services#15)
- Depot `fetch` command has been removed and replaced by depot repository and `install` functionality (#42)
- Version comparisons have been enhanced to deal more intelligently with package versions that don't conform to sematic versioning (#98)
- When updating package a repository, better feedback is now provided regarding what revision has been selected, or if the local tree has become out of sync with the upstream repository somehow (#109)
- Gridware operations that could cause errors when being executed under non-superuser accounts have been made available to all users within the `gridware` group (#88)
- `alces configure` is now `alces configure node` (#83)
- The default memory limit for SGE jobs has been increased from 1GiB to 1.5GiB (clusterware-services#23)

### Fixed
- Correctly parse output from packager scripts when output is less than 10 lines long (#96)
- Gridware packages are now listed in semantic version order (#97)
- Correct a problem that could cause exported packages to have incorrect dependency data (#93)
- Prevent dependency data from being installed in the wrong place if a package is imported before any others hae been built (#94)
- Set permissions correctly to provide access to `gridware` group members when packages are imported (#105)
- Remove hard-coded path in the Clusterware configuration files for `logrotate` (#104)
- Allow Gridware distro dependencies to be installed while an `apps/python` module is loaded (#131)
- Tolerate broken links when updating file modes during import (#135)

#### Issues/PRs

[Core 1.5.0], [Handlers 1.5.0], [Services 1.5.0], [Storage 1.5.0], [Sessions 1.5.0]

## [1.4.1] - 2016-03-16

### Added
- If the configurator is no longer running after manual configuration, restart it. (#80)

### Fixed
- Correct additions to `/etc/hosts` if the IP address to add is a partial match with an existing IP address. (#81)
- Use the cluster name specified for manual configuration. (#77)

## [1.4.0] - 2016-03-15

### Added
- Handler for firewall configuration on `member-leave`, `member-join` events (clusterware-handlers#17)
- This CHANGELOG file! (#71)
- Support for Flight Access appliance
- Tool for manually initiating Clusterware configuration (#61)
- Increase coverage/utility of tab-completion under `bash` (#56)
- Add locking when nodes are being added/removed from SGE configuration (clusterware-handlers#18)
- Deferred configuration of Gridware tree (clusterware-handlers#16)
- Send additional messages to Alces Flight service to improve orchestration feedback (clusterware-handlers#15)
- Inform/reconfigure slave nodes when a Gridware depot is fetched/enabled/disabled on a Gridware master node (clusterware-handlers#14)

### Changed
- `alces about environment` command renamed to `alces about node` (#64)
- Improve SGE templates and howto guides (clusterware-services#14)

### Fixed
- Support cluster SSH key generation under `tcsh` (#69)
- Initialize `MODULEPATH` correctly under `tcsh` (#67)
- Correct permissions on Gridware directories (#66)
- Correct regex that was preventing nodes from being added to `genders` file (clusterware-handlers#18)
- Patch `s3cmd` so DNS style bucket names work reliably over SSL (clusterware-storage#3)

#### Issues/PRs

[Core 1.4.0], [Handlers 1.4.0], [Services 1.4.0], [Storage 1.4.0], [Sessions 1.4.0]

## [1.3.0] - 2016-03-04

### Added
- Improved Clusterware content versioning (#60)
- Clean up when hosts leaving the cluster service ring (#58)
- Allow Serviceware to be pinned to specific versions (#57)
- Recursive get/put for `alces storage` utility (#55)
- Galaxy FTP support PASV mode when running on NAT-ed instance (clusterware-services#9)
- OpenVPN Serviceware pack and Clusterware handlers (clusterware-services#8)
- Automatically initialize Gridware tree when installing `cluster-gridware` handler (clusterware-handlers#12)
- Additional session types, including lighter weight sessions (clusterware-sessions#2)

### Changed
- Update Galaxy Serviceware pack for EL6 (clusterware-services#13)
- Upgrade s3cmd to 1.6.1 release (clusterware-services#12)

### Fixed
- Galaxy compute instance failures (clusterware-services#11)
  - Install Java on Galaxy compute instance
  - Relocate Pulsar working directory into shared data area 
- Galaxy FTP access when configured for shared data (clusterware-services#10)
- Galaxy compute hosts added on each boot (clusterware-handlers#13)

#### Issues/PRs

[Core 1.3.0], [Handlers 1.3.0], [Services 1.3.0], [Storage 1.3.0], [Sessions 1.3.0]

## [1.2.1] - 2016-02-25

### Fixed
- Fix depot handling code which was failing due to missing inclusion of logging library.

## [1.2.0] - 2016-02-23

- Various features

## [1.1.0] - 2016-02-09

- Various features

## [1.0.0] - 2016-01-15

- Initial release

[Unreleased]: https://github.com/alces-software/clusterware/compare/1.5.3...develop
[1.5.3]: https://github.com/alces-software/clusterware/compare/1.5.2...1.5.3
[1.5.2]: https://github.com/alces-software/clusterware/compare/1.5.1...1.5.2
[1.5.1]: https://github.com/alces-software/clusterware/compare/1.5.0...1.5.1
[1.5.0]: https://github.com/alces-software/clusterware/compare/1.4.1...1.5.0
[Core 1.5.0]: https://github.com/alces-software/clusterware/issues?q=milestone%3A1.5.0
[Handlers 1.5.0]: https://github.com/alces-software/clusterware-handlers/issues?q=milestone%3A1.5.0
[Services 1.5.0]: https://github.com/alces-software/clusterware-services/issues?q=milestone%3A1.5.0
[Storage 1.5.0]: https://github.com/alces-software/clusterware-storage/issues?q=milestone%3A1.5.0
[Sessions 1.5.0]: https://github.com/alces-software/clusterware-sessions/issues?q=milestone%3A1.5.0
[1.4.1]: https://github.com/alces-software/clusterware/compare/1.4.0...1.4.1
[1.4.0]: https://github.com/alces-software/clusterware/compare/1.3.0...1.4.0
[Core 1.4.0]: https://github.com/alces-software/clusterware/issues?q=milestone%3A1.4.0
[Handlers 1.4.0]: https://github.com/alces-software/clusterware-handlers/issues?q=milestone%3A1.4.0
[Services 1.4.0]: https://github.com/alces-software/clusterware-services/issues?q=milestone%3A1.4.0
[Storage 1.4.0]: https://github.com/alces-software/clusterware-storage/issues?q=milestone%3A1.4.0
[Sessions 1.4.0]: https://github.com/alces-software/clusterware-sessions/issues?q=milestone%3A1.4.0
[1.3.0]: https://github.com/alces-software/clusterware/compare/1.2.0...1.3.0
[Core 1.3.0]: https://github.com/alces-software/clusterware/issues?q=milestone%3A1.3.0
[Handlers 1.3.0]: https://github.com/alces-software/clusterware-handlers/issues?q=milestone%3A1.3.0
[Services 1.3.0]: https://github.com/alces-software/clusterware-services/issues?q=milestone%3A1.3.0
[Storage 1.3.0]: https://github.com/alces-software/clusterware-storage/issues?q=milestone%3A1.3.0
[Sessions 1.3.0]: https://github.com/alces-software/clusterware-sessions/issues?q=milestone%3A1.3.0
[1.2.1]: https://github.com/alces-software/clusterware/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/alces-software/clusterware/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/alces-software/clusterware/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/alces-software/clusterware/compare/0.0.0...1.0.0
