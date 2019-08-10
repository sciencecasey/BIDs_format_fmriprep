#rename proc for _beh files VM-Pilot (Navon/Inverted/Emoval)
#by Casey Jayne 08072019
#original formats -> BIDs format examples::
#1_UpInvUpInv_useme-50192-1_truncated.csv	->  sub-50192_ses-1_task-invertedfaces_acq-1UpInvUpInv_beh.csv
#2_UpInvInvUp-50142-2_truncated.csv			->	sub-50142_ses-2_task-invertedfaces_acq-2UpInvInvUp_beh.csv
#50132_emovalence_1.csv						->	sub-50132_ses-1_task-emoval_physio.csv
#50132_emovalence_2.csv						->	sub-50132_ses-2_task-emoval_physio.csv
#Navon-50202-2_tuncated2.csv				->	sub-50202_ses-2_task-navon_beh.csv


set -e

#enter information
echo -n "Enter the group level directory with the files to change names"
read sourcedir

echo -n "Enter the group level directory for the raw file outputs"
read rawdir

echo -n "Enter the subject ID #s (can be more than one eg 50132 50142"
read subjects

echo "Toplevel Source Directory is ${sourdir}"
echo "Toplevel Raw Directory is ${rawdir}"
echo "Subjects to change include ${subjects}"

for subj in $subjects; do
	echo "Processing subject $subj"
	
	mkdir -p ${rawdir}/sub-${subj}/beh
	
	#copy subject files to subject raw folder
	cd $sourcedir
	for files in *${subj}*.csv; do
	  cp $files ${rawdir}/sub-${subj}/beh;
	done
	
	cd $rawdir/sub-${subj}/beh
	
	#change names of emoval files
	emofiles=$(ls -1 *emoval* | wc -l)
	for ((i=1;i<=${emofiles};i++)); do
		emo=$(ls *emoval*)
		tempemo=$(ls -1 $emo | sed '1q;d')
		tempemoext="${tempemo##*.}"
		ses=$(echo $tempemo | awk -F '[_]' '{print $3}')
		mv -n $tempemo sub-${subj}_ses-${ses}_task-emoval_physio.${tempemoext}
		echo "${tempemo} changed to sub-${subj}_ses-${ses}_task-emoval_physio.${tempemoext}"
	done
	
	#change names of navon files
	navonfiles=$(ls -1 *Navon* | wc -l)
	for ((i=1;i<=$navonfiles;i++)); do
		navon=$(ls *Navon*)
		tempnavon=$(ls -1 $navon | sed '1q;d')
		tempnavonext="${tempnavon##*.}"
		tempses=$(echo $tempnavon | awk -F '[-]' '{print $3}')
		ses=$(echo $tempses | awk -F '[_]' '{print $1}')
		mv -n $tempnavon sub-${subj}_ses-${ses}_task-navon_beh.${tempnavonext}
		echo "$tempnavon changed to sub-${subj}_ses-${ses}_task-navon_beh.${tempnavonext}"
	done
	
	#change names of inverted faces files
	invfiles=${(ls -1 *Up* | wc -l)
	for ((i=1;i<=invfiles;i++)); do
		inv=$(ls *Up*)
		tempinv=$(ls -1 $inv | sed '1q;d')
		tempinvext="${tempinvext##*.}"
		tempses=$(echo $tempinv | awk -F '[-]' '{print $3}')
		ses=$(echo $tempses | awk -F '[_]' '{print $1}')
		tempacq=$(echo $tempinv | awk -F '[-]' '{print $1}')
		acq=$(echo $tempacq | awk -F '[_]' '{print $1$2}')
		mv -n $tempinv sub-${subj}_ses-${ses}_task-invertedfaces_acq-${acq}_beh.csv
		echo "$tempinv changed to sub-${subj}_ses-${ses}_task-invertedfaces_acq-${acq}_beh.csv"
	done
done