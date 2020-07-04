namespace :autosde do
  namespace :oas do
    desc "generates openApi client for autosde site-manage API "

    task :generate_client  do
      require 'optimist'

      root = ManageIQ::Providers::Autosde::Engine.root #ManageIQ::Environment::APP_ROOT
      # parent folder for generated stuff ( contains input spec file)
      default_folder = "app/models/manageiq/providers/autosde/storage_manager/openapi_client"

      # oas file
      default_oas_file = 'site_manager_oas.json'

      abs_path = File.join(root, default_folder)
      # sub-folder in parent folder (will contain generated stuff, will be cleanup each time)
      generated = 'generated'
      generated_path = File.join(abs_path, generated)

      # clean old generated files
      rm_r generated_path if Dir.exist?(generated_path)

      # create folder for generated stuff anew
      mkdir_p generated_path

      # option parser
      options = Optimist.options(EvmRakeHelper.extract_command_options) do
        opt :output, 'Output folder', :type => :string, :short => 'o', :default => abs_path
        opt :source, 'oas file', :type => :string, :default => default_oas_file
      end

      # validate input
      error = validate_directory(options[:output])
      Optimist.die error if error

      file = options[:source]
      output_dir = options[:output]

      # build generated stuff
      sh build_command(output_dir, generated)

      # modify  files
      modify_generate_files(generated_path)

    end

    # helpers

    def build_command(output_dir, generated)
      puts ">>>>> #{output_dir}"
      # exclude some not needed things
      env = " --env JAVA_OPTS=\"${JAVA_OPTS} -Dapis -Dmodels  -DsupportingFiles -DmodelDocs=false -DmodelTests=false -DapiTests=false -DapiDocs=false\" "
      "docker run #{env} --rm -v #{output_dir}:/local openapitools/openapi-generator-cli generate -i /local/site_manager_oas.json -g ruby -o /local/#{generated} --skip-validate-spec"
    end

    def validate_directory(directory)
      unless File.directory?(directory)
        return 'Destination directory must exist'
      end
      unless File.writable?(directory)
        return 'Destination directory must be writable'
      end
      nil
    end

    def modify_generate_files(dir)
      file_name = 'openapi_client.rb'
      file_path = File.join(dir, 'lib', file_name)
      puts "file path => #{file_path}"
      search_pattern = 'require'
      replace_string = 'require_relative'
      text = File.read(file_path)
      content = text.gsub(/#{search_pattern}/, replace_string)
      File.open(file_path, "w") { |file| file << content }
    end

  end
end

