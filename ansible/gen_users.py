#!/usr/bin/env python3
#
# generate fake users for ad:
#  * importable by ansible win_domain_user module users.yml var file (slow)
#  * ps1 script format (fast)
#

from faker import Factory
import random

NUM_OF_USERS = 1000
OUT_YML = "users.yml"
OUT_PS1 = "users.ps1"
OU = "Staff"

fake = Factory.create('en-GB')

group_chance = {"Domain Admins": 0.05, "RDP All": 0.8}

wordlist = list(map(lambda x: x.rstrip(), open("wordlist.txt", "r").readlines()))

def grouplist():
  res = []
  for g in group_chance:
    if random.random() < group_chance[g]:
      res.append(g)
  return res

yml = open(OUT_YML, "w")
ps1 = open(OUT_PS1, "w")

ps1.write('$d = (Get-ADDomain).DistinguishedName\r\n')
ps1.write('If (Get-ADOrganizationalUnit -Filter "distinguishedName -eq \'OU={},$d\'") {{ Remove-ADOrganizationalUnit -Identity "OU={},$d" -Confirm:$False }}\r\n'.format(OU, OU))
ps1.write('New-ADOrganizationalUnit -Name "{}" -Path $d -ProtectedFromAccidentalDeletion $false\r\n'.format(OU))
yml.write("users:\n")
groupdb = {}
samdb = []
for i in range(NUM_OF_USERS):
  fn = fake.first_name()
  ln = fake.last_name()
  pw = random.choice(wordlist)
  samname_base = "{}.{}".format(fn.lower(), ln.lower())
  samname = samname_base
  idx = 0
  while samname in samdb:
    idx += 1
    samname = "{}.{}".format(samname_base, idx)
  samdb.append(samname)
  if idx > 0:
    cn = "{} {} {}".format(fn, ln, idx)
  else:
    cn = "{} {}".format(fn, ln)
  yml.write("  - name: {}\n".format(samname))
  yml.write("    firstname: {}\n".format(fn))
  yml.write("    surname: {}\n".format(ln))
  yml.write("    password: {}\n".format(pw))
  yml.write("    state: present\n")
  yml.write("    groups:\n")
  ps1.write('New-ADUser -Enabled $true -AccountPassword (ConvertTo-SecureString -AsPlainText "{}" -Force) -Name "{}" -GivenName "{}" -Surname "{}" -SamAccountName "{}" -Path "OU={},$d"\r\n'.format(pw, cn, fn, ln, samname, OU))
  for g in grouplist():
    yml.write("      - {}\n".format(g))
    if g not in groupdb:
      groupdb[g] = []
    groupdb[g].append(samname)
for g in groupdb:
  ps1.write('If (-Not (Get-ADGroup -Filter "Name -eq \'{}\'")) {{ New-ADGroup -Name "{}" -GroupScope Global }}'.format(g, g))
  ps1.write('Add-ADGroupMember -Identity "{}" -Members "{}"\r\n'.format(g, '","'.join(groupdb[g])))

yml.close()
ps1.close()
