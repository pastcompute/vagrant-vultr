require 'vagrant-vultr/helpers/client'

module VagrantPlugins
  module Vultr
    module Action
      class Create
        include Helpers::Client

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @client = client
          @logger = Log4r::Logger.new('vagrant::vultr::create')
        end

        def call(env)
          region   = env[:machine].provider_config.region
          plan     = env[:machine].provider_config.plan
          os       = env[:machine].provider_config.os
          hostname = env[:machine].provider_config.hostname
          label    = env[:machine].provider_config.label
          snapshot = env[:machine].provider_config.snapshot
          ssh_key_name = env[:machine].provider_config.ssh_key_name
		  enable_ipv6 = env[:machine].provider_config.enable_ipv6
		  enable_private_network = env[:machine].provider_config.enable_private_network

          if ssh_key_name == nil
            ssh_key_name = Action::SetupSSHKey::NAME
          end

          @logger.info "Creating server with:"
          @logger.info "  -- Region: #{region}"
          @logger.info "  -- OS: #{os}"
          @logger.info "  -- Plan: #{plan}"
          @logger.info "  -- Snapshot: #{snapshot}"
          @logger.info "  -- Enable IPv6: #{enable_ipv6}"
          @logger.info "  -- Enable Private Network: #{enable_private_network}"
          @logger.info "  -- Hostname: #{hostname}"
          @logger.info "  -- Label: #{label}"
          @logger.info "  -- SSH Key Name: #{ssh_key_name}"

          attributes = {
            region: region,
            os: os,
            plan: plan,
            hostname: hostname,
            label: label,
            snapshot: snapshot,
            enable_ipv6: enable_ipv6,
            enable_private_network: enable_private_network,
            ssh_key_name: ssh_key_name
          }

          @machine.id = @client.create_server(attributes)

          env[:ui].info 'Waiting for subcription to become active...'
          @client.wait_to_activate(@machine.id)

          env[:ui].info 'Waiting for server to start...'
          @client.wait_to_power_on(@machine.id)

          env[:ui].info 'Waiting for SSH to become active...'
          @client.wait_for_ssh(@machine)

          env[:ui].info 'Machine is booted and ready to use!'

          @app.call(env)
        end
      end
    end
  end
end
