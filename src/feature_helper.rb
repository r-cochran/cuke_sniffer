class FeatureHelper

  def self.build_features_from_folder(folder_path)
    features = []
    Dir.entries(folder_path).each_entry do |file_name|
      unless FILE_IGNORE_LIST.include?(file_name)
        file_name = "#{folder_path}/#{file_name}"
        if File.directory?(file_name)
          features << build_features_from_folder(file_name)
        elsif file_name.include?(".feature")
          features << Feature.new(file_name)
        end
      end
    end
    features.flatten
  end
end