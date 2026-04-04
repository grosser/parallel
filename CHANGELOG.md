# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-04-03

### Changed

- Require Ruby >= 3.3
- Add Ruby 4 Ractor support

## [1.28.0] - 2026-04-02

### Fixed

- Dump undumpable exceptions without cause if that fixes the issue

## [1.27.0] - 2025-04-14

### Added

- Ruby 3.4 support

## [1.26.3] - 2024-08-16

### Fixed

- Ensure not to use old `concurrent-ruby`

## [1.26.2] - 2024-08-11

### Fixed

- Revert v1.26.1 revert; restore cgroups-aware processor count

## [1.26.1] - 2024-08-08

### Fixed

- Revert cgroups-aware processor count from v1.26.0

## [1.26.0] - 2024-08-08

### Changed

- Use cgroups-aware processor count by default

## [1.25.1] - 2024-06-08

### Fixed

- Improve speed for `Get-CimInstance` on Windows

## [1.25.0] - 2024-06-08

### Removed

- Remove dependency on `win32ole`

### Changed

- Require Ruby >= 2.7

## [1.24.0] - 2023-12-16

### Added

- Add `:finish_in_order` option

## [1.23.0] - 2023-04-18

### Added

- Add `filter_map`

### Changed

- Inline the methods of ProcessorCount module

## [1.22.1] - 2022-03-25

### Fixed

- Fix compilation on Windows

## [1.22.0] - 2022-03-21

### Added

- Ractor support
- Ruby 3.1 support

## [1.21.0] - 2021-09-13

### Fixed

- Avoid thousands of `lsof` warnings in chroot
- Fix processor count detection on macOS darwin20

## [1.20.2] - 2021-08-24

### Fixed

- Add support for darwin20 processor count detection

## [1.20.1] - 2020-11-22

### Changed

- Switch CI from Travis to GitHub Actions

## [1.20.0] - 2020-11-07

### Added

- Allow breaking with value

### Changed

- Bump Ruby requirements

## [1.19.2] - 2020-06-17

### Fixed

- Allow timeout usage inside of threads

## [1.19.1] - 2019-11-22

### Added

- Add project metadata to the gemspec

### Fixed

- Rescue core exceptions like rspec does

## [1.19.0] - 2019-11-13

### Fixed

- Make sure to also rescue non-standard errors

## [1.18.0] - 2019-10-06

### Added

- Allow overriding the number of processors with an env variable

## [1.17.0] - 2019-04-01

### Fixed

- Fix async exception timing

## [1.16.2] - 2019-03-29

### Fixed

- Prefer local variable over instance variable in worker replacement

## [1.16.1] - 2019-03-28

### Fixed

- Calculate lap correctly to replace worker in isolation mode

## [1.16.0] - 2019-03-26

### Fixed

- Child gracefully halts when parent already died
- Ensure threads are killed on completion

## [1.15.0] - 2019-03-24

### Fixed

- Avoid nil errors by initializing all workers during isolation runs

## [1.14.0] - 2019-02-25

### Fixed

- Avoid deprecation warnings
- Skip BigDecimal warnings explicitly

## [1.13.0] - 2019-01-17

### Added

- Enforce a single worker type

### Fixed

- Ensure that `.map` doesn't modify options passed in

## [1.12.1] - 2017-12-16

### Fixed

- Ensure the trapped signal is callable within the Interrupt signal handler

## [1.12.0] - 2017-07-25

### Added

- Ruby 2.4 support

### Fixed

- Reference the Tempfile so it's not GC'd/removed too early

## [1.11.2] - 2017-05-06

### Fixed

- Synchronize worker replacement to avoid race condition

## [1.11.1] - 2017-03-11

### Fixed

- Fix typo (bracktrace => backtrace), use `attr_reader`
- Remove bindings stack added by `better_errors` gem

## [1.11.0] - 2017-03-10

### Added

- Add `any?` and `all?` methods

### Fixed

- Handle kill and break exceptions in `work_direct`
- Make version not be required twice when using via git source

## [1.10.0] - 2016-11-24

### Added

- Add `Parallel.worker_number` via thread local
- Add timeout support

### Fixed

- Make undumpable exceptions traceable
- Do not call kill method if thread is nil

## [1.9.0] - 2016-06-03

### Added

- Expose `parallel_worker_number` via thread local so tasks can coordinate external dependencies

## [1.8.0] - 2016-03-27

### Added

- Add isolation mode

## [1.7.0] - 2016-03-25

### Added

- Support `true` in progress

## [1.6.2] - 2016-02-24

### Fixed

- Don't call `:finish` hook if there was an exception

## [1.6.1] - 2015-07-21

### Fixed

- `Parallel.map` writes its output safely

## [1.6.0] - 2015-05-26

### Changed

- Stop rescuing interrupt and remove unnecessary thread kill code

## [1.5.1] - 2015-05-25

### Fixed

- Make ensure logic not get called when JRuby exits

## [1.5.0] - 2015-05-25

### Changed

- Refactor into JobFactory
- Extract UserInterruptHandler

### Fixed

- Fix JRuby threading vs Ctrl+C

## [1.4.1] - 2015-03-01

### Added

- Add `progress_options` option for `ruby-progressbar` library

## [1.4.0] - 2015-02-16

### Fixed

- Stop workers in additional cases when exception is raised in processes
- Ensure `EOFError` in process is raised as EOF, not `DeadWorker`

## [1.3.4] - 2015-02-07

### Fixed

- Notify start and finish with zero workers

## [1.3.3.1] - 2015-09-07

### Fixed

- Fix missing thread require
- Simplify require

## [1.3.3] - 2014-10-08

### Fixed

- Initialize instance variable before access

## [1.3.2] - 2014-09-12

### Added

- Allow custom definition of interrupt signal
- Pass full options to `in_threads`

## [1.3.1] - 2014-09-04

### Fixed

- Fix Queue not being defined in REE / 1.9.3

## [1.3.0] - 2014-08-30

### Added

- Support lambdas in threads and processes

### Changed

- Refactored queue wrapping and mutex handling

## [1.2.4] - 2014-08-17

### Changed

- Do not store all values in an array for `each` + finish/progress; discard after instrumentation

## [1.2.3] - 2014-08-17

### Added

- Support progress and finish callbacks
- Pass results to finish callback on each

## [1.2.2] - 2014-08-12

### Fixed

- Do not silently fail when getting interrupted

## [1.2.1] - 2014-08-12

### Added

- Add progressbar support

## [1.2.0] - 2014-08-07

### Fixed

- Preserve and call original interrupt to not kill irb sessions

## [1.1.2] - 2014-07-18

### Fixed

- Do not kill yourself so stdout can get flushed properly

## [1.1.1] - 2014-07-17

### Added

- Introduce `Parallel::Kill` to stop all execution

## [1.1.0] - 2014-07-17

### Fixed

- Do not re-raise interrupts or SystemExit

## [1.0.0] - 2014-03-21

### Added

- Yield results to finish callback

### Changed

- Call finish with result for more flexibility

## [0.9.2] - 2014-01-13

### Added

- Allow use of Postgres

### Fixed

- Keep compatible with REE
- Fix GC detection

## [0.9.1] - 2013-11-25

### Added

- Add license to gem

## [0.9.0] - 2013-10-16

### Added

- More accurate processor core counts for Linux and Windows
- Only attempt multiprocessing if `Process.fork` is available
- JRuby threads as default for JRuby platform

## [0.8.4] - 2013-09-26

### Added

- FreeBSD sysctl support for processor count

## [0.8.3] - 2013-09-20

### Fixed

- Fix uninitialized instance variable `@to_be_killed`

## [0.8.2] - 2013-09-13

### Changed

- Avoid slowness when assigning/passing results that will be discarded

## [0.8.1] - 2013-09-10

### Fixed

- Fix copy-paste error in `physical_processor_count` for Win32

## [0.8.0] - 2013-08-30

### Fixed

- Under Linux, physical core count is number of physicals * cores/physical
- Add Ruby 1.8.7 support
- Handle case where cores not visible in `/proc/cpuinfo`

## [0.7.1] - 2013-06-30

### Added

- Processor count support for NetBSD

## [0.7.0] - 2013-06-14

### Fixed

- Fix finish order
- Kill threads on Ctrl+C

## [0.6.5] - 2013-05-14

### Fixed

- Correct number of CPUs in KVM

## [0.6.4] - 2013-03-30

### Added

- Handle return in parallel threads/processes using `Parallel::Break`

## [0.6.3] - 2013-03-19

### Added

- Add MIT-LICENSE.txt

## [0.6.2] - 2013-02-03

### Changed

- Experiment with signed certs

## [0.6.1] - 2012-12-15

### Fixed

- `DeadWorker` uses common ancestor `Exception` for EOF and EPIPE

## [0.6.0] - 2012-12-15

### Added

- Nice notification when workers die
- Nice error message when trying to write to a dead process

### Changed

- Extract worker class
- Refactor instrumentation

## [0.5.21] - 2012-12-01

### Changed

- Memoize processor counts as they don't change

## [0.5.20] - 2012-11-27

### Added

- Monitor progress with `:start` and `:finish` callbacks
- Progressbar support

## [0.5.19] - 2012-10-07

### Fixed

- Ignore dead children

## [0.5.18] - 2012-08-17

### Added

- Cygwin support for processor count

## [0.5.17] - 2012-06-03

### Fixed

- Additional distro support for processor count

## [0.5.16] - 2012-03-06

### Changed

- Bundlerify gemspec

## [0.5.15] - 2012-02-25

### Fixed

- Fix complex object de/serialisation

## [0.5.14] - 2012-02-07

### Fixed

- Raise undumpable exceptions properly
- Silence a warning

## [0.5.13] - 2012-02-02

### Added

- First try on physical CPU count

## [0.5.12] - 2012-01-21

### Added

- Processor count support for Solaris

## [0.5.11] - 2011-12-09

### Fixed

- Fix pipe-closing file descriptor issue

## [0.5.10] - 2011-12-06

### Changed

- Switch license to MIT
- Refactor worker creation

## [0.5.9] - 2011-09-11

### Fixed

- Default `processor_count` to 1 when unknown
- Remove self-reference so it can be easily vendored

## [0.5.8] - 2011-08-18

### Changed

- Simplify work in processes

## [0.5.7] - 2011-08-08

### Added

- Support 0 threads/processes for debugging and benchmarking

### Changed

- Simplified command for Linux CPU detection

## [0.5.6] - 2011-08-05

### Changed

- Count hyper-threads instead of cores

## [0.5.5] - 2011-06-03

### Added

- Windows support for number of processes

## [0.5.4] - 2011-06-02

### Fixed

- Support any version of Darwin
- Support JRuby on OS X

## [0.5.3] - 2011-03-20

### Added

- Support any Enumerable (anything that has `to_a`)

## [0.5.2] - 2011-02-15

### Fixed

- Guard against missing `hwprefs` on OS X 10.6+

## [0.5.1] - 2010-11-05

### Fixed

- Let other jobs finish clean when one raises
- Join all threads if one got an exception

## [0.5.0] - 2010-10-24

### Changed

- Split thread and process handling
- Preserve order of elements
- Remove encoding/decoding and duping overhead

## [0.4.6] - 2010-10-06

### Fixed

- Fix `hwprefs` `thread_count` to `cpu_count` on Leopard

## [0.4.5] - 2010-10-06

### Added

- Detect Hyperthreading on Darwin

## [0.4.4] - 2010-09-24

### Fixed

- Make tests pass on OS X with different UID array index
- Fix for Ruby 1.9 formatting and splat changes

## [0.4.3] - 2010-08-24

### Added

- FreeBSD support

## [0.4.2] - 2010-05-11

### Fixed

- Prevent Hold status in children

## [0.4.1] - 2010-04-18

### Added

- Add `each_with_index` and `map_with_index`

## [0.4.0] - 2010-01-17

### Changed

- Preserve results only if necessary

## [0.3.7] - 2009-12-19

### Fixed

- Using nil as argument for `in_processes` should use the default

## [0.3.6] - 2009-11-07

### Added

- Add `GC.copy_on_write_friendly=true`

## [0.3.5] - 2009-10-18

### Added

- Support for Ranges
- High fork rate support

## [0.3.4] - 2009-10-16

### Changed

- Internal improvements

## [0.3.3] - 2009-10-11

### Changed

- Internal refactoring

## [0.3.2] - 2009-10-11

### Added

- Add `Parallel.each`

## [0.3.1] - 2009-10-05

### Added

- Initial release on RubyGems

[2.0.0]: https://github.com/grosser/parallel/compare/v1.28.0...v2.0.0
[1.28.0]: https://github.com/grosser/parallel/compare/v1.27.0...v1.28.0
[1.27.0]: https://github.com/grosser/parallel/compare/v1.26.3...v1.27.0
[1.26.3]: https://github.com/grosser/parallel/compare/v1.26.2...v1.26.3
[1.26.2]: https://github.com/grosser/parallel/compare/v1.26.1...v1.26.2
[1.26.1]: https://github.com/grosser/parallel/compare/v1.26.0...v1.26.1
[1.26.0]: https://github.com/grosser/parallel/compare/v1.25.1...v1.26.0
[1.25.1]: https://github.com/grosser/parallel/compare/v1.25.0...v1.25.1
[1.25.0]: https://github.com/grosser/parallel/compare/v1.24.0...v1.25.0
[1.24.0]: https://github.com/grosser/parallel/compare/v1.23.0...v1.24.0
[1.23.0]: https://github.com/grosser/parallel/compare/v1.22.1...v1.23.0
[1.22.1]: https://github.com/grosser/parallel/compare/v1.22.0...v1.22.1
[1.22.0]: https://github.com/grosser/parallel/compare/v1.21.0...v1.22.0
[1.21.0]: https://github.com/grosser/parallel/compare/v1.20.2...v1.21.0
[1.20.2]: https://github.com/grosser/parallel/compare/v1.20.1...v1.20.2
[1.20.1]: https://github.com/grosser/parallel/compare/v1.20.0...v1.20.1
[1.20.0]: https://github.com/grosser/parallel/compare/v1.19.2...v1.20.0
[1.19.2]: https://github.com/grosser/parallel/compare/v1.19.1...v1.19.2
[1.19.1]: https://github.com/grosser/parallel/compare/v1.19.0...v1.19.1
[1.19.0]: https://github.com/grosser/parallel/compare/v1.18.0...v1.19.0
[1.18.0]: https://github.com/grosser/parallel/compare/v1.17.0...v1.18.0
[1.17.0]: https://github.com/grosser/parallel/compare/v1.16.2...v1.17.0
[1.16.2]: https://github.com/grosser/parallel/compare/v1.16.1...v1.16.2
[1.16.1]: https://github.com/grosser/parallel/compare/v1.16.0...v1.16.1
[1.16.0]: https://github.com/grosser/parallel/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/grosser/parallel/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/grosser/parallel/compare/v1.13.0...v1.14.0
[1.13.0]: https://github.com/grosser/parallel/compare/v1.12.1...v1.13.0
[1.12.1]: https://github.com/grosser/parallel/compare/v1.12.0...v1.12.1
[1.12.0]: https://github.com/grosser/parallel/compare/v1.11.2...v1.12.0
[1.11.2]: https://github.com/grosser/parallel/compare/v1.11.1...v1.11.2
[1.11.1]: https://github.com/grosser/parallel/compare/v1.11.0...v1.11.1
[1.11.0]: https://github.com/grosser/parallel/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/grosser/parallel/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/grosser/parallel/compare/v1.8.0...v1.9.0
[1.8.0]: https://github.com/grosser/parallel/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/grosser/parallel/compare/v1.6.2...v1.7.0
[1.6.2]: https://github.com/grosser/parallel/compare/v1.6.1...v1.6.2
[1.6.1]: https://github.com/grosser/parallel/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/grosser/parallel/compare/v1.5.1...v1.6.0
[1.5.1]: https://github.com/grosser/parallel/compare/v1.5.0...v1.5.1
[1.5.0]: https://github.com/grosser/parallel/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/grosser/parallel/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/grosser/parallel/compare/v1.3.4...v1.4.0
[1.3.4]: https://github.com/grosser/parallel/compare/v1.3.3.1...v1.3.4
[1.3.3.1]: https://github.com/grosser/parallel/compare/v1.3.3...v1.3.3.1
[1.3.3]: https://github.com/grosser/parallel/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/grosser/parallel/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/grosser/parallel/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/grosser/parallel/compare/v1.2.4...v1.3.0
[1.2.4]: https://github.com/grosser/parallel/compare/v1.2.3...v1.2.4
[1.2.3]: https://github.com/grosser/parallel/compare/v1.2.2...v1.2.3
[1.2.2]: https://github.com/grosser/parallel/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/grosser/parallel/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/grosser/parallel/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/grosser/parallel/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/grosser/parallel/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/grosser/parallel/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/grosser/parallel/compare/v0.9.2...v1.0.0
[0.9.2]: https://github.com/grosser/parallel/compare/v0.9.1...v0.9.2
[0.9.1]: https://github.com/grosser/parallel/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/grosser/parallel/compare/v0.8.4...v0.9.0
[0.8.4]: https://github.com/grosser/parallel/compare/v0.8.3...v0.8.4
[0.8.3]: https://github.com/grosser/parallel/compare/v0.8.2...v0.8.3
[0.8.2]: https://github.com/grosser/parallel/compare/v0.8.1...v0.8.2
[0.8.1]: https://github.com/grosser/parallel/compare/v0.8.0...v0.8.1
[0.8.0]: https://github.com/grosser/parallel/compare/v0.7.1...v0.8.0
[0.7.1]: https://github.com/grosser/parallel/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/grosser/parallel/compare/v0.6.5...v0.7.0
[0.6.5]: https://github.com/grosser/parallel/compare/v0.6.4...v0.6.5
[0.6.4]: https://github.com/grosser/parallel/compare/v0.6.3...v0.6.4
[0.6.3]: https://github.com/grosser/parallel/compare/v0.6.2...v0.6.3
[0.6.2]: https://github.com/grosser/parallel/compare/v0.6.1...v0.6.2
[0.6.1]: https://github.com/grosser/parallel/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/grosser/parallel/compare/v0.5.21...v0.6.0
[0.5.21]: https://github.com/grosser/parallel/compare/v0.5.20...v0.5.21
[0.5.20]: https://github.com/grosser/parallel/compare/v0.5.19...v0.5.20
[0.5.19]: https://github.com/grosser/parallel/compare/v0.5.18...v0.5.19
[0.5.18]: https://github.com/grosser/parallel/compare/v0.5.17...v0.5.18
[0.5.17]: https://github.com/grosser/parallel/compare/v0.5.16...v0.5.17
[0.5.16]: https://github.com/grosser/parallel/compare/v0.5.15...v0.5.16
[0.5.15]: https://github.com/grosser/parallel/compare/v0.5.14...v0.5.15
[0.5.14]: https://github.com/grosser/parallel/compare/v0.5.13...v0.5.14
[0.5.13]: https://github.com/grosser/parallel/compare/v0.5.12...v0.5.13
[0.5.12]: https://github.com/grosser/parallel/compare/v0.5.11...v0.5.12
[0.5.11]: https://github.com/grosser/parallel/compare/v0.5.10...v0.5.11
[0.5.10]: https://github.com/grosser/parallel/compare/v0.5.9...v0.5.10
[0.5.9]: https://github.com/grosser/parallel/compare/v0.5.8...v0.5.9
[0.5.8]: https://github.com/grosser/parallel/compare/v0.5.7...v0.5.8
[0.5.7]: https://github.com/grosser/parallel/compare/v0.5.6...v0.5.7
[0.5.6]: https://github.com/grosser/parallel/compare/v0.5.5...v0.5.6
[0.5.5]: https://github.com/grosser/parallel/compare/v0.5.4...v0.5.5
[0.5.4]: https://github.com/grosser/parallel/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/grosser/parallel/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/grosser/parallel/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/grosser/parallel/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/grosser/parallel/compare/v0.4.6...v0.5.0
[0.4.6]: https://github.com/grosser/parallel/compare/v0.4.5...v0.4.6
[0.4.5]: https://github.com/grosser/parallel/compare/v0.4.4...v0.4.5
[0.4.4]: https://github.com/grosser/parallel/compare/v0.4.3...v0.4.4
[0.4.3]: https://github.com/grosser/parallel/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/grosser/parallel/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/grosser/parallel/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/grosser/parallel/compare/v0.3.7...v0.4.0
[0.3.7]: https://github.com/grosser/parallel/compare/v0.3.6...v0.3.7
[0.3.6]: https://github.com/grosser/parallel/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/grosser/parallel/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/grosser/parallel/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/grosser/parallel/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/grosser/parallel/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/grosser/parallel/releases/tag/v0.3.1
