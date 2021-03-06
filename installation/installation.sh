#! /usr/bin/env bash
#!/bin/sh -l


#
# Description: Script to prepare environment to be able to run quaisar pipeline
#
# Usage: ./quaisar_installation.sh OS_Type location_for_scriopts location_to_download_databases_to location_of_where_to_store_output
#
# Output location: No output created
#
# Modules required: None
#
# v1.0.2 (05/18/2020)
#
# Created by Nick Vlachos (nvx4@cdc.gov)
#

#finds where script is it, so it properly reference directories during install
install_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd | rev | cut -d'/' -f2- | rev)"

echo "Current directory is ${install_script_dir}"

#  Function to print out help blurb
show_help () {
	echo "Usage: ./installation.sh -t OS-Type -i script_installation_location -d database_installation_location -w Working_directory_of_output_from_runs"
}

# Parse command line options
options_found=0
while getopts ":h?t:i:d:w:" option; do
	options_found=$(( options_found + 1 ))
	case "${option}" in
		\?)
			echo "Invalid option found: ${OPTARG}"
      show_help
      exit 0
      ;;
		t)
			echo "Option -t triggered, argument = ${OPTARG}"
			OS_type=${OPTARG}
      ;;
    i)
  		echo "Option -i triggered, argument = ${OPTARG}"
  		installation_location=${OPTARG}
      ;;
		d)
			echo "Option -d triggered, argument = ${OPTARG}"
			databases=${OPTARG}
      ;;
    w)
      echo "Option -w triggered, argument = ${OPTARG}"
      working_directory=${OPTARG}
      ;;
		:)
			echo "Option -${OPTARG} requires as argument"
      ;;
		h)
			show_help
			exit 0
			;;
	esac
done

# Show help info for when no options are given
if [[ "${options_found}" -eq 0 ]]; then
	echo "No options found"
	show_help
	exit 1
elif [ -z "${OS_type}" ]; then
  echo "Empty OS_type supplied to supplied to installation.sh, exiting"
  exit 2
elif [ -z "${installation_location}" ]; then
	echo "Empty script location supplied to supplied to installation.sh, exiting"
	exit 3
elif [ -z "${databases}" ]; then
	echo "Empty database installation location supplied to installation.sh, exiting"
	exit 4
elif [ -z "${working_directory}" ]; then
  echo "Empty working directory for output supplied to installation.sh, exiting"
  exit 5
fi


echo -e "${OS_type}\n${installation_location}\n${databases}\n${working_directory}"

echo "Installing quaisar scripts to ${installation_location}"
if [[ ! -d ${installation_location} ]]; then
  echo "Creating ${installation_location}"
  mkdir -p ${installation_location}
fi

function test_go() {
  current_dir=$(pwd)
  echo "Testing Go!"
  echo -e "package main\n" > ${installation_location}/hello.go
  echo -e "import fmt\n" >> ${installation_location}/hello.go
  echo -e "func main() {\nfmt.Printf(\"hello, world\")\n}" >> ${installation_location}/hello.go
  go build ${installation_location}/hello.go
  cd ${installation_location}
  go_test_output=$(go hello)
  if [[ "${go_test_output}" = "hello, world" ]]; then
    echo "Go is installed correctly, proceed!"
  else
    echo "Go is not installed, halting"
    exit 99
  fi
  cd ${current_dir}
}

function test_singularity() {
  sing_version=$(singularity --version)
  if [[ "${sing_version}" = "singularity version"* ]]; then
    v3plus=$(echo "${sing_version}" | cut -d' ' -f3 | cut -d'.' -f1)
    echo "${v3plus}"
    if [[ "${v3plus}" -ge 3 ]]; then
      echo "Singularity installed and ready to go"
    else
      echo "Your singularity version is too old, please upgrade to version 3 (or remove old versions and change parameters) before trying again"
      exit
    fi
  else
    echo "You do not have singularity installed, either choose a supported operating system, or preinstall before trying to install QuAISAR"
    exit 101
  fi
}

echo "Checking for working directory of runs ${working_directory}"
if [[ ! -d ${working_directory} ]]; then
  echo "Creating ${working_directory}"
  mkdir -p ${working_directory}
fi

if [[ ${OS_type} -eq 1 ]] || [[ ${OS_type} -eq 2 ]]; then
  echo "Installing pre-dependencies"
  if [[ "${OS_type}" -eq 1 ]]; then
    sudo apt-get update && sudo apt-get install -y \
    build-essential \
    libssl-dev \
    uuid-dev \
    libgpgme11-dev \
    squashfs-tools \
    libseccomp-dev \
    wget \
    pkg-config \
    git \
    cryptsetup

  elif [[ ${OS_type} -eq 2 ]]; then
    echo "Completed installing pre dependencies"
  fi
  echo "Installing Go"
  curl -O https://storage.googleapis.com/golang/go1.14.2.linux-amd64.tar.gz --output ${installation_location}
  tar -C /usr/local -xvf go1.14.2.linux-amd64.tar.gz
  echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
  test_go
  echo "Installing Singularity"
  export VERSION=3.5.2 && # adjust this as necessary \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && \
    tar -C "${installation_location}" -xzf singularity-${VERSION}.tar.gz && \
    cd ${installation_location}/singularity
  ./mconfig && \
    make -c builddir && \
    sudo make -C builddir install.
  test_singularity
fi

#test_singularity

# Create primary config file
head -n25 ${install_script_dir}/installation/config_template.sh > ${installation_location}/new_config.sh
echo "output_dir=${working_directory}" >> ${installation_location}/new_config.sh
head -n27 ${install_script_dir}/installation/config_template.sh | tail -n1 >> ${installation_location}/new_config.sh
echo "src=${installation_location}" >> ${installation_location}/new_config.sh
head -n29 ${install_script_dir}/installation/config_template.sh | tail -n1 >> ${installation_location}/new_config.sh
echo "local_DBs=${databases}" >> ${installation_location}/new_config.sh
head -n31 ${install_script_dir}/installation/config_template.sh | tail -n1 >> ${installation_location}/new_config.sh
CPUs=$(nproc --all)
echo "procs=${CPUs}" >> ${installation_location}/new_config.sh
tail -n91 ${install_script_dir}/installation/config_template.sh >> ${installation_location}/new_config.sh

# Copy all scripts from this fodler to install location
cp ${install_script_dir}/scripts/* ${installation_location}
rm ${installation_location}/config.sh
mv ${installation_location}/new_config.sh ${installation_location}/config.sh
echo "${installation_location}"
chmod +x ${installation_location}/*.sh ${installation_location}/*.py


echo "Exiting prematurely to prevent constant installations"

# Install databases
#Create database folder
if [[ ! -d ${databases} ]]; then
  echo "Creating ${databases} for databases"
  mkdir -p "${databases}/BUSCO"
fi
echo "${install_script_dir}/scripts/database_checker.sh ${databases} -i"
${install_script_dir}/scripts/database_checker.sh ${databases} -i


#check if conda is installed already
conda_call_lines=$(conda list | wc -l)
if [[ "${conda_call_lines}" -gt 1 ]]; then
	:
else
	yes | ${install_script_dir}/installation/install_miniconda.sh
fi

home_dir=$(echo $HOME)
echo "prefix: ${home_dir}/miniconda3/envs/py36_biopython" >> ${install_script_dir}/installation/py36_biopython.yml

. "${home_dir}/.bashrc"

conda create --name py36_biopython python=3.6 biopython -y

echo -e "Installation complete. Before running the pipeline, open a new window or run the following:\n. ${home_dir}/.bashrc \n\n If you would like to view or edit parameters and settings for pipeline, please see ${installation_location}/config.sh"
