#!/bin/bash -l

#$ -o database_checker.out
#$ -e database_checker.err
#$ -N database_checker
#$ -cwd
#$ -q short.q

#
# Description: Script checks for all databases used by QuAISAR pipeline and sets up any missing ones
#
# Usage ./database_checker.sh -path_to_database_folder [-i]
#	optional -i is for chencking AND installing, otherwise script just checks for existence..no downloading
#
# Modules required: None
#
# v1.0.1 (05/08/2020)
#
# Created by Nick Vlachos (nvx4@cdc.gov)
#

do_download="false"
# Checks for proper argumentation
if [[ $# -eq 0 ]]; then
	echo "No argument supplied to $0, exiting"
	exit 113
elif [[ "${1}" = "-h" ]]; then
	echo "Usage ./database_checker.sh -path_to_config_file [-i]"
	echo "-i is too install databases, otherwise script just checks for existence"
	exit 0
elif [[ ! -d "${1}" ]]; then
	echo "No folder exists as ${1}...exiting"
	exit 113
else
	path_to_DBs="${1}"
fi

if [[ "${2}" == "-i" ]]; then
	do_download="true"
fi

# Shows where databases should be (installed)
echo "${path_to_DBs}"
missing_DBS=()

# Check for parent directory
if [[ ! -d ${path_to_DBs} ]]; then
	mkdir -p ${path_to_DBs}
fi

# # # # Check for BUSCO
busco_taxa=(bacteria_odb10.2019-06-26 alteromonadales_odb10.2019-04-24 bacillales_odb10.2019-04-24 bacilli_odb10.2019-04-24 bacteroidetes_odb10.2019-04-24 betaproteobacteria_odb10.2019-04-24 burkholderiales_odb10.2019-04-24 campylobacterales_odb10.2019-04-24 clostridiales_odb10.2019-04-24 clostridia_odb10.2019-04-24 corynebacteriales_odb10.2019-04-24 enterobacterales_odb10.2019-04-24 epsilonproteobacteria_odb10.2019-04-24 firmicutes_odb10.2019-04-24 flavobacteriales_odb10.2019-04-24  flavobacteriia_odb10.2019-04-24 gammaproteobacteria_odb10.2019-04-24 lactobacillales_odb10.2019-04-24 neisseriales_odb10.2019-04-24 proteobacteria_odb10.2019-04-24 pseudomonadales_odb10.2019-04-24 xanthomonadales_odb10.2019-04-24 actinobacteria_class_odb10.2019-04-24 )

#echo "${#busco_taxa[@]}"

for odb_info in "${busco_taxa[@]}"; do
	# Check for top level bacteria database
	#echo ${odb_info}
	taxa=$(echo "$odb_info" | cut -d'_' -f1)
	db_date=$(echo "$odb_info" | cut -d'.' -f2)
	if [[ ! -d "${path_to_DBs}/BUSCO/${taxa}_odb10" ]]; then
		if [[ "${do_download}" = "true" ]]; then
			if [[ ! -d "${path_to_DBs}/BUSCO" ]]; then
				mkdir "${path_to_DBs}/BUSCO"
			fi
			cd "${path_to_DBs}/BUSCO"
			if [[ "${taxa}" == "actinobacteria" ]]; then
				taxa="actinobacteria_class"
			fi
			echo "Downloading latest BUSCO database for ${taxa} (wget http://busco-data.ezlab.org/v4/data/lineages/${taxa}_odb10.${db_date}.tar.gz)"
			wget "http://busco-data.ezlab.org/v4/data/lineages/${taxa}_odb10.${db_date}.tar.gz"
			# Dont know how to handle this one outlier (only one to specify a level in the filename) - ALl OUR bugs are in class Actinobacteria too
		else
			echo "Missing latest BUSCO database for ${taxa}"
			missing_DBS=("${missing_DBS[@]}" "BUSCO-${taxa}")
		fi
	else
		echo "BUSCO has latest ${taxa}_odb10 as of 3/15/2020"
	fi
done
find ${path_to_DBs}/BUSCO/ -name '*.gz' -exec tar xzf {} \;
mv ${path_to_DBs}/BUSCO/actinobacteria_class_odb10 ${path_to_DBs}/BUSCO/actinobacteria_odb10
find ${path_to_DBs}/BUSCO/ -name '*.gz' -exec rm {} \;

# All other databases will need to be hosted somehwere before being able to be checked/updated. Currently they are included in the Docker image

# Test index 0 is filename output, 1 is MEGA link, 2 is onedrive link, 3 is drive link
link_index=3
# Lists of links to test for downloading (MEGA OneDrive Google)
bbtools_links=("bbtools.simg" "https://mega.nz/file/0r5UCYIR#zn3LHj7RHKAMR-VkDGSc-5lUmWaE12A3jBPQOCJaZOk" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21106&authkey=AHXpg4F2NHk28Vw" "https://drive.google.com/uc?export=download&id=1QCvz1LRidSmeXhzMrfm7GtEDff4ik3zs")
blast_links=("blast-2.9.0-docker.img" "https://mega.nz/file/gyhCVIQR#1n-m6DEI1LA6HOiEE40i9x3fv5iXYFZsWT9sKfsNs_M" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21111&authkey=ADVSQ-oAmV3VAJk" "https://drive.google.com/uc?export=download&id=1-Ic9CxvcR4ubNsJX6k2XubWKhFXS_GVc")
bowtie2_links=("bowtie2-2.2.9-biocontainers" "https://mega.nz/file/92hgXAQJ#XThfqohBWcpD3kRzgUv4RjscDnmS2Xl5lNtBHVnvNuw" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21113&authkey=AKpz8agXXcDjON0" "https://drive.google.com/uc?export=download&id=1rQncOI9oqQKRDFLvxJFrZSZh2We5WA_S")
cSSTAR_links=("csstar.simg" "https://mega.nz/file/12wkUSDB#huoDBxj6keneY9h0hehwBWPoZ_n5zTpOiELePL0szFs" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21117&authkey=AFzS-KUAFnQdSnU" "https://drive.google.com/uc?export=download&id=1b--ivEqsFdnPPB85Ds340J8Pu3BzSRoI")
entrez_links=("entrez_taxon.simg" "https://mega.nz/file/gy4RQQrY#JZWvV4-PbeMfOJjnRj6qjZ9jzkXZGFgLbURGPyQu42E" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21116&authkey=AGPABuxJPVYnJgA" "https://drive.google.com/uc?export=download&id=1Earz_6jrnTkIjV_oLTmnuY9P2NSMY614")
GAMA_links=("GAMA_quaisar.simg" "https://mega.nz/file/R3wmFQJb#yY3gQ1tFvIPxeKSEUydezyTh5fnVANBOA0LV7dmHHFk" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21107&authkey=AJKsAgfit5oEhCs" "https://drive.google.com/uc?export=download&id=1kzEloxzGIVPaV-1PngLt9FAn2dpGeguj")
gottcha_links=("gottcha.simg" "https://mega.nz/file/EyxEDCrC#Q2kkGwzDB0HdLL3q9U2uRf7gd1orHbFK_voCCTIBErc" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21108&authkey=AMIQfW5e3Yi-sH4" "https://drive.google.com/uc?export=download&id=1SnGgM60JUdhe0y5EoZprcPpG326pG79j")
plasmidFinder_links=("plasmidFinder_with_DB.simg" "https://mega.nz/file/kugiyYZK#um_iss6jLcs4P3_qL7M5EYHICcyYJz0cHyCmUaR4ovg" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21112&authkey=AHORh2N541BayFw" "https://drive.google.com/uc?export=download&id=1wZAzkiTD2rLxkgDon16rZErMjg986yit")
QUAST_links=("QUAST5.simg" "https://mega.nz/file/8rw0kQxL#1p-zUtABJb9sLmwkeAojSMmFJ8oRkZaOtVinT0Jo1NY" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21110&authkey=AM_c7ih_fP4JxrE" "https://drive.google.com/uc?export=download&id=1JhxjA2xt4dsjpO96egc7Iyz9wOEbnXXF")
srst2_links=("srst2.simg" "https://mega.nz/file/Y6hg3CCb#6lLqih6Dv5AYOs0hfJiBZD7BkxR8k4wwhTEkJKKmwls" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21109&authkey=AINwP6LEwO1bDgI" "https://drive.google.com/uc?export=download&id=1Kobw285kXNy7yxHHxhRxYY2PjjEmVtYK")
ANI_links=("REFSEQ_20200305.msh.gz" "https://mega.nz/file/puxixKaT#tUbaDQ1YV2TpxgpHyhlOI1ryTfaBP7RhBgD9_Psimhc" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21114&authkey=AB5T8jQOePfzxSg" "https://drive.google.com/uc?export=download&id=161jVEG-AV38qNxIcNHSM-T0hn1RoyIv0")
pubmlst_links=("pubmlsts.tar.gz" "https://mega.nz/file/M2h2mYZT#SJ4ohNn60WsdHovWxNKp6sQTtcA5tfk6WY-iECA9zEw" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21115&authkey=AGCIPp4ZdSRdGHc" "https://drive.google.com/uc?export=download&id=1DoqUliXXJSWEsZFCoGSnakzjySbywgx2")
sstar_links=("sstar.tar.gz" "https://mega.nz/file/Z7gEWArZ#MfOJld0JsjtYMXI7vzkr-N2f8oKCpTgM1zYobL6fX3E" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21122&authkey=AG1SomRvYC1gMxM" "https://drive.google.com/uc?export=download&id=1WXqL4bdT-eO_zyIk-csLPdZatj-JTyPM")
adapters_links=("adapters.fasta" "https://mega.nz/file/AqwyXA7S#Ao8VR1JELCeos6ISbDE3e1r7LNXSplfA5pc5m8ICb5w" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21121&authkey=AO1Xn0MaUceaHVw" "https://drive.google.com/uc?export=download&id=1Ec_tQoL-fsMYJArP92-1g--SHoEiEhIY")
MMBbugs_links=("MMB_Bugs.txt" "https://mega.nz/file/ArxWwCbD#gtCCSQAKZCKB_euY2tryANlq_R4hZkN_HdZhEfPjo1k" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21128&authkey=ADtwVO9h0vMIU4M" "https://drive.google.com/uc?export=download&id=1RYL8timv8CLhvIyXgRKiTUWxwerrvEcf")
phiX_links=("phiX.fasta" "https://mega.nz/file/drg00AIK#rH95tA3qTuE7SDGvcUIDuGfENm4un4MPYyI5G1tmCB4" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21119&authkey=AEYBttLLp5mkKM0" "https://drive.google.com/uc?export=download&id=111clfbuw7sjUoQN0Uw8NVhZINJAf739G")
taxes_links=("taxes.csv" "https://mega.nz/file/1v5UFIgY#K5pFtVNLrKP5kB6BH5S_f_nqwVNvLRhnW7xkd8dSteo" "https://onedrive.live.com/download?cid=89BB0F0D841B2A3B&resid=89BB0F0D841B2A3B%21127&authkey=AOl2_e_i2ubfrt4" "https://drive.google.com/uc?export=download&id=1-lnexzeEquhcvJT-UE3wx8YD804rr5ts")

wget_options=""
if [[ ${link_index} -eq 1 ]]; then
	echo "Unknown how to process"
elif [[ ${link_index} -ge 2 ]]; then
	wget_options="--no-check-certificate"
elif [[ ${link_index} -eq 3 ]]; then
	echo "None needed for google drive"
fi

# star (6 Mbs)
if [[ ! -d "${path_to_DBs}/star" ]]; then
	#cp -r /container_DBs/star ${path_to_DBs}
	if [[ "${do_download}" = "true" ]]; then
		echo "Copying latest NAR-AR database"
		cd ${path_to_DBs}
		wget "${wget_options}" -O "${sstar_links[0]}" "${sstar_links[${link_index}]}"
		tar -zxvf sstar.tar.gz
		mv ${path_to_DBs}/raid5/QuAISAR_databases/star ${path_to_DBs}
		rm -r ${path_to_DBs}/raid5
		rm sstar.tar.gz
	else
		echo "Missing latest NAR-AR database"
		missing_DBS=("${missing_DBS[@]}" "NAR-AR")
	fi
else
	echo "NAR-AR database installed"
fi

if [[ ! -f "${path_to_DBs}/MMB_Bugs.txt" ]]; then
	#cp -r /container_DBs/MMB_Bugs.txt ${path_to_DBs}
	if [[ "${do_download}" = "true" ]]; then
		echo "Copying MMB_bugs"
		cd ${path_to_DBs}
		wget "${wget_options}" -O "${MMBbugs_links[0]}" "${MMBbugs_links[${link_index}]}"
	else
		echo "Missing MMB_Bugs"
		missing_DBS=("${missing_DBS[@]}" "MMB_Bugs")
	fi
else
	echo "MMB_Bugs installed"
fi

if [[ ! -f "${path_to_DBs}/taxes.csv" ]]; then
	#cp -r /container_DBs/taxes.csv ${path_to_DBs}
	if [[ "${do_download}" = "true" ]]; then
		echo "Copying taxes"
		cd ${path_to_DBs}
		wget "${wget_options}" -O "${taxes_links[0]}" "${taxes_links[${link_index}]}"
	else
		echo "Missing taxes"
		missing_DBS=("${missing_DBS[@]}" "taxes")
	fi
else
	echo "taxes installed"
fi

if [[ ! -f "${path_to_DBs}/phiX.fasta" ]]; then
	#cp -r /container_DBs/phiX.fasta ${path_to_DBs}
	if [[ "${do_download}" = "true" ]]; then
		echo "Copying phiX.fasta"
		cd ${path_to_DBs}
		wget "${wget_options}" -O "${phiX_links[0]}" "${phiX_links[${link_index}]}"
	else
		echo "Missing phiX"
		missing_DBS=("${missing_DBS[@]}" "phiX")
	fi
else
	echo "phiX installed"
fi

if [[ ! -f "${path_to_DBs}/adapters.fasta" ]]; then
	#cp -r /container_DBs/adapters.fasta ${path_to_DBs}
	if [[ "${do_download}" = "true" ]]; then
		echo "Copying adapters.fasta"
		cd ${path_to_DBs}
		wget "${wget_options}" -O "${adapters_links[0]}" "${adapters_links[${link_index}]}"
	else
		echo "Missing adapters"
		missing_DBS=("${missing_DBS[@]}" "adapters")
	fi
else
	echo "adapters installed"
fi

if [[ ! -d "${path_to_DBs}/ANI" ]]; then
	#cp -r /container_DBs/ANI ${path_to_DBs}
	if [[ "${do_download}" = "true" ]]; then
		echo "Copying latest REFSEQ sketch database (ANI)"
		mkdir ${path_to_DBs}/ANI
		cd ${path_to_DBs}/ANI
		if [[ ${link_index} -eq 3 ]]; then
			query=`curl -k -c ./cookie.txt -s -L "${ANI_links[3]}" \
			| perl -nE'say/uc-download-link.*? href="(.*?)\">/' \
			| sed -e 's/amp;//g' | sed -n 2p`
			url="https://drive.google.com$query"
			curl -k -b ./cookie.txt -L -o ${ANI_links[0]} $url
			rm ./cookie.txt
		else
			wget "${wget_options}" -O "${ANI_links[0]}" "${ANI_links[${link_index}]}"
		fi
		gunzip *.gz
	else
		echo "Missing latest REFSEQ sketch database (ANI)"
		missing_DBS=("${missing_DBS[@]}" "REFSEQ-ANI")
	fi
else
	echo "ANI REFSEQ sketch database installed"
fi

if [[ ! -d "${path_to_DBs}/pubmlsts" ]]; then
	#cp -r /container_DBs/pubmlsts ${path_to_DBs}
	if [[ "${do_download}" = "true" ]]; then
		echo "Copying pubMLST"
		cd ${path_to_DBs}
		wget {wget_options} -O "${pubmlst_links[0]}" "${pubmlst_links[${link_index}]}"
		tar -zxvf pubmlsts.tar.gz
		mv pubmlsts_2 pubmlsts
		rm pubmlsts.tar.gz
	else
		echo "Missing pubMLST"
		missing_DBS=("${missing_DBS[@]}" "pubMLST")
	fi
else
	echo "pubMLST installed"
fi

singularities=(bbtools.simg+${bbtools_links[${link_index}]}+76 blast-2.9.0-docker.img+${blast_links[${link_index}]}+94 bowtie2-2.2.9-biocontainers.simg+${bowtie2_links[${link_index}]}+364 cSSTAR.simg+${cSSTAR_links[${link_index}]}+688 entrez_taxon.simg+${entrez_links[${link_index}]}+239 GAMA_quaisar.simg+${GAMA_links[${link_index}]}+242 gottcha.simg+${gottcha_links[${link_index}]}+208 plasmidFinder_with_DB.simg+${plasmidFinder_links[${link_index}]}+805 QUAST5.simg+${QUAST_links[${link_index}]}+345 srst2.simg+${srst2_links[${link_index}]}+262)

for simage_info in "${singularities[@]}"; do
	# custom singularity images (3.6GBs)
	simage=$(echo "${simage_info}" | cut -d'+' -f1)
	url_link=$(echo "${simage_info}" | cut -d'+' -f2)
	size=$(echo "${simage_info}" | cut -d'+' -f3)
	echo -e "${simage}\n${url_link}\n${size}\n"

	if [[ ! -f "${path_to_DBs}/singularities/${simage}" ]]; then
		#cp -r /container_DBs/custom_singularities ${path_to_DBs}
		if [[ "${do_download}" = "true" ]]; then
			if [[ ! -d "${path_to_DBs}/singularities" ]]; then
				mkdir "${path_to_DBs}/singularities"
				cd "${path_to_DBs}/singularities"
			fi
			echo "Copying custom singularity image ${simage}"
			if [[ ${size} -ge 100 ]] && [[ ${link_index} -eq 3 ]]; then
				echo "Too big, special command"
				#wget --save-cookies cookies.txt "${url_link}" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1/p' > confirm.txt
		 		#wget --load-cookies cookies.txt -O ${simage} '${url_link}'&'confirm='$(<confirm.txt)

				query=`curl -k -c ./cookie.txt -s -L "${url_link}" \
				| perl -nE'say/uc-download-link.*? href="(.*?)\">/' \
				| sed -e 's/amp;//g' | sed -n 2p`
				url="https://drive.google.com$query"
				curl -k -b ./cookie.txt -L -o ${simage} $url
				rm ./cookie.txt
			else
				echo "Normal command -just testing"
				wget "${wget_options}" -O ${simage} "${url_link}"
			fi
		else
			echo "Missing custom singularity image ${simage}"
			missing_DBS=("${missing_DBS[@]}" "singularities-${simage}")
		fi
	else
		echo "custom singularity image ${simage} installed"
	fi
done

# Check to see if kraken mini database is installed
if [[ ! -d "${path_to_DBs}/kraken" ]]; then
	if [[ "${do_download}" = "true" ]]; then
		mkdir "${path_to_DBs}/kraken"
		cd "${path_to_DBs}/kraken"
		echo "Downloading latest (mini)kraken database (wget https://ccb.jhu.edu/software/kraken/dl/minikraken_20171019_4GB.tgz)"
		wget "https://ccb.jhu.edu/software/kraken/dl/minikraken_20171019_4GB.tgz"
		if [[ ! -f "minikraken_20171019_4GB.tgz" ]]; then
			curl -k -O "https://ccb.jhu.edu/software/kraken/dl/minikraken_20171019_4GB.tgz"
		fi
		tar xzf minikraken_20171019_4GB.tgz
		rm minikraken_20171019_4GB.tgz
	else
		echo "Missing latest kraken database"
		missing_DBS=("${missing_DBS[@]}" "kraken")
	fi
else
	echo "kraken database is installed"
fi

##### Currently down.....and has been a while
# Check to see if gottcha database is installed
if [[ ! -d "${path_to_DBs}/gottcha" ]]; then
	if [[ "${do_download}" = "true" ]]; then
		cd "${path_to_DBs}"
		# Original LANL hosted address that has been down a good while
	 	#wget -P "${path_to_DBs}/gottcha" "https://edge-dl.lanl.gov/gottcha/GOTTCHA_database_v20150825/GOTTCHA_BACTERIA_c4937_k24_u30_xHUMAN3x.species.tar.gz"
		# Temporary mirror until original is fixed
		echo "Downloading latest gottcha database (wget https://zenodo.org/record/819341/files/gottcha_bac_arc_v1.tar.gz)"
		wget "https://zenodo.org/record/819341/files/gottcha_bac_arc_v1.tar.gz"
		tar xzf gottcha_bac_arc_v1.tar.gz
		rm gottcha_bac_arc_v1.tar.gz
		mv gottcha/gottcha_db ./
		rm -r gottcha
		mv gottcha_db gottcha
		rm gottcha.dbprofile.out
		# Need to find sa place to host genus_Lookup.tar.gz
	else
		echo "Missing gottcha database"
		missing_DBS=("${missing_DBS[@]}" "gottcha")
	fi
else
	echo "gottcha database installed"
fi

ls ${path_to_DBs}
#chmod -Rx ${path_to_DBs}/*

echo "There are ${#missing_DBS[@]} missing databases (${missing_DBS[@]})"
