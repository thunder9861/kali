#!/usr/bin/ruby

# This script is invoked by the kernel when a core dump occurs.
# It intercepts the core file data via:
# /proc/sys/kernel/core_pattern
# It relies on these arguments in this order:
# %e %p %u %g %h %s
# See the declaration of the script call here:
# /etc/sysctl.conf
# kernel.core_pattern=|/root/bin/corefile %e %p %u %g %h %s

require 'etc'
require 'digest/md5'
require 'fileutils'

# Parse arguments
filename = ARGV[0]      # %e Executable filename
pid      = ARGV[1].to_i # %p Process ID
uid      = ARGV[2].to_i # %u User ID
gid      = ARGV[3].to_i # %g Group ID
hostname = ARGV[4]      # %h Hostname
signal   = ARGV[5].to_i # %s Signal Number

# Extract additional metadata
filepath          = File.readlink("/proc/#{pid}/exe")
access_time       = File.atime(filepath)
cmdline           = File.read("/proc/#{pid}/cmdline").gsub!(/\0/, "\n")
creation_time     = File.ctime(filepath)
environment       = File.read("/proc/#{pid}/environ").gsub!(/\0/, "\n")
filesize          = File.size(filepath)
group             = Etc.getgrgid(gid)[:name]
memory_map        = File.read("/proc/#{pid}/maps")
modification_time = File.mtime(filepath)
permissions       = File.stat(filepath).mode.to_s(8)
setuid            = File.stat(filepath).setuid?
signal_name       = Signal.list.invert[signal]
stack             = File.read("/proc/#{pid}/stack")
time              = Time.now.strftime("%Y-%m-%d-%H-%M")
username          = Etc.getpwuid(uid)[:name]
working_directory = File.readlink("/proc/#{pid}/cwd")

# Create core directory
directory = "/var/core"
Dir.mkdir(directory) unless Dir.exists? directory

# Create core filename
executable = File.join(directory, "#{filename}-#{time}.bin")
corefile   = File.join(directory, "#{filename}-#{time}.core")
metadata   = File.join(directory, "#{filename}-#{time}.metadata")

# Copy executable
FileUtils.copy(filepath, executable)

# Copy the core from stdin
core = File.new(corefile, "w")
begin
   while(chunk = STDIN.read)
      core.write chunk
      break if chunk == nil || chunk.length == 0
   end
rescue EOFError
   core.close
end
core.close

# Calculate the md5 hash of the core
core_md5 = Digest::MD5.hexdigest(File.read(corefile))

# Calculate the md5 hash of the executable
file_md5 = Digest::MD5.hexdigest(File.read(filepath))

# Create the metadata
f = File.new(metadata, "w")

# Print basic data
f.puts "Signal            : #{signal_name} (#{signal})"
f.puts "File              : #{filepath}"
f.puts "File Size         : #{filesize}"
f.puts "File MD5          : #{file_md5}"
f.puts "Core MD5          : #{core_md5}"
f.puts "Core Time         : #{time}"
f.puts "Creation Time     : #{creation_time}"
f.puts "Modification Time : #{modification_time}"
f.puts "Access Time       : #{access_time}"
f.puts "Hostname          : #{hostname}"
f.puts "PID               : #{pid}"
f.puts "User              : #{username} (#{uid})"
f.puts "Group             : #{group} (#{gid})"
f.puts "Permissions       : #{permissions}"
f.puts "Setuid            : #{setuid}"
f.puts "Working Directory : #{working_directory}"
f.puts ""

# Print verbose data
f.puts "Command line:          \n#{cmdline}\n"
f.puts "Stack:                 \n#{stack}\n"
f.puts "Memory Map:            \n#{memory_map}\n"
f.puts "Environment Variables: \n#{environment}\n"
f.flush

# Get the registers and backtrace from GDB
f.puts "Loading GDB..."
f.puts "Running 'backtrace' and 'info registers'"
f.flush
r, w = IO.pipe
child = fork{$stdin.reopen(r); $stdout.reopen(f); $stderr.reopen(f); exec "/usr/bin/gdb -q -c #{corefile}"}
w.puts "set height 0"
w.puts "backtrace"
w.puts "info registers"
w.puts "quit"
Process.wait

f.close
exit 0
