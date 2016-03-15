# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

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
