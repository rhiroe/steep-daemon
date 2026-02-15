# Steep::Daemon

**Daemon mode for Steep type checker** - Keep Steep's LSP Server running persistently to avoid expensive RBS environment reloading on each check. This provides **10-100x faster type checking** for subsequent runs!

## Overview

This gem adds daemon mode functionality to [Steep](https://github.com/soutaro/steep), a static type checker for Ruby. By keeping Steep's LSP Server (Master + Workers) running persistently, the expensive RBS environment loading only happens once. Subsequent `steep check` invocations connect to the daemon via Unix socket and skip the startup cost.

**Note**: This is a temporary solution until the daemon mode is merged into Steep. See the [upstream PR](https://github.com/rhiroe/steep/tree/feat/server-daemon) for details.

## Features

- 🚀 **Dramatic speedup**: Type checking after the first run is 10-100x faster
- 🔄 **Automatic RBS re-warming**: Watches for signature changes and reloads RBS environment automatically
- 🛡️ **Transparent fallback**: Falls back to standard mode if daemon is not available
- 🎯 **Drop-in replacement**: Just require the gem, and `steep check` automatically uses daemon mode
- 🔌 **Unix socket communication**: Efficient IPC without network overhead

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'steep-daemon'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install steep-daemon
```

## Usage

### Basic Usage

Simply require the gem before running Steep:

```ruby
# In your Gemfile
gem 'steep'
gem 'steep-daemon'
```

Or in your code:

```ruby
require 'steep/daemon'
```

The monkey patch is automatically applied to `Steep::Driver::Check#run`, enabling daemon mode by default.

### CLI Commands

The gem provides a `steep-daemon` command for managing the daemon server:

```bash
# Start the daemon server
bundle exec steep-daemon start

# Check daemon status
bundle exec steep-daemon status

# Stop the daemon server
bundle exec steep-daemon stop

# Restart the daemon server
bundle exec steep-daemon restart

# Show help
bundle exec steep-daemon help
```

**Note**: The daemon will start automatically on the first `steep check` run, so manually starting it is optional.

### Programmatic Control

You can also control the daemon programmatically:

```ruby
# Start the daemon manually (optional)
Steep::Daemon.start

# Check daemon status
Steep::Daemon.status

# Stop the daemon
Steep::Daemon.stop
```

### Type Checking with Daemon Mode

Once the gem is loaded, just run `steep check` as usual:

```bash
bundle exec steep check
```

On the first run, the daemon will:
1. Start in the background
2. Load the RBS environment (slow, 10-30 seconds)
3. Perform the type check

On subsequent runs:
1. Connect to the existing daemon via Unix socket
2. Perform type check immediately (fast, <1 second for startup)

### Disabling Daemon Mode

If you want to disable daemon mode for a specific run, you can patch the driver:

```ruby
require 'steep/daemon'

driver = Steep::Driver::Check.new(...)
driver.use_daemon = false
driver.run
```

### Background File Watcher

The daemon includes a background file watcher that:
- Monitors `.rb` and `.rbs` files for changes
- Automatically reloads RBS environment when signatures change
- Keeps the daemon warm and ready for the next type check

### Daemon Management

```ruby
# Check if daemon is running
Steep::Daemon.running?  # => true/false

# Check if daemon is starting up
Steep::Daemon.starting?  # => true/false

# Get daemon paths
Steep::Daemon.socket_path  # => "/tmp/steep-server/steep-abc12345.sock"
Steep::Daemon.pid_path     # => "/tmp/steep-server/steep-abc12345.pid"
Steep::Daemon.log_path     # => "/tmp/steep-server/steep-abc12345.log"
```

### Viewing Daemon Logs

```bash
# Tail the daemon log
tail -f $(ruby -r steep/daemon -e "puts Steep::Daemon.log_path")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## How It Works

1. **Monkey Patching**: The gem patches `Steep::Driver::Check#run` to add daemon detection and socket communication
2. **Daemon Server**: Runs Steep's LSP Server (Master + Workers) in a background process
3. **Unix Socket**: Uses Unix domain sockets for fast IPC between client and daemon
4. **File Tracking**: Monitors file changes and syncs them to the daemon's workers
5. **Automatic Warm-up**: Pre-loads RBS environment on daemon startup for instant subsequent checks

## Implementation Details

This gem is based on the [upstream PR](https://github.com/rhiroe/steep/tree/feat/server-daemon) and includes:

- `Steep::Daemon` module for daemon lifecycle management
- `Steep::Daemon::Server` for the persistent LSP server
- `Steep::Daemon::Configuration` for socket/PID/log path management
- Monkey patch for `Steep::Driver::Check#run` to enable daemon mode

## Troubleshooting

### Daemon not starting

Check the daemon log:
```bash
cat $(ruby -r steep/daemon -e "puts Steep::Daemon.log_path")
```

### Stale daemon process

Clean up manually:
```ruby
Steep::Daemon.stop
Steep::Daemon.cleanup
```

### Fork not available

The daemon requires `Process.fork`, which is not available on Windows or some Ruby implementations.

## Performance Comparison

Without daemon (typical):
- First run: 25s (RBS loading: 20s + type check: 5s)
- Second run: 25s (RBS loading: 20s + type check: 5s)
- Third run: 25s (RBS loading: 20s + type check: 5s)

With daemon:
- First run: 25s (RBS loading: 20s + type check: 5s)
- Second run: 5s (type check only)
- Third run: 5s (type check only)

**Result**: 5x faster for typical projects, up to 100x faster for projects with heavy RBS dependencies!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rhiroe/steep-daemon.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
