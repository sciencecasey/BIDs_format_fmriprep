#rename proc for _beh files EEG_ANX (Houses/Bodies/Emoval)
#hoffman::/u/project/jfeusner/data/SCRIPTS_ALL_STUDIES/BIDS_Script/BEH_BIDs_eeganx.sh
#by Casey Jayne 08122019
#to use, go to script location, type sh BEH_BIDs_eeganx.sh and enter desired fields 
#original formats -> BIDs format examples::
#Houses_upgrade_4041-2_truncated.csv				->  sub-4041_task-houses_acq-2_beh.csv
#Participant 1_sub-4041_bodiesOT_NOheader.txt		->	sub-4041_task-houses_acq-2_ce-valence_physio.csv
#TO_Bodies_upgraded-4041-3_truncated.csv			->	sub-4041_task-bodies_acq-3_dir-TO_beh.csv
#Participant 1_sub-4041_bodiesOT_NOheader.txt		->	sub-4041_task-bodies_acq-3_ce-valence_dir-TO_physio.csv
#OT_Bodies_upgraded-4041-3_truncated.csv			->	sub-4041_task-bodies_acq-3_dir-OT_beh.csv
#Participant 1_sub-4041_somatomap_NOheader.txt		->	sub-4041_task-somatomap_acq-4_ce-valence_physio.csv


set -e

#enter information
echo -n "Enter the group level directory with the files to change names :"
read sourcedir

echo -n "Enter the group level directory for the raw file outputs :"
read rawdir

echo -n "Enter the subject ID #s (can be more than one eg 50132 50142) :"
read subjects

echo "Toplevel Source Directory is ${sourcedir}"
echo "Toplevel Raw Directory is ${rawdir}"
echo "Subjects to change include ${subjects}"

for subj in $subjects; do
	echo "Processing subject $subj"
	
	mkdir -p ${rawdir}/sub-${subj}/beh
	
	#copy subject files to subject raw folder
	cd $sourcedir/sub-${subj}/beh
	for files in *${subj}*truncated*.csv; do
	  cp $files ${rawdir}/sub-${subj}/beh;
	done
	for files in *NOheader*.txt; do 
	  cp "$files" ${rawdir}/sub-${subj}/beh  #there are spaces in the name so files must be contained within quotations
	done
	
	cd $rawdir/sub-${subj}/beh

	
	#change names of houses files
	housefiles=$(ls -1 *Houses*.csv | wc -l)
	for ((i=1;i<=$housefiles;i++)); do
		house=$(ls *House*)
		temphouse=$(ls -1 $house | sed '1q;d')
		temphouseext="${temphouse##*.}"
		tempacq=$(echo $temphouse | awk -F '[-]' '{print $3}')
		acq=$(echo $tempacq | awk -F '[_]' '{print $1}')
		mv -n $temphouse sub-${subj}_task-houses_acq-${acq}_beh.${temphouseext}
		echo "$temphouse changed to sub-${subj}_task-houses_acq-${acq}_beh.${temphouseext}"
	done
	
	#change names of bodies files
	bodyfiles=$(ls -1 *Bodies*.csv | wc -l)
	for ((i=1;i<=bodyfiles;i++)); do
		body=$(ls *Bod*)
		tempbody=$(ls -1 $body | sed '1q;d')
		tempbodyext="${tempbody##*.}"
		tempacq=$(echo $tempbody | awk -F '[-]' '{print $3}')
		acq=$(echo $tempacq | awk -F '[_]' '{print $1}')
		dr=$(echo $tempbody | awk -F '[_]' '{print $1}')
		mv -n $tempbody sub-${subj}_task-bodies_acq-${acq}_dr-${dr}_beh.csv
		echo "$tempbody changed to sub-${subj}_task-bodies_acq-${acq}_dir-${dr}_beh.csv"
	done
	
	
	#change names of emoval files
	##first remove spaces so that names can be captured
	for i in *header*; do name=$(echo $i | awk '{print $2}'); mv "$i" "$name"; done
	#for i in *header*; do name=$(echo $i | awk -F '[_]' '{print $2}'); mv "$i" "$name"; done
	emofiles=$(ls -1 *NOheader.txt | wc -l)
	for ((i=1;i<="${emofiles}";i++)); do
		emo=$(ls -1 *header*)
		tempemo=$(echo "$emo" | sed '1q;d')
		tempemoext="${tempemo##*.}"
		tempacq=$(echo "$tempemo" | awk -F '[-]' '{print $3}')
		acq=$(echo "$tempacq" | awk -F '[_]' '{print $1}')
		temptask=$(echo "$tempemo" | awk -F '[_]' '{print $3}')
		task=$(echo "$temptask" | awk -F '[-]' '{print $1}')
		if [[ "$task" = "bodies"* ]]; 
			then 
			dir=$(echo "${task: -2}");
			mv -n "$tempemo" "sub-${subj}_task-bodies_acq-${acq}_dir-${dir}_ce-valence_physio.${tempemo##*.}"
			echo "${tempemo} changed to sub-${subj}_task-bodies_acq-${acq}_dir-${dir}_ce-valence_physio.${tempemo##*.}"
		else
			mv -n "$tempemo" "sub-${subj}_task-${task}_acq-${acq}_ce-valence_physio.${tempemo##*.}"
			echo "${tempemo} changed to sub-${subj}_task-${task}_acq-${acq}_ce-valence_physio.${tempemo##*.}"
		fi
	done
	
	#add the acq and dir to emofiles
	
done