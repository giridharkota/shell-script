# shell-script
# HP DP Media rotation script for ESL and MSL librarires
#!/usr/bin/ksh
# set -x
##
# This script will check offsite pools and eject tapes to library mail slots also findout Free tapes from media scrach media pool
#
## Input Data as per Customer
CUSTOMER="ABC"
MAIL_SLOTS="2"
FREE_POOL1="Free_Pool_Name"
EJECT_POOL1="Eject_Pool_Name"
LB_NAME="HP_DP Library_Name"
LB_EXCHANGER="/dev/rchgr/autoch7<HPDP exchanger name"
#
TMP_FREE_LIST="/tmp/z_free_list.txt"
TMP_EJECT="/tmp/z_eject_list1.txt"
TMP_EJECT1="/tmp/z_eject_list2.txt"
TMP_OUT_FILE="/tmp/z_final.txt"
#
echo '  ' > /tmp/z_free_list.txt
echo ' ' > /tmp/z_eject_list1.txt
echo '  ' > /tmp/z_final.txt
echo ' ' > /tmp/z_free_list.txt
##################### Free Pool List #######################
#
echo ' ' > $TMP_FREE_LIST
echo "$CUSTOMER" >> $TMP_FREE_LIST
echo "---------------------- ">> $TMP_FREE_LIST
echo " Scratch Tape List " >> $TMP_FREE_LIST
echo "---------------------- ">> $TMP_FREE_LIST
#
/opt/omni/bin/omnimm -list_pool $FREE_POOL1 |grep "                            " |  awk '{print $2}' >> $TMP_FREE_LIST
################# Eject Medias ############################
for M in $(/opt/omni/bin/omnimm -list_pool $EJECT_POOL1 |grep Yes | tail -$MAIL_SLOTS | awk '{print (substr($5,1,(length($5)-1)))}')
do
 /opt/omni/bin/omnimm -eject $LB_NAME $M > /tmp/z.txt
done
wait
echo "step1"
##################### Preparing eject media list ###########################
echo "stat x" > /tmp/uma.cmd
echo "exit" >> /tmp/uma.cmd
echo "\n `date` \n" > $TMP_EJECT1
echo "*************** $CUSTOMER ************" >> $TMP_EJECT1
echo "---------------------------------------" >> $TMP_EJECT1
echo "Eject Tape List:  Please Unload Below Tapes from $LB_NAME Library " >> $TMP_EJECT1
echo "----------------------------------------" >> $TMP_EJECT1
/opt/omni/lbin/uma -ioctl $LB_EXCHANGER -barcode -tty </tmp/uma.cmd | grep Full >> $TMP_EJECT
wait
#
for N in $(cat /tmp/z_eject_list1.txt | awk '{print (substr($4,2,(length($4)-2)))}')
do
 /opt/omni/bin/omnimm -check_protection $N | awk '{print $2 "    " $6 " " $8 " " $9}' >> $TMP_EJECT1
done
wait
echo "step2"
##################### Preparing media list pool ###########################
cat $TMP_EJECT1 > $TMP_OUT_FILE
cat $TMP_FREE_LIST >> $TMP_OUT_FILE
echo "step3"
################### Mailing ###########################
/sbin/cat /tmp/eao_bkp/mail /tmp/z_final.txt | /usr/sbin/sendmail -t
