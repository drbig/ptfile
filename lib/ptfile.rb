require 'ptfile/version'
require 'bindata'

# The PTFile module
#
module PTFile
  # Class handling the 'magic' part
  #
  # We first need to determine if the file is either 15 or 31 samples-long,
  # so that we can set proper offsets to read the 'real' data.
  #
  class Magic < BinData::Record
    # Valid magic strings
    STRINGS = %w{M.K. M!K! FLT4 FLT8 6CHN 8CHN}

    # offset from 0 for 15 samples file
    skip    :length => 600
    string  :magic_one, :length => 4
    # offset from last definition for 31 sample file
    skip    :length => 476
    string  :magic_two, :length => 4

    # Check if has magic
    #
    # @return [true, false] whether magic is present
    def has_magic?
      if STRINGS.member? magic_one or STRINGS.member? magic_two
        true
      else
        false
      end
    end

    # Get number of samples
    #
    # This can be either 15 or 31, even if not all are used as instruments.
    # 'Comment' samples usually begin with '#'.
    #
    # @return [Integer] number of samples (15 or 31)
    def samples; magic_two == 'M.K.' ? 31 : 15; end

    # Get magic string
    #
    # @return [String, false] magic string or false
    def extra
      if STRINGS.member? magic_one
        magic_one
      elsif STRINGS.member? magic_two
        magic_two
      else
        false
      end
    end
  end

  # Class handling the actual module data
  #
  # There are many field with long names, hopefully self-explanatory.
  #
  class Module < BinData::Record
    mandatory_parameter :sample_table_size, :has_magic
    endian :big

    string    :title, :read_length => 20, :trim_padding => true

    # Here we have the sample info table, which is either 15 or 31 in length.
    array     :sample_table, :initial_length => :sample_table_size do
      string  :name, :read_length => 22, :trim_padding => true
      uint16  :sample_length
      bit4    :finetune
      uint8   :volume
      uint16  :repeat_offset
      uint16  :repeat_length
    end

    # Restart position only means that for Noisetracker, otherwise this is
    # some useless data.
    uint8     :song_positions
    uint8     :restart_position
    array     :pattern_table, :type => :uint8, :initial_length => 128
    string    :magic, :read_length => 4, :onlyif => :has_magic

    # Patterns are also held sequentially, so to get the actual number of
    # patterns defined we need to find the max number in the patterns_table,
    # and then adjust it to be 0-indexed.
    array     :patterns, :initial_length => lambda { pattern_table.max - 1} do
      array   :commands, :type => :uint8, :initial_length => 1024
    end

    # Each sample's data is written in sequence, and length of each sample has
    # to be read from samples_lengths array.
    array     :samples, :initial_length => :samples_count do
      array   :data, :type => :int8,\
        :initial_length => lambda { samples_lengths[index] }
    end

    # Clear everything
    #
    def clear
      @samples_count = @samples_lengths = @sane = nil
      super
    end

    # Check if what we got looks sane
    #
    # This may give false positives.
    #
    # @return [true, false] does read data look sane
    def sane?
      @sane ||=\
        (title.match(/[^[:print:]]/) == nil ) and\
        (not sample_table.collect\
          {|e| e.name.match(/[^[:print:]]/) == nil }.include? false) and\
        (samples_count == samples.length) and\
        (samples.collect{|e| e.length} == samples_lengths)
    end

    # Number of samples used in the file
    #
    # @return [Integer] number of samples used
    def samples_count
      @samples_count ||= sample_table.inject(0)\
        {|a,v| a += v.sample_length > 1 ? 1 : 0 }
    end

    # Return sample lengths (in bytes)
    #
    # @return [Array<Integer>] sample lengths
    def samples_lengths
      @samples_lengths ||= sample_table.select\
        {|e| e.sample_length > 1 }.collect{|e| e.sample_length }
    end
  end

  # Cached Magic object
  @magic = Magic.new
  # Possible Module object args combinations
  @perms = [31, 15].product([true, false])
  # Array of cached Module objects
  @cache = @perms.collect\
    {|p| Module.new(Hash[[:sample_table_size, :has_magic].zip(p)]) }

  # The preffered way to read a ProTracker file
  #
  # With built-in caching.
  #
  # @param io [IO] object to read data from
  #
  # @return [Module] the module data
  def self.read(io)
    @magic.clear
    @magic.read(io)
    io.rewind
    mod = @cache[@perms.index([@magic.samples, @magic.has_magic?])]
    mod.clear
    mod.read(io)
  end
end
