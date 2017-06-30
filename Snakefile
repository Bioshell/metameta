version="1.1"

# Check for required parameters
if "samples" not in config:
	print("No samples defined on the configuration file")
elif "workdir" not in config:
	print("No working directory defined on the configuration file")
elif "dbdir" not in config:
	print("No database directory defined on the configuration file")
else:

	# Load default values (when they are not set on the configfile.yaml)
	include: "scripts/default.sm"

	# Set snakemake main workdir variable
	workdir: config["workdir"]

	onstart:
		import pprint, os
		# create dir for log on cluster mode (script breaks without it)
		shell("mkdir -p {config[workdir]}/clusterlog")
		print("")
		print("---------------------------------------------------------------------------------------")
		print("MetaMeta Pipeline v%s by Vitor C. Piro (vitorpiro@gmail.com, http://github.com/pirovc)" % version)
		print("---------------------------------------------------------------------------------------")
		print("Parameters:")
		for k,v in sorted(config.items()):
			print(" - " + k + ": ", end='')
			pprint.pprint(v)
		print("---------------------------------------------------------------------------------------")
		print("")
		
	def onend(msg, log):
		#Remove clusterlog folder (if exists and empty)
		shell('if [ -d "{config[workdir]}/clusterlog/" ]; then [ ! "$(ls -A {config[workdir]}/clusterlog/)" ] && rm -d {config[workdir]}/clusterlog/; fi')
		from datetime import datetime
		dtnow = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
		log_file = config["workdir"] + "/metameta_" + dtnow + ".log"
		shell("cp {log} {log_file}")
		print("")
		print("---------------------------------------------------------------------------------------")
		print(msg)
		print("Please check the main log file for more information:")
		print("\t" + log_file)
		print("Detailed output and execution time for each rule can be found at:")
		print("\t" + config["dbdir"] + "log/")
		print("\t" + config["workdir"] + "SAMPLE_NAME/log/")
		print("---------------------------------------------------------------------------------------")
		print("")
	
	onsuccess:
		onend("MetaMeta finished successfuly", log)

	onerror:
		onend("An error has occured.", log)
		
	############################################################################################## 
	include: "scripts/db.sm"
	include: "scripts/preproc.sm"
	include: "scripts/clean_files.sm"
	include: "scripts/clean_reads.sm"
	include: "scripts/metametamerge.sm"
	include: "scripts/krona.sm"
	include: "scripts/util.py"
	include: "tools/clark_db_custom.sm"
	include: "tools/dudes_db_custom.sm"
	include: "tools/kaiju_db_custom.sm"
	include: "tools/kraken_db_custom.sm"
	for t in config["tools"]:
		include: ("tools/"+t+".sm")
	############################################################################################## 

	rule all:
		input:
			clean_reads =  expand("{sample}/clean_reads.done", sample=config["samples"]),
			krona_html = expand("{sample}/metametamerge/{database}/final.metametamerge.profile.html", sample=config["samples"], database=config["databases"])
			
	############################################################################################## 
