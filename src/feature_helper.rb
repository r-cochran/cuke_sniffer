class FeatureHelper

  def self.build_features_from_folder(folder_path)
    #TODO - WHY IS I A HASH?
    features_hash = {}
    Dir.entries(folder_path).each_entry { |file_name|
      unless (FILE_IGNORE_LIST.include?(file_name))
        file_name = "#{folder_path}/#{file_name}"
        if (File.directory?(file_name))
          sub_hash = build_features_from_folder(file_name)
          sub_hash.each_key { |key| features_hash[key] = sub_hash[key] }
        elsif (file_name.include?(".feature"))
          features_hash[file_name] = Feature.new(file_name)
        end
      end
    }
    features_hash
  end
end