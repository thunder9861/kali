=begin
 This is a machine generated main stub file using stdlib-doc
 Created on Mon Aug 13 21:18:53 +0400 2012 by IntelliJ Ruby Stubs Generator.

 This documentation uses content from the book "Programming Ruby - The Pragmatic Programmer's Guide"
 Copyright (C) 2001 by Addison Wesley Longman, Inc. This material may be distributed only subject to the terms and conditions set forth in the Open Publication License, v1.0 or later (the latest version is presently available at http://www.opencontent.org/openpub/)).
 Distribution of substantively modified versions of this document is prohibited without the explicit permission of the copyright holder.
 Distribution of the work or derivative of the work in any standard (paper) book form is prohibited unless prior permission is obtained from the copyright holder.

 This documentation uses content form the article http://en.wikibooks.org/wiki/Ruby_Programming/Syntax/Variables_and_Constants#Pre-defined_Variables
 Text is available under the GNU Free Documentation License. (http://en.wikibooks.org/wiki/GNU_Free_Documentation_License)
=end

# Exception information message set by 'raise'.
# This variable is thread local.
$! = Exception.new #value is unknown, used for indexing.

# Array of backtrace of the last exception thrown.
# This variable is thread local.
$@ = [] #value is unknown, used for indexing.

# String matched by last successful pattern match in this scope.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$& = "" #value is unknown, used for indexing.

# String to the left of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$` = "" #value is unknown, used for indexing.

# String to the right of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$' = "" #value is unknown, used for indexing.

# Last bracket(group) matched by last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$+ = "" #value is unknown, used for indexing.

# 1st group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$1 = "" #value is unknown, used for indexing.

# 2nd group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$2 = "" #value is unknown, used for indexing.

# 3rd group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$3 = "" #value is unknown, used for indexing.

# 4th group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$4 = "" #value is unknown, used for indexing.

# 5th group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$5 = "" #value is unknown, used for indexing.

# 6th group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$6 = "" #value is unknown, used for indexing.

# 7th group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$7 = "" #value is unknown, used for indexing.

# 8th group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$8 = "" #value is unknown, used for indexing.

# 9th group of last successful pattern match.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope, thread local and read-only.
$9 = "" #value is unknown, used for indexing.

# information about last match in the current scope. The variables
# $1 - $9,  $&, $` and $' are given from $~.
# Ruby interpreter sets this variable to 'nil' after an unsuccessful match.
# This variable is defined in current scope and thread local.
$~ = MatchData.new #value is unknown, used for indexing.

# Deprecated.
# The flag for case insensitive, nil by default. If flag is not 'nil'
# and not 'false' pattern matches and string comparisions will be case
# insensitive.
$= = Object.new #value is unknown, used for indexing.

# Input record separator, newline by default. This variable is used by
# Kernel#gets to separate records. If $/ is 'nil', Kernel#gets will read the
# entire file at once.
$/ = "" #value is unknown, used for indexing.

# Alias to $/.
$-0 = $/ #value is unknown, used for indexing.

# Output record separator string for Kernel#print and IO#write.
# Default is nil.
$\ = "" #value is unknown, used for indexing.

# Output field separator string for Kernel#print and Array#join.
# Default is nil.
$, = "" #value is unknown, used for indexing.

# Default separator for String#split.
$; = "" #value is unknown, used for indexing.

# Alias to $;.
$-F = $; #value is unknown, used for indexing.

# Current input line number of last file that was read.
$. = 0 #value is unknown, used for indexing.

# Virtual concatenation file of files given on command line.
# $< supports File and Enumerable methods.
# This variable is read-only.
$< = File.new #value is unknown, used for indexing.

# Default output for Kernel#print, Kernel#printf. $stdout by default
$> = IO.new #value is unknown, used for indexing.

# Last line read by Kernel#gets or Kernel#readline.
# This variable is defined in current scope, thread local.
$_ = "" #value is unknown, used for indexing.

# Name of the script being executed. May be assignable.
$0 = "" #value is unknown, used for indexing.

# Command line arguments given for the script.
# Does not include interpreter arguments.
# This variable is read-only.
$* = [] #value is unknown, used for indexing.

# Process number of Ruby instance running this script.
# This variable is read-only.
$$ = 0 #value is unknown, used for indexing.

# Status of last executed child process.
# This variable is thread local and read-only.
$? = Process::Status.new #value is unknown, used for indexing.

# Load path for scripts and binary modules by load or require. You can
# append directory to load path using $: << dir_path.
# This variable is read-only.
$: = [] #value is unknown, used for indexing.

# Alias to $:.
$-I = $: #value is unknown, used for indexing.

# Alias to $:.
$LOAD_PATH  = $: #value is unknown, used for indexing.

# Module names loaded by require.
# Ruby interpreters have the following bug:
# 
# require "my/file"
# require "my/../my/file" #the same file as my/file
# p $"
#
# Produces: ["my/file.rb", "my/../my/file.rb"]
#
# This variable is read-only.
$" = [] #value is unknown, used for indexing.

# True if command-line option -d is set.
$DEBUG = Object.new #value is unknown, used for indexing.

# Alias to $DEBUG.
$-d = $DEBUG #value is unknown, used for indexing.

# Name of current input file from $<. Same as $<.filename.
# This variable is read-only.
$FILENAME = "" #value is unknown, used for indexing.

# Current standard error output.
$stderr = IO.new #value is unknown, used for indexing.

# Current standard input.
$stdin = IO.new #value is unknown, used for indexing.

# Current standard output. Assignment to $stdout is deprecated: use
# $stdout.reopen instead.
$stdout = IO.new #value is unknown, used for indexing.

# Determines current safe level. Safe level cannot be reduced by assignment.
# The default value of $SAFE is zero under most circumstances. The current
# value of $SAFE is inherited when new threads are created. However, within
# each thread, the value of $SAFE may be changed without affecting the value
# in other threads.
# This variable is thread local.
#
# $SAFE Constraints:
#   0    No checking of the use of externally supplied (tainted) data is performed.
#        This is Ruby's default mode.
#   >= 1 Ruby disallows the use of tainted data by potentially dangerous operations.
#   >= 2 Ruby prohibits the loading of program files from globally writable locations.
#   >= 3 All newly created objects are considered tainted.
#   >= 4 Ruby effectively partitions the running program in two. Nontainted objects may
#        not be modified. Typically, this will be used to create a sandbox: the program sets
#        up an environment using a lower $SAFE level, then resets $SAFE to 4 to prevent
#        subsequent changes to that environment.
$SAFE  = 0 #value is unknown, used for indexing.

# Verbose flag. Set by the -v, --version, -w, -W switch.
$VERBOSE  = Object.new #value is unknown, used for indexing.

# Alias to $VERBOSE.
$-v  = $VERBOSE #value is unknown, used for indexing.

# Alias to $VERBOSE.
$-w  = $VERBOSE #value is unknown, used for indexing.

# True if command-line option -a ("autosplit" mode) is set.
# This variable is read-only.
$-a = Object.new #value is unknown, used for indexing.

# If command-line option is set $_ will be split into $F.
$F = [] #value is unknown, used for indexing.

# If in-place-edit mode is set, this variable holds the extension, otherwise nil.
$-i = "" #value is unknown, used for indexing.

# Specifies multibyte code-set for strings and regular expressions.
# Equals to the -K command-line option.
# May be one of: u, U for UTF-8; or a, A, n, N for ASCII; e, E for EUC; s, S for SJIS
$-K = "" #value is unknown, used for indexing.

# True if command-line option -l is set ("line-ending processing" is on).
$-l = Object.new #value is unknown, used for indexing.

# True if command-line option -p is set ("loop" mode is on).
# This variable is read-only.
$-p  = Object.new #value is unknown, used for indexing.

# If a constant SCRIPT_LINES__ is defined as a Hash, then the source code of
# all files loaded by Kernel#load and Kernel#require will be stored in Hash.
#
# Example:
#   SCRIPT_LINES__ = {}
#   require 'my_file'
#   p SCRIPT_LINES__.keys
#   p SCRIPT_LINES__['./my_file']
#
#   produces:
#
#   ["./my_file.rb", "./other_file.rb"]
#   ["require 'other_file'\n", "\n"]
SCRIPT_LINES__ = nil #value is unknown, used for indexing.

require 'kernel'
require 'object'
require 'exception'
require 'standard_error'
require 'thread_error'
require 'regexp'
require 'comparable'
require 'numeric'
require 'system_stack_error'
require 'enumerable'
require 'string'
require 'precision'
require 'integer'
require 'bignum'
require 'index_error'
require 'security_error'
require 'set'
require 'name_error'
require 'no_method_error'
require 'range'
require 'file/constants'
require 'io'
require 'type_error'
require 'dir'
require 'zero_division_error'
require 'signal'
require 'system_exit'
require 'script_error'
require 'not_implemented_error'
require 'hash'
require 'regexp_error'
require 'date'
require 'rb_config'
require 'math'
require 'signal_exception'
require 'interrupt'
require 'syntax_error'
require 'struct'
require 'module'
require 'class'
require 'continuation'
require 'io_error'
require 'range_error'
require 'data'
require 'thread'
require 'gem'
require 'proc'
require 'process'
require 'array'
require 'no_memory_error'
require 'sorted_set'
require 'time'
require 'file_test'
require 'match_data'
require 'method'
require 'option_parser'
require 'stop_iteration'
require 'argument_error'
require 'float'
require 'float_domain_error'
require 'runtime_error'
require 'thread_group'
require 'unbound_method'
require 'etc'
require 'fixnum'
require 'false_class'
require 'r_doc'
require 'errno'
require 'eof_error'
require 'load_error'
require 'file_utils/stream_utils_'
require 'file_utils'
require 'true_class'
require 'nil_class'
require 'gc'
require 'system_call_error'
require 'file'
require 'local_jump_error'
require 'binding'
require 'symbol'
require 'object_space'
require 'marshal'
require 'generators'
