# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added
- This CHANGELOG file! (#71)
- Support for Flight Access appliance
- Tool for manually initiating Clusterware configuration (#61)
- Increase coverage/utility of tab-completion under `bash` (#56)
- Add locking when nodes are being added/removed from SGE configuration (alces-software/clusterware-handlers#18)
- Deferred configuration of Gridware tree (alces-software/clusterware-handlers#16)
- Send additional messages to Alces Flight service to improve orchestration feedback (alces-software/clusterware-handlers#15)
- Inform/reconfigure slave nodes when a Gridware depot is fetched/enabled/disabled on a Gridware master node (alces-software/clusterware-handlers#14)

### Changed
- `alces about environment` command renamed to `alces about node` (#64)
- Improve SGE templates and howto guides (alces-software/clusterware-services#14)

### Fixed
- Support cluster SSH key generation under `tcsh` (#69)
- Initialize `MODULEPATH` correctly under `tcsh` (#67)
- Correct permissions on Gridware directories (#66)
- Correct regex that was preventing nodes from being added to `genders` file (alces-software/clusterware-handlers#18)
- Patch `s3cmd` so DNS style bucket names work reliably over SSL (alces-software/clusterware-storage#3)

## [1.3.0] - 2016-03-04

### Added
- Improved Clusterware content versioning (#60)
- Clean up when hosts leaving the cluster service ring (#58)
- Allow Serviceware to be pinned to specific versions (#57)
- Recursive get/put for `alces storage` utility (#55)
- Galaxy FTP support PASV mode when running on NAT-ed instance (alces-software/clusterware-services#9)
- OpenVPN Serviceware pack and Clusterware handlers (alces-software/clusterware-services#8)
- Automatically initialize Gridware tree when installing `cluster-gridware` handler (alces-software/clusterware-handlers#12)
- Additional session types, including lighter weight sessions (alces-software/clusterware-sessions#2)

### Changed
- Update Galaxy Serviceware pack for EL6 (alces-software/clusterware-services#13)
- Upgrade s3cmd to 1.6.1 release (alces-software/clusterware-services#12)

### Fixed
- Galaxy compute instance failures (alces-software/clusterware-services#11)
  - Install Java on Galaxy compute instance
  - Relocate Pulsar working directory into shared data area 
- Galaxy FTP access when configured for shared data (alces-software/clusterware-services#10)
- Galaxy compute hosts added on each boot (alces-software/clusterware-handlers#13)

## [1.2.1] - 2016-02-25

### Fixed
- Fix depot handling code which was failing due to missing inclusion of logging library.

## [1.2.0] - 2016-02-23

- Various features

## [1.1.0] - 2016-02-09

- Various features

## [1.0.0] - 2016-01-15

- Initial release

[Unreleased]: https://github.com/alces-software/clusterware/compare/1.3.0...develop
[1.3.0]: https://github.com/alces-software/clusterware/compare/1.2.0...1.3.0
[1.2.1]: https://github.com/alces-software/clusterware/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/alces-software/clusterware/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/alces-software/clusterware/compare/1.0.0...1.1.0
