#!/usr/bin/env sh

# This script adds a TXT record to a BIND DNS zone file for using acme.sh, if you set up 
# an authority dns server for your domain.
# NOTE: This script assumes that the zone file is named after the db. like db.domain.com
# and is located in /etc/bind/zones/. Ensure the BIND configuration is set up accordingly.
# If you enabled dnssec function, you should change dir and name of ZSK and KSK below in 
# resign_zone function, and add it into dns_bind_add and dns_bind_rm manully.

#returns 0 means success, otherwise error.
#
#Template Author: Neilpang
#Report Bugs here: https://github.com/acmesh-official/acme.sh
#
########  functions start #####################

# Please Read this guide first: https://github.com/acmesh-official/acme.sh/wiki/DNS-API-Dev-Guide
# Usage: dns_myapi_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"



# please modify dir for yours.
ZONE_FILES_DIR="/etc/bind/zones"

RELOAD_CMD="sudo systemctl reload bind9"

# Extracts the root domain from the full domain
# Example: _extract_root_domain "_acme-challenge.www.example.com" returns "example.com"
_extract_root_domain() {
    echo "$1" | rev | cut -d. -f1-2 | rev
}

# Using dnssec function with bind9 need resign zone file after added or removed record.
# You should change dir and name of ZSK and KSK below as your own before add this 
# function into dns_bind_add and dns_bind_rm.
resign_zone(){
    echo "Re-signing the zone: ${zone_file}"
    dnssec-signzone -K ${ZONE_FILES_DIR} -o ${root_domain} -k K${root_domain}.${ZSK}.key $zone_file K${root_domain}.${KSK}.key
    $RELOAD_CMD
}

#Add the txt record before validation.
dns_bind_add() {
  fulldomain=$1
  txtvalue=$2
  _info "Using bind"
  _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  root_domain="$(_extract_root_domain "$fulldomain")"
  zone_file="${ZONE_FILES_DIR}/db.${root_domain}"

  # Check if the zone file exists
  if [ ! -f "$zone_file" ]; then
    _err "Zone file for $root_domain not found in $ZONE_FILES_DIR"
     _err "Add txt record error."
    return 1
  fi

  # Add TXT record to zone file  
  echo "$fulldomain. IN TXT \"$txtvalue\"" >> "$zone_file"

  # Reload BIND to apply changes
  if $RELOAD_CMD; then
    _info "BIND reloaded successfully, TXT record added."
    return 0
  else
    _err "Failed to reload BIND."
    return 1
  fi
}

#Remove the txt record after validation.
dns_bind_rm() {
  fulldomain=$1
  txtvalue=$2
   _debug fulldomain "$fulldomain"
  _debug txtvalue "$txtvalue"

  root_domain="$(_extract_root_domain "$fulldomain")"
  zone_file="${ZONE_FILES_DIR}/db.${root_domain}"

  _info "Using bind, Removing TXT record for $fulldomain with value $txtvalue"
  if [ ! -f "$zone_file" ]; then
    _err "Zone file for $root_domain not found in $ZONE_FILES_DIR"
    return 1
  fi

  # Remove the record
  sed -i "/$fulldomain. IN TXT \"$txtvalue\"/d" "$zone_file" && \
  _info "TXT record removed successfully." || _err "Failed to remove TXT record."
  $RELOAD_CMD && \
  _info "BIND reloaded successfully." || _err "Failed to reload BIND."
}

########  functions end #####################
