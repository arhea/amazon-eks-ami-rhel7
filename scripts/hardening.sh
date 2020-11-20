#!/usr/bin/env bash

set -o pipefail
set -o nounset
set -o errexit

# enable dod stig
if [ "${HARDENING_FLAG}" = "stig" ]; then

  # install dependencies
  yum install -y dracut-fips-aesni dracut-fips openscap openscap-scanner scap-security-guide

  # we will configure FIPS ourselves as the generated STIG locks the OS
  # configure dracut-fips
  dracut -f

  # udpate the kernel settings
  grubby --update-kernel=ALL --args="fips=1"

  # configure this to meet the stig checker
  sed -i "/^GRUB_CMDLINE_LINUX/ s/\"$/ fips=1\"/" /etc/default/grub

  # set the ssh ciphers
  sed -i 's/^Cipher.*/Ciphers aes128-ctr,aes192-ctr,aes256-ctr/' /etc/ssh/sshd_config
  sed -i 's/^MACs.*/MACs hmac-sha2-256,hmac-sha2-512/' /etc/ssh/sshd_config

  # run stig hardening without FIPS as it breaks EC2 booting because /boot isn't on its
  # own partition
  oscap xccdf generate fix \
    --output /etc/packer/stig.sh \
    --tailoring-file /etc/packer/files/ssg-rhel7-ds-tailoring.xml \
    --profile xccdf_org.ssgproject.content_profile_stig_aws \
    --fetch-remote-resources \
    /usr/share/xml/scap/ssg/content/ssg-rhel7-ds.xml

  /etc/packer/stig.sh

  reboot

fi
