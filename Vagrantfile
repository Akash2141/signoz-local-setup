VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  
  # --- Common Settings ---
  config.vm.box = "ubuntu/jammy64"
  
  config.vm.provider "virtualbox" do |vb|
    vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
  end

  config.vm.define "signoz" do |signoz|
    signoz.vm.hostname = "signoz"
    # Static IP for easy access to the Signoz UI (http://192.168.56.5:8080)
    signoz.vm.network "private_network", ip: "192.168.56.5"
    signoz.vm.network "forwarded_port", guest: 8080, host: 8080
    signoz.vm.provider "virtualbox" do |vb|
      # Recommended resources for Signoz/ClickHouse
      vb.memory = "4096" 
      vb.cpus = "3"
    end
    
    signoz.vm.synced_folder "./signoz-setup", "/home/vagrant/signoz-setup"
    
    # --- PROVISIONING BLOCK: Install Docker Engine and Compose Plugin ---
    signoz.vm.provision "shell", inline: <<-SHELL
      # Update system and install prerequisite packages
      sudo apt-get update
      sudo apt-get install -y ca-certificates curl gnupg lsb-release

      # Add Docker's official GPG key
      sudo mkdir -p /etc/apt/keyrings
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg

      # Add the Docker repository to Apt sources
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

      # Install Docker Engine, containerd, and the Compose Plugin
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

      # Add the 'vagrant' user to the 'docker' group to run commands without sudo
      sudo usermod -aG docker vagrant

      # git clone https://github.com/SigNoz/signoz.git

      # docker compose -f signoz/deploy/docker/docker-compose.yaml -f ./signoz-setup/docker-compose.yaml up -d

      echo "--- Docker and Compose Installation Complete ---"
    SHELL
  end

end