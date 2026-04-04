# Changelog

## Unreleased

### Added / Fixed / Changed

- Add here when making a PR

## 2.0.0

### Changed

- Require Ruby >= 3.3
- Add Ruby 4 Ractor support

## 1.28.0

### Fixed

- Dump undumpable exceptions without cause if that fixes the issue

## 1.27.0

### Added

- Ruby 3.4 support

## 1.26.3

### Fixed

- Ensure not to use old `concurrent-ruby`

## 1.26.2

### Fixed

- Revert v1.26.1 revert; restore cgroups-aware processor count

## 1.26.1

### Fixed

- Revert cgroups-aware processor count from v1.26.0

## 1.26.0

### Changed

- Use cgroups-aware processor count by default

## 1.25.1

### Fixed

- Improve speed for `Get-CimInstance` on Windows

## 1.25.0

### Removed

- Remove dependency on `win32ole`

### Changed

- Require Ruby >= 2.7

## 1.24.0

### Added

- Add `:finish_in_order` option

## 1.23.0

### Added

- Add `filter_map`

### Changed

- Inline the methods of ProcessorCount module

## 1.22.1

### Fixed

- Fix compilation on Windows

## 1.22.0

### Added

- Ractor support
- Ruby 3.1 support

## 1.21.0

### Fixed

- Avoid thousands of `lsof` warnings in chroot
- Fix processor count detection on macOS darwin20

## 1.20.2

### Fixed

- Add support for darwin20 processor count detection

## 1.20.1

### Changed

- Switch CI from Travis to GitHub Actions

## 1.20.0

### Added

- Allow breaking with value

### Changed

- Bump Ruby requirements

## 1.19.2

### Fixed

- Allow timeout usage inside of threads

## 1.19.1

### Added

- Add project metadata to the gemspec

### Fixed

- Rescue core exceptions like rspec does

## 1.19.0

### Fixed

- Make sure to also rescue non-standard errors

## 1.18.0

### Added

- Allow overriding the number of processors with an env variable

## 1.17.0

### Fixed

- Fix async exception timing

## 1.16.2

### Fixed

- Prefer local variable over instance variable in worker replacement

## 1.16.1

### Fixed

- Calculate lap correctly to replace worker in isolation mode

## 1.16.0

### Fixed

- Child gracefully halts when parent already died
- Ensure threads are killed on completion

## 1.15.0

### Fixed

- Avoid nil errors by initializing all workers during isolation runs

## 1.14.0

### Fixed

- Avoid deprecation warnings
- Skip BigDecimal warnings explicitly

## 1.13.0

### Added

- Enforce a single worker type

### Fixed

- Ensure that `.map` doesn't modify options passed in

## 1.12.1

### Fixed

- Ensure the trapped signal is callable within the Interrupt signal handler

## 1.12.0

### Added

- Ruby 2.4 support

### Fixed

- Reference the Tempfile so it's not GC'd/removed too early

## 1.11.2

### Fixed

- Synchronize worker replacement to avoid race condition

## 1.11.1

### Fixed

- Fix typo (bracktrace => backtrace), use `attr_reader`
- Remove bindings stack added by `better_errors` gem

## 1.11.0

### Added

- Add `any?` and `all?` methods

### Fixed

- Handle kill and break exceptions in `work_direct`
- Make version not be required twice when using via git source

## 1.10.0

### Added

- Add `Parallel.worker_number` via thread local
- Add timeout support

### Fixed

- Make undumpable exceptions traceable
- Do not call kill method if thread is nil

## 1.9.0

### Added

- Expose `parallel_worker_number` via thread local so tasks can coordinate external dependencies

## 1.8.0

### Added

- Add isolation mode

## 1.7.0

### Added

- Support `true` in progress

## 1.6.2

### Fixed

- Don't call `:finish` hook if there was an exception

## 1.6.1

### Fixed

- `Parallel.map` writes its output safely

## 1.6.0

### Changed

- Stop rescuing interrupt and remove unnecessary thread kill code

## 1.5.1

### Fixed

- Make ensure logic not get called when JRuby exits

## 1.5.0

### Changed

- Refactor into JobFactory
- Extract UserInterruptHandler

### Fixed

- Fix JRuby threading vs Ctrl+C

## 1.4.1

### Added

- Add `progress_options` option for `ruby-progressbar` library

## 1.4.0

### Fixed

- Stop workers in additional cases when exception is raised in processes
- Ensure `EOFError` in process is raised as EOF, not `DeadWorker`

## 1.3.4

### Fixed

- Notify start and finish with zero workers

## 1.3.3.1

### Fixed

- Fix missing thread require
- Simplify require

## 1.3.3

### Fixed

- Initialize instance variable before access

## 1.3.2

### Added

- Allow custom definition of interrupt signal
- Pass full options to `in_threads`

## 1.3.1

### Fixed

- Fix Queue not being defined in REE / 1.9.3

## 1.3.0

### Added

- Support lambdas in threads and processes

### Changed

- Refactored queue wrapping and mutex handling

## 1.2.4

### Changed

- Do not store all values in an array for `each` + finish/progress; discard after instrumentation

## 1.2.3

### Added

- Support progress and finish callbacks
- Pass results to finish callback on each

## 1.2.2

### Fixed

- Do not silently fail when getting interrupted

## 1.2.1

### Added

- Add progressbar support

## 1.2.0

### Fixed

- Preserve and call original interrupt to not kill irb sessions

## 1.1.2

### Fixed

- Do not kill yourself so stdout can get flushed properly

## 1.1.1

### Added

- Introduce `Parallel::Kill` to stop all execution

## 1.1.0

### Fixed

- Do not re-raise interrupts or SystemExit

## 1.0.0

### Added

- Yield results to finish callback

### Changed

- Call finish with result for more flexibility

## 0.9.2

### Added

- Allow use of Postgres

### Fixed

- Keep compatible with REE
- Fix GC detection

## 0.9.1

### Added

- Add license to gem

## 0.9.0

### Added

- More accurate processor core counts for Linux and Windows
- Only attempt multiprocessing if `Process.fork` is available
- JRuby threads as default for JRuby platform

## 0.8.4

### Added

- FreeBSD sysctl support for processor count

## 0.8.3

### Fixed

- Fix uninitialized instance variable `@to_be_killed`

## 0.8.2

### Changed

- Avoid slowness when assigning/passing results that will be discarded

## 0.8.1

### Fixed

- Fix copy-paste error in `physical_processor_count` for Win32

## 0.8.0

### Fixed

- Under Linux, physical core count is number of physicals * cores/physical
- Add Ruby 1.8.7 support
- Handle case where cores not visible in `/proc/cpuinfo`

## 0.7.1

### Added

- Processor count support for NetBSD

## 0.7.0

### Fixed

- Fix finish order
- Kill threads on Ctrl+C

## 0.6.5

### Fixed

- Correct number of CPUs in KVM

## 0.6.4

### Added

- Handle return in parallel threads/processes using `Parallel::Break`

## 0.6.3

### Added

- Add MIT-LICENSE.txt

## 0.6.2

### Changed

- Experiment with signed certs

## 0.6.1

### Fixed

- `DeadWorker` uses common ancestor `Exception` for EOF and EPIPE

## 0.6.0

### Added

- Nice notification when workers die
- Nice error message when trying to write to a dead process

### Changed

- Extract worker class
- Refactor instrumentation

## 0.5.21

### Changed

- Memoize processor counts as they don't change

## 0.5.20

### Added

- Monitor progress with `:start` and `:finish` callbacks
- Progressbar support

## 0.5.19

### Fixed

- Ignore dead children

## 0.5.18

### Added

- Cygwin support for processor count

## 0.5.17

### Fixed

- Additional distro support for processor count

## 0.5.16

### Changed

- Bundlerify gemspec

## 0.5.15

### Fixed

- Fix complex object de/serialisation

## 0.5.14

### Fixed

- Raise undumpable exceptions properly
- Silence a warning

## 0.5.13

### Added

- First try on physical CPU count

## 0.5.12

### Added

- Processor count support for Solaris

## 0.5.11

### Fixed

- Fix pipe-closing file descriptor issue

## 0.5.10

### Changed

- Switch license to MIT
- Refactor worker creation

## 0.5.9

### Fixed

- Default `processor_count` to 1 when unknown
- Remove self-reference so it can be easily vendored

## 0.5.8

### Changed

- Simplify work in processes

## 0.5.7

### Added

- Support 0 threads/processes for debugging and benchmarking

### Changed

- Simplified command for Linux CPU detection

## 0.5.6

### Changed

- Count hyper-threads instead of cores

## 0.5.5

### Added

- Windows support for number of processes

## 0.5.4

### Fixed

- Support any version of Darwin
- Support JRuby on OS X

## 0.5.3

### Added

- Support any Enumerable (anything that has `to_a`)

## 0.5.2

### Fixed

- Guard against missing `hwprefs` on OS X 10.6+

## 0.5.1

### Fixed

- Let other jobs finish clean when one raises
- Join all threads if one got an exception

## 0.5.0

### Changed

- Split thread and process handling
- Preserve order of elements
- Remove encoding/decoding and duping overhead

## 0.4.6

### Fixed

- Fix `hwprefs` `thread_count` to `cpu_count` on Leopard

## 0.4.5

### Added

- Detect Hyperthreading on Darwin

## 0.4.4

### Fixed

- Make tests pass on OS X with different UID array index
- Fix for Ruby 1.9 formatting and splat changes

## 0.4.3

### Added

- FreeBSD support

## 0.4.2

### Fixed

- Prevent Hold status in children

## 0.4.1

### Added

- Add `each_with_index` and `map_with_index`

## 0.4.0

### Changed

- Preserve results only if necessary

## 0.3.7

### Fixed

- Using nil as argument for `in_processes` should use the default

## 0.3.6

### Added

- Add `GC.copy_on_write_friendly=true`

## 0.3.5

### Added

- Support for Ranges
- High fork rate support

## 0.3.4

### Changed

- Internal improvements

## 0.3.3

### Changed

- Internal refactoring

## 0.3.2

### Added

- Add `Parallel.each`

## 0.3.1

### Added

- Initial release on RubyGems
