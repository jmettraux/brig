
module BrigHelper

  def build_brig

    Brig.build('spec_target')
  end

  def build_brig_if_necessary

    return if File.exist?('spec_target')

    build_brig
  end

  def nuke_brig

    FileUtils.rm_rf('spec_target')
  end
end

