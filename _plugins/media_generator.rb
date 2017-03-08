#-----------------------------------------------------------------------------------------
#
# This plugin read all the individual media files(old and new) and write them into single json file.
# Also it reads all the individual model instance files and write them to single json file.
# When jekyll server running all these files will be created and updated accordingly.
#
#---------------------------------------------------------------------------------------

module Jekyll
  class MediaGenerator < Generator
    # This generator is safe from arbitrary code execution.
    safe true
    require 'pry'
    def generate(_site)
      create_media_files media_dir, 'media' # creates image_data.json
      create_old_media old_media_dir # creates old_media.json
      create_model_files('models')
    end

    private

    def definitions_dir
      File.join('_data', '_definitions')
    end

    def model_dir
      File.join('_data', '_models')
    end

    def media_dir
      File.join('_assets', 'image_data')
    end

    def old_media_dir
      File.join('_assets', 'images')
    end

    def absolute_dir(dir)
      File.expand_path(File.join(Dir.pwd, dir))
    end

    def save(filename, content)
      File.open("#{filename}.json", 'w') do |file|
        file.write(JSON.pretty_generate(content))
      end
    end

    def clean_file(filename)
      `rm #{filename}.json` if File.exist?("#{filename}.json")
    end

    # create old_media json for the images fetching from Github
    def create_old_media(folder)
      clean_file('old_media')
      folder = absolute_dir(folder)
      return [] unless File.directory? folder
      old_media_data = []
      Dir[File.join(folder, '/*')].each do |file|
        old_media_data << { :path => File.basename(file), :sha => '' }
      end
      save 'old_media', old_media_data
    end

    def create_media_files(folder, file_name = 'models')
      clean_file(file_name)
      abs_folder = absolute_dir(folder)
      return unless File.directory? abs_folder
      writing_file_data = Dir[File.join(abs_folder, '*.json')].map do |file|
        data = JSON.parse File.read(file)
        data[:git_file_name] = File.join(folder, File.basename(file))
        data
      end.flatten
      save file_name, writing_file_data
    end

    def create_model_files(file_name)
      clean_file(file_name)
      abs_folder = absolute_dir(definitions_dir)
      sub_folders = []
      return unless File.directory? abs_folder
      Dir.glob("#{definitions_dir}/**/*.json").each { |file| sub_folders << File.basename(file, '.*') } if file_name == 'models'
      hash = Hash.new { |h, k| h[k] = [] }
      sub_folders.each do |sub_folder|
        hash[sub_folder.to_s] << [name: '', title:'', file: ''] unless File.directory?(File.join(model_dir, sub_folder))
        Dir[File.join(model_dir, sub_folder, '*.json')].map do |file|
          data = JSON.parse File.read(file)
          attrs = {}
          attrs[:name] = data['name'] if data.has_key?('name')
          attrs[:title] = data['title'] if data.has_key?('title')
          attrs[:file] = File.basename(file)
          hash[sub_folder.to_s] << [attrs]
        end
      end
      save file_name, hash
    end
  end
end
