# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Development versions now use `.dev` suffix (e.g., `0.1.0.dev`)
- Automated release workflow removes `.dev` for releases
- After release, version automatically bumps to next dev version

## [v0.1.0] - 2026-02-15

### Added
- Initial release of steep-daemon
- Daemon mode for Steep type checker with persistent LSP server
- Unix domain socket-based communication
- Background RBS file watcher
- CLI commands: start, stop, restart, status
- Monkey patch for Steep::Drivers::Check to enable daemon mode
- Comprehensive test suite (36 tests, 59 assertions)
- 10-100x performance improvement for type checking

### Technical Details
- Double-fork daemonization pattern
- Master + Workers architecture
- Automatic fallback to standard mode if daemon is unavailable
- File tracking and synchronization
- JSON-based protocol over Unix sockets

[Unreleased]: https://github.com/yourusername/steep-daemon/compare/v0.1.0...HEAD
[v0.1.0]: https://github.com/yourusername/steep-daemon/releases/tag/v0.1.0
