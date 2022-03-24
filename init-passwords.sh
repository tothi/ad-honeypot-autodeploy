#!/bin/bash
#

echo "[*] Setting initial passwords."

echo
echo "[!] CAUTION: Some of the passwords below must meet complexity requirements!"
echo "[!] It is not checked here, but lack of complexity may cause failure in the last (config deployment) phase"
echo

echo -n "[?] Enter default Windows local Administrator password: "
read -s adminpass
echo

echo -n "[?] Enter Windows Domain Admin password for user ECORP\\Administrator: "
read -s domainadminpass
echo

echo -n "[?] Enter DSRM password for Windows Domain: "
read -s dsrmpass
echo

echo -n "[?] Enter password for sudo user 'ubuntu' on Ubuntu (Graylog) system: "
read -s ubuntupass
echo

echo -n "[?] Enter Graylog password for root user 'admin': "
read -s graylogpass
echo

echo "[*] Setting Windows local Administrator password and Ubuntu user password in packer/private.json"
adminpass_esc=$(printf '%s\n' "${adminpass}" | sed -e 's/[\/&]/\\&/g')
ubuntupass_esc=$(printf '%s\n' "${ubuntupass}" | sed -e 's/[\/&]/\\&/g')
sed -i packer/private.json -e "s/\"administrator_password\": \".*\"/\"administrator_password\": \"${adminpass_esc}\"/" \
                           -e "s/\"ubuntu_password\": \".*\"/\"ubuntu_password\": \"${ubuntupass_esc}\"/" \

p1=`echo -n "${adminpass}Password" | iconv -tutf-16le | base64 -w0`
p2=`echo -n "${adminpass}AdministratorPassword" | iconv -tutf-16le | base64 -w0`
for w in win2016 win10 win2012r2; do
  a="packer/answer_files/${w}/Autounattend.xml"
  echo "[*] Setting Windows local Administrator password in ${a} for UserAccounts and AutoLogon"
  sed -i "$a" -e "/<Password>/,/<\/Password>/ s/<Value>.*<\/Value>/<Value>${p1}<\/Value>/" \
              -e "/<AdministratorPassword>/,/<\/AdministratorPassword>/ s/<Value>.*<\/Value>/<Value>${p2}<\/Value>/"
done

echo "[*] Creating SSH key for Ubuntu (Graylog) access..."
rm -fr packer/.ssh
mkdir packer/.ssh
ssh-keygen -t ed25519 -f packer/.ssh/id_ed25519 -N "" -C ubuntu@packer-host
SSH_PUBKEY=`cat packer/.ssh/id_ed25519.pub | tr -d '\n'`

echo "[*] Setting Ubuntu password ans SSH key in packer/answer_files/graylog/preseed.cfg"
ubuntupasscrypt=`mkpasswd -m sha-512 -S $(pwgen -ns 16 1) ${ubuntupass}`
sed -i packer/answer_files/graylog/preseed.cfg -e "s#d-i passwd/user-password-crypted password .*#d-i passwd/user-password-crypted password ${ubuntupasscrypt}#" \
                                               -e "s#echo ssh-ed25519 AAA.* ubuntu@packer-host#echo ${SSH_PUBKEY}#"

echo "[*] Setting Graylog password in packer/scripts/graylog.sh"
graylogsha2=`echo -n "${graylogpass}" | sha256sum | cut -d' ' -f1`
sed -i packer/scripts/graylog.sh -e "s/GRAYLOG_SHA2=\".*\"/GRAYLOG_SHA2=\"${graylogsha2}\"/"

echo "[*] Updating passwords in ansible/hosts"
domainadminpass_esc=$(printf '%s\n' "${domainadminpass}" | sed -e 's/[\/&]/\\&/g')
dsrmpass_esc=$(printf '%s\n' "${dsrmpass}" | sed -e 's/[\/&]/\\&/g')
graylogpass_esc=$(printf '%s\n' "${graylogpass}" | sed -e 's/[\/&]/\\&/g')
sed -i ansible/hosts -e "s/^default_password=.*/default_password=\"${adminpass_esc}\"/" \
                     -e "s/^domain_admin_password=.*/domain_admin_password=\"${domainadminpass_esc}\"/" \
                     -e "s/^dsrm_password=.*/dsrm_password=\"${dsrmpass_esc}\"/" \
                     -e "s/^ubuntu_password=.*/ubuntu_password=\"${ubuntupass_esc}\"/" \
                     -e "s/^graylog_pwd=.*/graylog_pwd=\"${graylogpass_esc}\"/"

echo "[+] Done. Deploy with packer+terraform+ansible."

