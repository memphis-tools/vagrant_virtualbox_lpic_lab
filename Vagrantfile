# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"

# -----------------------------------------------------------------------------
# Load .env
raise ".env is missing!" unless File.exist?(".env")
File.readlines(".env").each do |line|
  line = line.strip
  next if line.empty? || line.start_with?("#")
  key, value = line.split("=", 2)
  ENV[key] = value
end

# -----------------------------------------------------------------------------
# Load machines.yml
raise "vars/machines.yml is missing!" unless File.exist?("vars/machines.yml")
machines_config = YAML.load_file("vars/machines.yml")
defaults = machines_config.fetch("defaults", {})
machines  = machines_config.fetch("machines", {})

# -----------------------------------------------------------------------------
# Load common variables
raise "vars/vars.yml is missing!" unless File.exist?("vars/vars.yml")
vars = YAML.load_file("vars/vars.yml")

# -----------------------------------------------------------------------------
# Helpers
def create_disk(vb, disk_file, size_mb, port)
  unless File.exist?(disk_file)
    vb.customize [
      "createhd",
      "--filename", disk_file,
      "--size", size_mb
    ]
  end

  vb.customize [
    "storageattach", :id,
    "--storagectl", "SATA Controller",
    "--port", port,
    "--device", 0,
    "--type", "hdd",
    "--medium", disk_file
  ]
end

# -----------------------------------------------------------------------------
# Common provisioning variables
provision_vars = {
  "DNS_MANAGER_USER_NAME"     => ENV["DNS_MANAGER_USER_NAME"],
  "DNS_MANAGER_USER_PASSWORD" => ENV["DNS_MANAGER_USER_PASSWORD"],
  "LUKS_PASSPHRASE"           => ENV["LUKS_PASSPHRASE"],
  "NAS_APACHE_USER_NAME" => ENV["NAS_APACHE_USER_NAME"],
  "NAS_APACHE_GROUP_NAME" => ENV["NAS_APACHE_GROUP_NAME"],
  "NAS_TOMCAT_USER_NAME" => ENV["NAS_TOMCAT_USER_NAME"],
  "NAS_TOMCAT_GROUP_NAME" => ENV["NAS_TOMCAT_GROUP_NAME"],
  "NAS_KDC_USER_NAME" => ENV["NAS_KDC_USER_NAME"],
  "NAS_KDC_GROUP_NAME" => ENV["NAS_KDC_GROUP_NAME"],
  "VAGRANT_TOMCAT_KEYSTORE_PASSWORD" => ENV["VAGRANT_TOMCAT_KEYSTORE_PASSWORD"],
  "DEVOPS_GROUP_NAME" => ENV["DEVOPS_GROUP_NAME"],
  "DEVOPS_TOMCAT_USER_NAME" => ENV["DEVOPS_TOMCAT_USER_NAME"],
  "APACHE_PASSWORD_ACCESS" => ENV["APACHE_PASSWORD_ACCESS"],
  "LUKS_PASSPHRASE" => ENV["LUKS_PASSPHRASE"]
}

# Ansible extra var example
ansible_extra_vars = {
  dns_manager_user_name: ENV["DNS_MANAGER_USER_NAME"],
  nas_apache_user_name: ENV["NAS_APACHE_USER_NAME"],
}

# -----------------------------------------------------------------------------
# Vagrant
Vagrant.configure("2") do |config|

  machines.each do |name, machine|
    # -------------------------------------------------------------------------
    # Machine configuration
    box = defaults.fetch("box")
    hostname = machine.fetch("hostname", name)
    ips = machine.fetch("ips")
    memory = machine.fetch("memory_mb")
    primary_disk_size = machine.fetch(
      "primary_disk_size",
      defaults.fetch("primary_disk_size")
    )
    extra_disks = machine.fetch("extra_disks", [])

    # -------------------------------------------------------------------------
    # Resolve ${VARIABLE} from ENV
    box = box.gsub(/\$\{([^}]+)\}/) do
      ENV.fetch($1) {
        raise "Environment variable #{$1} is not defined"
      }
    end

    # -------------------------------------------------------------------------
    # VM
    config.vm.define hostname do |vm|
      vm.vm.box = box
      vm.vm.hostname = hostname
      vm.vm.provider :virtualbox
      # Primary disk
      vm.vm.disk(
        :disk,
        size: primary_disk_size,
        primary: true
      )
      # -----------------------------------------------------------------------
      # Network
      ips.each do |ip|
        vm.vm.network(
          "public_network",
          bridge: vars["network_interface"],
          ip: ip
        )
      end
      # -----------------------------------------------------------------------
      # Templates
      template_path = "./templates/#{hostname}"
      if Dir.exist?(template_path)
        vm.vm.synced_folder(
          template_path,
          "/vagrant_templates",
          type: "rsync"
        )
      end

      # -----------------------------------------------------------------------
      # VirtualBox
      vm.vm.provider "virtualbox" do |vb|
        vb.name   = hostname
        vb.memory = memory
        vb.cpus   = vars["cpus"]
        # Extra disks
        extra_disks.each do |disk|
          disk_path = File.join(
            vars["extra_disks_folder_path"],
            disk.fetch("filename")
          )
          create_disk(
            vb,
            disk_path,
            disk.fetch("size_mb"),
            disk.fetch("port")
          )
        end
      end

      # -----------------------------------------------------------------------
      # Bootstrap
      vm.vm.provision "shell",
        inline: <<-SHELL
          export DEBIAN_FRONTEND=noninteractive
          apt-get update
          apt-get install -y \
            python3 \
            python3-apt
          apt-get clean
        SHELL

      # -----------------------------------------------------------------------
      # Host-specific shell provisioning
      provision_script = "scripts/provision_#{hostname}.sh"

      unless File.exist?(provision_script)
        raise "Provisioning script is missing: #{provision_script}"
      end
      vm.vm.provision "shell",
        path: provision_script,
        env: provision_vars.merge(
          "HOSTNAME" => hostname
        )

      # -----------------------------------------------------------------------
      # Ansible
      # Other syntax example, for custom provision label: vm.vm.provision "execute_specific_role", type: "ansible" do |ansible|
      vm.vm.provision "ansible" do |ansible|
        ansible.playbook = "ansible/site.yml"
        ansible.inventory_path = "ansible/inventory.ini"
        ansible.limit = hostname
        ansible.tags = "install"
        ansible.vault_password_file = "ansible/.ansible.secret"
        ansible.extra_vars = ansible_extra_vars
      end
    end
  end
end
