
module BrigHelper

  SPEC_TARGET = File.expand_path(File.join(
    File.dirname(__FILE__), '..', '..', 'spec_target'))

  def build_brig

    builder = File.expand_path(File.join(
      File.dirname(__FILE__), '..', '..', 'bin/build.rb'))

    do_exec(builder, '-v', SPEC_TARGET)
  end

  def nuke_brigs

    #FileUtils.rm_rf('spec_target')
    #do_exec('rm', '-fR', "#{SPEC_TARGET}*")
    `sudo rm -fR #{SPEC_TARGET}*`
  end

  protected

  def do_exec(*command)

    command.unshift('sudo')

    Open3.popen3(*command) do |si, so, se, wt|
      stderr = se.read
      raise "#{command.inspect} failed : #{stderr}" unless stderr.empty?
    end
  end
end

