# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased] - 1.6.0

### Added
- Nothing, yet!

## [1.5.0] - 2016-04-25

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

### Changed
- The algorithm for determining the memory limit (`vmem`) for SGE execution hosts has been updated so as not to exceed total RAM + swap (clusterware-handlers#22)
- The AWS CLI tool has been updated to the latest version (v1.10.19) in order to make use of autoscaling features (clusterware-services#15)
- Depot `fetch` command has been removed and replaced by depot repository and `install` functionality (#42)
- Version comparisons have been enhanced to deal more intelligently with package versions that don't conform to sematic versioning (#98)
- When updating package a repository, better feedback is now provided regarding what revision has been selected, or if the local tree has become out of sync with the upstream repository somehow (#109)
- Gridware operations that could cause errors when being executed under non-superuser accounts have been made available to all users within the `gridware` group (#88)

### Fixed
- Correctly parse output from packager scripts when output is less than 10 lines long (#96)
- Gridware packages are now listed in semantic version order (#97)
- Correct a problem that could cause exported packages to have incorrect dependency data (#93)
- Prevent dependency data from being installed in the wrong place if a package is imported before any others hae been built (#94)
- Set permissions correctly to provide access to `gridware` group members when packages are imported (#105)
- Remove hard-coded path in the Clusterware configuration files for `logrotate` (#104)

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

[Unreleased]: https://github.com/alces-software/clusterware/compare/1.5.0...develop
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
