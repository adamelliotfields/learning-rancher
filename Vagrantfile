# frozen_string_literal: true

require 'yaml'

yaml = YAML.load_file(File.join(File.dirname(__FILE__), 'vagrant', 'config.yml'))

Vagrant.configure(yaml['config_version']) do |config|
  config.vm.box = yaml['box']
  config.vm.box_check_update = yaml['box_check_update']

  yaml['files'].each do |file|
    config.vm.provision(
      'file',
      source: File.join(File.dirname(__FILE__), file['source']),
      destination: file['destination']
    )
  end

  yaml['provisioners'].each do |provisioner|
    config.vm.provision(
      'shell',
      path: File.join(File.dirname(__FILE__), provisioner['path'])
    )
  end

  yaml['synced_folders'].each do |folder|
    config.vm.synced_folder(
      folder['hostpath'],
      folder['guestpath'],
      folder['options']
    )
  end

  yaml['vms'].each_with_index do |vm, i|
    config.vm.define(vm['name'], primary: i.zero?) do |v|
      v.vm.hostname = vm['name']

      vm['networks'].each do |network|
        v.vm.network(network.keys[0], network[network.keys[0]])
      end

      v.vm.provider(yaml['provider']) do |vb|
        vb.name = vm['name']
        vb.cpus = vm['cpus']
        vb.memory = vm['memory']
        vb.linked_clone = vm['linked_clone']

        vm['customizations'].each do |customization|
          vb.customize(['modifyvm', :id, customization.to_a].flatten)
        end
      end
    end
  end
end
