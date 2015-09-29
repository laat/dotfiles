# Get latest container ID
alias dol="docker ps -l -q"

# Get container process
alias dops="docker ps"

# Get process included stop container
alias dopa="docker ps -a"

# Get images
alias doi="docker images"

# Get container IP
alias doip="docker inspect --format '{{ .NetworkSettings.IPAddress }}'"

# Run deamonized container, e.g., $dkd base /bin/echo hello
alias dokd="docker run -d -P"

# Run interactive container, e.g., $dki base /bin/bash
alias doki="docker run -i -t -P"

# Stop all containers
dostop() { docker stop $(docker ps -a -q); }

# Remove all containers
dorm() { docker rm $(docker ps -a -q); }

# Stop and Remove all containers
alias dormf='docker stop $(docker ps -a -q) && docker rm $(docker ps -a -q)'

# Remove all images
dori() { docker rmi $(docker images -q); }

# Show all alias related docker
doalias() { alias | grep 'docker' | sed "s/^\([^=]*\)=\(.*\)/\1 => \2/"| sed "s/['|\']//g" | sort; }
