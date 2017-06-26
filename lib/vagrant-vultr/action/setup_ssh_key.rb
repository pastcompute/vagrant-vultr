require 'vagrant-vultr/helpers/client'

module VagrantPlugins
  module Vultr
    module Action
      class SetupSSHKey
        include Helpers::Client

        NAME = 'vagrant'.freeze

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @logger = Log4r::Logger.new('vagrant::vultr::setup_ssh_key')
	  @ssh_key_name = env[:machine].provider_config.ssh_key_name
        end

        def call(env)
          if @ssh_key_name != nil
            ssh_key_id = @client.ssh_key_id(@ssh_key_name)
          else
            ssh_key_id = @client.ssh_key_id(NAME)
          end
          unless ssh_key_id
            @logger.info 'SSH key does not exist. Creating new one...'
            key_path = File.expand_path("#{env[:machine].config.ssh.private_key_path.first}.pub")
            ssh_key_id = @client.create_ssh_key(NAME, File.read(key_path))
          end
          @logger.info "Using SSH key: #{ssh_key_id}."

          @app.call(env)
        end
      end
    end
  end
end
