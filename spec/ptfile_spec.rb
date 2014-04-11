require 'rspec'
require 'ptfile'

FILES = %w{test1 test2}.collect{|e| File.expand_path('../' + e + '.mod', __FILE__) }

describe PTFile::Magic do
  magic = nil

  context 'with big table file' do
    it 'reads a file' do
      magic = File.open(FILES[0]) {|f| PTFile::Magic.read(f) }
      magic.should_not be_nil
    end

    it 'returns correct number of samples' do
      magic.samples.should eq 31
    end

    it 'returns correct magic string' do
      magic.extra.should eq 'M.K.'
      magic.has_magic?.should be_true
    end
  end
end

describe PTFile::Module do
  mod = nil

  context 'with big table file' do
    it 'initializes' do
      mod = PTFile::Module.new(:sample_table_size => 31, :has_magic => true)
      mod.should_not be_nil
    end

    it 'reads a file' do
      File.open(FILES[0]) {|f| mod.read(f) }
    end

    it 'parses the mod name correctly' do
      mod.title.should_not match(/[^[:print:]]/)
      mod.title.should eq 'Power X'
    end

    it 'parses the sample info table correctly' do
      mod.sample_table.each do |s|
        s.name.should_not match(/[^[:print:]]/)
        s.sample_length.should be >= 0
        s.sample_length.should be <= 65535
        s.volume.should be >= 0
        s.volume.should be <= 64
        s.repeat_offset.should be >= 0
        s.repeat_length.should be >= 0
        if s.sample_length > 1
          s.repeat_offset.should be <= s.sample_length
          s.repeat_length.should be <= (s.sample_length - s.repeat_offset)
        end
      end
    end

    it 'parses the sample data correctly' do
      mod.samples.length.should eq mod.samples_count
      mod.samples.each_with_index do |s, i|
        s.length.should eq mod.sample_table[i].sample_length
      end
    end

    it 'validates data correctly' do
      mod.sane?.should eq true
    end

    it 'clears the object properly' do
      mod.clear
      mod.samples_count.should eq 0
      mod.samples_lengths.should eq []
    end

    it 'can be reused' do
      File.open(FILES[1]) {|f| mod.read(f) }
      mod.sane?.should eq true
      mod.title.should eq 'the driver'
      mod.samples_count.should eq 14
      mod.samples.length.should eq 14
    end
  end
end

describe PTFile do
  it 'should have a VERSION constant' do
    PTFile.const_get('VERSION').should_not be_empty
  end

  it 'should read files properly' do
    mod = File.open(FILES[0]) {|f| PTFile.read(f) }
    mod.title.should eq 'Power X'
    mod = File.open(FILES[1]) {|f| PTFile.read(f) }
    mod.title.should eq 'the driver'
  end
end
