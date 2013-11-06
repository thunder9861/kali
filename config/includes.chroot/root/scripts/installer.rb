#!/usr/bin/ruby

require "optparse"
require "fileutils"

################################################################################
# Define the Configuration parameters

module Configuration

   MBR_SIZE_MB         = 2
   BOOT_SIZE_MB        = 100
   INSTALL_SIZE_MB     = 200
   DATA_SIZE_MB        = 1024
   SWAP_RAM_MULTIPLIER = 1.25
   SQUASHFS_RATIO      = 4.0

end

################################################################################
# Patches

class String
   
   # Unindent heredocs
   def unindent
      gsub /^#{self[/\A\s*/]}/, ""
   end

   def unindent!
      gsub! /^#{self[/\A\s*/]}/, ""
   end

   # Check if a string represents a number
   def numeric?
      Float(self) != nil rescue false
   end

end

class Float

   def round_to(n)
      return (self / n).round * n
   end
   
   def ceil_to(n)
      return (self / n).ceil * n
   end

   def floor_to(n)
      return (self / n).floor * n
   end
   
end

class Integer

   def round_to(n)
      return self.to_f.round_to n
   end
   
   def ceil_to(n)
      return self.to_f.ceil_to n
   end
   
   def floor_to(n)
      return self.to_f.floor_to n
   end
   
end

################################################################################
# Helpers

# Define some constants
module Constants
   
   KB_IN_BYTES  = 1024
   MB_IN_BYTES  = 1024 * 1024
   GB_IN_BYTES  = 1024 * 1024 * 1024
   SECTOR_SIZE  = 512
   
end

# A module that can run shell commands
module ShellRunner

   # bool run(string, ^string)
   def sh(command, input = nil)

      result = false

      puts "Running command: #{command}"

      if not input.nil?
         input.unindent!
         puts `echo "#{input}" | #{command}`
         result = $?.exitstatus == 0
      else
         puts `#{command}`
         result = $?.exitstatus == 0 
      end

      puts "Result: #{result}"
      return result

   end

   # bool batch_sh([string])
   def batch_sh(commands)
   
      result = true
      
      for cmd in commands
         result &&= sh(cmd) if result
      end
      
      return result
   
   end

end

# A module that can run batch calls
module Batcher
   
   # bool batch_call([symbol])
   def batch_call(commands)
   
      result = true
      
      for cmd in commands
         result &&= send(cmd) if result
      end
      
      return result
   
   end
   
end

################################################################################
# Main

class Installer

   include ShellRunner
   include Batcher
   include Constants
   include Configuration

   # void initialize(string, string, ^{})
   def initialize(disk, password, options = {})
   
      @DISK = disk
      @PASSWORD = password
      
      parse_options(options)
      build_call_lists
      calculate_sizes
      
   end

   # void parse_options({})
   def parse_options(options)
   
      @SWAP = options[:swap]
      @REINSTALL = options[:reinstall]
   
   end
   
   # void build_call_lists(void)
   def build_call_lists
   
      @CLEANUP_CALLS = []
      @CLEANUP_CALLS << :unmount_boot
      @CLEANUP_CALLS << :unmount_chroot
      @CLEANUP_CALLS << :unmount_aufs
      @CLEANUP_CALLS << :unmount_lvm
      @CLEANUP_CALLS << :close_luks
   
      @PREINSTALL_CALLS = []
      @PREINSTALL_CALLS << :validate
      @PREINSTALL_CALLS << :partition
      @PREINSTALL_CALLS << :luks_format
      @PREINSTALL_CALLS << :open_luks
      @PREINSTALL_CALLS << :setup_volumes
      @PREINSTALL_CALLS << :copy_squashfs
      @PREINSTALL_CALLS << :mount_lvm
      @PREINSTALL_CALLS << :mount_aufs
      @PREINSTALL_CALLS << :mount_chroot
      @PREINSTALL_CALLS << :mount_boot
      @PREINSTALL_CALLS << :copy_boot
      
      @MOUNT_CALLS = []
      @MOUNT_CALLS << :open_luks
      @MOUNT_CALLS << :mount_lvm
      @MOUNT_CALLS << :mount_aufs
      @MOUNT_CALLS << :mount_chroot
      @MOUNT_CALLS << :mount_boot
      
      @CHROOT_CALLS = []
      
      @CHROOT_CALLS << :set_password
      @CHROOT_CALLS << :create_fstab
      @CHROOT_CALLS << :create_crypttab
      @CHROOT_CALLS << :update_initramfs
      @CHROOT_CALLS << :configure_grub
      
      @POSTINSTALL_CALLS = []
      @POSTINSTALL_CALLS << :install_grub
      @POSTINSTALL_CALLS << :unmount_boot
      @POSTINSTALL_CALLS << :unmount_chroot
      @POSTINSTALL_CALLS << :unmount_aufs
      @POSTINSTALL_CALLS << :unmount_lvm
      @POSTINSTALL_CALLS << :close_luks
      
      @REINSTALL_CALLS = []
      @REINSTALL_CALLS << :validate
      @REINSTALL_CALLS << :open_luks
      @REINSTALL_CALLS << :resize_root
      @REINSTALL_CALLS << :copy_squashfs
      @REINSTALL_CALLS << :close_luks
   
   end

   # int get_disk_size(void)
   def get_disk_size
      
      # Run fdisk
      fdisk = `fdisk -l #{@DISK}`
      
      # Find the disk size in bytes
      match = fdisk.match %r{^Disk #{@DISK}: .*}
      
      # Parse the disk size
      disk = match[0].split[4].to_i
      
      return disk.floor_to SECTOR_SIZE
      
   end
   
   # int get_mbr_size(void)
   def get_mbr_size
   
      return MBR_SIZE_MB
   
   end
   
   # int get_boot_size(void)
   def get_boot_size
      
      # Return the next highest multiple of 512 from the Configuration value
      return (BOOT_SIZE_MB * MB_IN_BYTES).ceil_to SECTOR_SIZE
      
   end
   
   # int get_root_size(void)
   def get_root_size
      
      # Get the size of the filesystem
      root = File.size "/lib/live/mount/medium/live/filesystem.squashfs"
      
      # Return the next multiple of 512
      return root.ceil_to SECTOR_SIZE
      
   end
   
   # int get_install_size(void)
   def get_install_size
   
      # Return the next highest multiple of 512 from the Configuration value
      return (INSTALL_SIZE_MB * MB_IN_BYTES).ceil_to SECTOR_SIZE
      
   end
   
   # int get_swap_size(void)
   def get_swap_size
            
      # Open kernel memory information
      f = File.open("/proc/meminfo", "r")
      
      # Look for the total memory
      m = f.read.match(/^MemTotal.*/)
      
      # Close file
      f.close
      
      # Read the value for ram
      ram_kb = m[0].split()[1].to_i
      
      # Determine the amount of swap
      swap_kb = ram_kb * SWAP_RAM_MULTIPLIER
      
      # Convert to bytes
      swap = swap_kb * KB_IN_BYTES
      
      # Round to nearest 512
      swap = swap.round_to SECTOR_SIZE
      
      return swap

   end
   
   # int get_data_size(void)
   def get_data_size
   
      # Return the next highest multiple of 512 from the Configuration value
      return (DATA_SIZE_MB * MB_IN_BYTES).ceil_to SECTOR_SIZE
      
   end

   # int get_rw_size(void)
   def get_rw_size
   
      # Get the size of the rw layer
      # Squashfs has a best compression ratio of 25% and an average of 33%
      # We want the aufs layer to be 1.25 times the size of the uncompressed squashfs image
      # Therefore, multiply by 4
      return (get_root_size() * SQUASHFS_RATIO).floor_to(SECTOR_SIZE)
      
   end
   
   # void calculate_sizes(void)
   def calculate_sizes
      
      size = {}

      # Get the total disk size
      size[:disk] = get_disk_size

      # Get the mbr size
      size[:mbr] = get_mbr_size

      # Get the boot partition size
      size[:boot] = get_boot_size

      # Get the size of the squashfs image
      size[:root] = get_root_size

      # Get the swap size
      size[:swap] = get_swap_size

      # Get the install partition size
      size[:install] = get_install_size
 
      # Get the total size of the core installation
      size[:total] = size[:mbr] +
                     size[:boot] +
                     size[:root] +
                     size[:install]

      # Account for swap space
      if @SWAP
         size[:total] += size[:swap]
      end

      # Get the remaining space
      size[:free] = size[:disk] - size[:total]

      # If there isn't enough free space, exit with an error
      if size[:free] <= 0
         puts "Disk capacity is too small to install"
         return false
      end

      # Get data partition size
      data = get_data_size

      # Get rw partition size
      rw = get_rw_size
      
      # If we surpass the disk size
      if rw > size[:free]
      
         # Resize the partitions
         rw = size[:free] * 0.9
         data = size[:free] * 0.1
         
         # Floor to the nearest 512
         rw = rw.floor_to SECTOR_SIZE
         data = data.floor_to SECTOR_SIZE
         
      # If only the data partition surpasses the disk size
      elsif rw + data > size[:free]
      
         # Resize the data partition only
         data = size[:free] - rw
         
         # Floor to the nearest 512
         data = data.floor_to SECTOR_SIZE
         
      end
      
      # Adjust the free and total sizes
      size[:free] -= rw + data
      size[:total] += rw + data
      
      # Save the newly calculated sizes
      size[:rw] = rw
      size[:data] = data
      
      @SIZE = size
      
      return size

   end

     # bool validate(void)
   def validate

      result = true

      # Check that file exists

      # Check that string begins with /dev/

      # Check that identifier is 3 letters long

      # Check that identifier doesn't end with a number

      # Check that final size will fit inside disk

      return result

   end

   # bool partition(void)
   def partition

      # Generate the partition table
      # Leave room after the MBR for GRUB
      #start = MBR_SIZE_MB + BOOT_SIZE_MB
      
      # Calculate sector size

      input = <<-EOF
         4096,204800,L,*
         208896,,E
         ,0
         ,0
         ,,L
         EOF

      # Write partition table to disk
      command = "sfdisk -uS #{@DISK}"
      result = sh(command, input)

      # Zero the first 512 bytes of /dev/sda1
      command = "dd if=/dev/zero of=#{@DISK}1 bs=512 count=1"
      result &&= sh command

      result &&= File.exists? "#{@DISK}1"
      result &&= File.exists? "#{@DISK}5"

      return result

   end

   # bool luks_format(void)
   def luks_format

      input = <<-EOF
         #{@PASSWORD}
      EOF

      # Format the container
      command = "cryptsetup luksFormat #{@DISK}5"
      result = sh(command, input)

      return result

   end

   # bool open_luks(void)
   def open_luks
   
      input = <<-EOF
         #{@PASSWORD}
      EOF

      # Open the container
      command = "cryptsetup luksOpen #{@DISK}5 pvcrypt"
      result = sh(command, input)
      
      return result
         
   end

   # bool setup_volumes(void)
   def setup_volumes

      commands = []
      commands << "pvcreate -ff -y /dev/mapper/pvcrypt"
      commands << "vgcreate vg /dev/mapper/pvcrypt"
      commands << "lvcreate -n root -L #{@SIZE[:root]}B /dev/mapper/vg"
      commands << "lvcreate -n install -L #{@SIZE[:install]}B /dev/mapper/vg"
      commands << "lvcreate -n rw -L #{@SIZE[:rw]}B /dev/mapper/vg"
      commands << "lvcreate -n data -L #{@SIZE[:data]}B /dev/mapper/vg"
      commands << "lvcreate -n swap -L #{@SIZE[:swap]}B /dev/mapper/vg" if @SWAP
      commands << "mkfs.ext2 #{@DISK}1"
      commands << "mkfs.ext4 /dev/mapper/vg-install"
      commands << "mkfs.ext4 /dev/mapper/vg-rw"
      commands << "mkfs.ext4 /dev/mapper/vg-data"
      commands << "mkswap /dev/mapper/vg-swap" if @SWAP

      result = batch_sh(commands)
      
      return result

   end

   # bool resize_root(void)
   def resize_root
   
      return false
      
   end

   # bool copy_squashfs(void)
   def copy_squashfs

      input_file = "/lib/live/mount/medium/live/filesystem.squashfs"
      output_file = "/dev/mapper/vg-root"
      block_size = "2M" # Make this a config option
      root_size = get_root_size
      
      command = "dd if=#{input_file} bs=#{block_size} | bar -s #{root_size} | dd of=#{output_file} bs=#{block_size}"
      result = sh command

      return result
      
   end

   # bool mount_lvm(void)
   def mount_lvm
   
      FileUtils.mkdir_p "/mnt/lvm/root"
      FileUtils.mkdir_p "/mnt/lvm/install"
      
      commands = []
      commands << "vgchange -a y"
      commands << "mount -t squashfs -o ro /dev/mapper/vg-root /mnt/lvm/root"
      commands << "mount -t ext4 -o rw,noatime /dev/mapper/vg-install /mnt/lvm/install"
      result = batch_sh commands
      
      return result
      
   end

   # bool mount_aufs(void)
   def mount_aufs

      FileUtils.mkdir_p "/mnt/chroot"
      
      command = "mount -t aufs -o dirs=/mnt/lvm/install=rw:/mnt/lvm/root=ro aufs /mnt/chroot"
      result = sh command
      
      return result
      
   end

   # bool mount_chroot(void)
   def mount_chroot

      FileUtils.mkdir_p "/mnt/chroot/proc"
      FileUtils.mkdir_p "/mnt/chroot/sys"
      FileUtils.mkdir_p "/mnt/chroot/dev"
      
      commands = []
      commands << "mount -t proc proc /mnt/chroot/proc"
      commands << "mount -t sysfs sys /mnt/chroot/sys"
      commands << "mount -o bind /dev /mnt/chroot/dev"
      commands << "mount -t devpts none /mnt/chroot/dev/pts"
      
      # Mount the temporary drives
      
#      lines << "tmpfs /tmp tmpfs noatime,nodev,nosuid 0 0"
#      lines << "tmpfs /var/run tmpfs noatime,nodev,nosuid 0 0"
#      lines << "tmpfs /var/lock tmpfs noatime,nodev,nosuid 0 0"
#      lines << "tmpfs /var/log tmpfs noatime,nodev,nosuid 0 0"
      
      result = batch_sh commands
      
      return result
      
   end

   # bool mount_boot(void)
   def mount_boot
   
      # Do this as an aufs layer so the previous contents are visible
   
      FileUtils.mkdir_p "/mnt/chroot/boot"
      command = "mount #{@DISK}1 /mnt/chroot/boot"
      result = sh command
      
      return result
   
   end

   # bool unmount_boot(void)
   def unmount_boot
   
      command = "umount -f /mnt/chroot/boot"
      result = sh command
      
      return result
   
   end

   # bool copy_boot(void)
   def copy_boot
   
      # Copy everything from /boot to /mnt/chroot/boot
      FileUtils.cp_r(Dir.glob("/boot/*"), "/mnt/chroot/boot")
      
      return true
   
   end

   # bool set_password(void)
   def set_password
   
      return sh("chpasswd", "root:root")
   
   end

   # bool create_fstab(void)
   def create_fstab

      FileUtils.mkdir_p "/mnt/chroot/root/Downloads"

      lines = []
      lines << "\# <file system> <mount point> <type> <optios> <dump> <pass>"
      lines << "proc /proc proc nodev,nosuid,noexec 0 0"
      lines << "/dev/mapper/vg-root / squashfs loop 0 0"
      lines << "#{@DISK}1 /boot ext4 rw,noatime,errors=remount-ro 0 0"
      lines << "/dev/mapper/vg-data /root/Downloads ext4 rw,noatime,errors=remount-ro 0 0"
      lines << "/dev/mapper/vg-swap none swap sw 0 0" if @SWAP
      lines << "tmpfs /tmp tmpfs noatime,nodev,nosuid 0 0"
      lines << "tmpfs /var/run tmpfs noatime,nodev,nosuid 0 0"
      lines << "tmpfs /var/lock tmpfs noatime,nodev,nosuid 0 0"
      lines << "tmpfs /var/log tmpfs noatime,nodev,nosuid 0 0"

      # Write the file
      File.open("/etc/fstab", "w") do |f|
         lines.each{ |line| f.puts line }
      end

      result = File.exist? "/etc/fstab"

      return result
      
   end

   # bool create_crypttab(void)
   def create_crypttab

      # Get the uuid of the encrypted partition
      uuid = `blkid #{@DISK}5`
      uuid.gsub!('"', ' ')
      uuid = uuid.split[2]

      lines = []
      lines << "\# <target name> <source device> <key file> <options>"
      lines << "pvcrypt /dev/disk/by-uuid/#{uuid} none luks"
      
      # Write the file
      File.open("/etc/crypttab", "w") do |f|
         lines.each{ |line| f.puts line }
      end

      result = File.exist? "/etc/crypttab"

      return result
      
   end

   # bool update_initramfs(void)
   def update_initramfs

      FileUtils.ln_sf("/usr/sbin/update-initramfs.orig.initramfs-tools", "/usr/sbin/update-initramfs")
      result = sh "update-initramfs -u"

      return result
      
   end

   # bool configure_grub(void)
   def configure_grub

      # Move grub_probe to grub_probe.orig
      FileUtils.mv("/usr/sbin/grub-probe", "/usr/sbin/grub-probe.orig")
      
      # Make link from grub_probe to scripts/grub_probe.sh
      FileUtils.ln_s("/root/scripts/grub-probe.sh", "/usr/sbin/grub-probe")
      
      # Give grub-probe permissions
      FileUtils.chmod(0755, "/usr/sbin/grub-probe")
      
      # Get the uuid of the boot partition
      uuid = `blkid #{@DISK}1`
      uuid.gsub!('"', ' ')
      uuid = uuid.split[2]
      
      # Set grub probe environment variables
      ENV["GRUB_PROBE_DEVICE"] = "#{@DISK}1"
      ENV["GRUB_PROBE_FS"] = "ext2"
      ENV["GRUB_PROBE_FS_UUID"] = "#{uuid}"
      ENV["GRUB_PROBE_PARTMAP"] = "msdos"
      ENV["GRUB_PROBE_DRIVE"] = "(#{@DISK},msdos1)"
      
      # Write environment variables for persistence
      lines = []
      lines << "export GRUB_PROBE_DEVICE=#{@DISK}"
      lines << "export GRUB_PROBE_FS=ext2"
      lines << "export GRUB_PROBE_FS_UUID=#{uuid}"
      lines << "export GRUB_PROBE_PARTMAP=msdos"
      lines << "export GRUB_PROBE_DRIVE=(#{@DISK},msdos1)"

      # Write the file
      File.open("/root/.bash_environment", "a") do |f|
         lines.each{ |line| f.puts line }
      end
      
      # Sort and remove duplicates in .bash_environment

      result = sh "update-grub2"

      return result
      
   end
   
   # bool install_grub(void)
   def install_grub
   
      # Erase the MBR, NOT THE PARTITION TABLE
      # Then install grub
      commands = []
      commands << "dd if=/dev/zero of=#{@DISK} bs=446 count=1"
      commands << "grub-install --no-floppy --recheck --boot-directory=/mnt/chroot/boot #{@DISK}"
      
      result = batch_sh commands
      
      return result
      
   end

   # bool unmount_chroot(void)
   def unmount_chroot

      commands = []
      commands << "umount -f /mnt/chroot/proc"
      commands << "umount -f /mnt/chroot/sys"
      commands << "umount -f /mnt/chroot/dev"
      commands << "umount -f /mnt/chroot/dev/pts"

      # Unmount tmpfs

      result = batch_sh commands

      return result
      
   end

   # bool unmount_aufs(void)
   def unmount_aufs

      command = "umount -f /mnt/chroot"
      result = sh command

      return result
      
   end

   # bool unmount_lvm(void)
   def unmount_lvm

      commands = []
      commands << "umount -f /mnt/lvm/root"
      commands << "umount -f /mnt/lvm/install"

      result = batch_sh commands

      return result
       
   end

   # bool close_luks(void)
   def close_luks
   
      commands = []
      commands << "vgchange -a n"
      commands << "cryptsetup luksClose pvcrypt"
      
      result = batch_sh(commands)

      return result
      
   end

   # bool cleanup(void)
   def cleanup
      
      @CLEANUP_CALLS.each{ |c| send c }
      return true
      
   end

   # bool mount(void)
   def mount
      
      return batch_call @MOUNT_CALLS
      
   end

   # bool install(void)
   def install

      cleanup
   
      result = batch_call @PREINSTALL_CALLS
      
      if result
      
         # Chroot
         fork do
         
            Dir.chroot "/mnt/chroot"
            
            result &&= batch_call @CHROOT_CALLS
            
            Kernel.exit! result

         end
         
         # Wait for the child process to finish the chroot tasks
         Process.wait
         result &&= $?.exitstatus == 0 
         
      end
      
      result &&= batch_call @POSTINSTALL_CALLS

      return result

   end
   
   # bool reinstall(void)
   def reinstall
   
      result = batch_call @REINSTALL_CALLS
      
      return result
   
   end

end

################################################################################
# Parse options

options = {}
options[:quiet] = false
options[:reinstall] = false
options[:swap] = false
options[:verbose] = false
options[:yes] = false

option_parser = OptionParser.new do |opts|
   opts.on("-d", "--disk DISK", "Disk to install to (required) (ex: /dev/sda)"){|d| options[:disk] = d}
   opts.on("-m", "--mount", "Mount an existing installation (optional)"){options[:reinstall] = true}
   opts.on("-p", "--password PASSWORD", "Password to use (required)"){|p| options[:password] = p}
   opts.on("-q", "--quiet", "Suppress output (optional)"){options[:quiet] = true}
   opts.on("-r", "--reinstall", "Reinstall the image without formatting the disk (optional)"){options[:reinstall] = true}
   opts.on("-s", "--swap", "Enable swap partition (optional)"){|s| options[:swap] = true}
   opts.on("-v", "--verbose", "More output (optional)"){options[:verbose] = true}
   opts.on("-y", "--yes", "Assume yes to all questions (optional)"){options[:yes] = true}
   opts.on("-h", "--help", "Display options"){puts opts; exit}
end

begin
   option_parser.parse!
   mandatory = [:disk, :password]
   missing = mandatory.select{|parameter| options[parameter].nil?}
   if not missing.empty?
      puts "Missing options: #{missing.join(', ')}"
      puts option_parser
      exit
   end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
   puts $!.to_s
   puts option_parser
   exit
end

# Ask the user if they are SURE they want to do the requested action

installer = Installer.new(options[:disk], 
                          options[:password], 
                          options)
                          
result = installer.install

Kernel.exit result.nil? ? false : result

