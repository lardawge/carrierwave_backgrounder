module GlobalMacros
  def load_file(full_path)
    File.open(full_path)
  end

  def file_count(path)
    Dir.entries(path).reject { |f| f =~ /\.|\../ }.size
  end
end