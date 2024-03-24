# dns_bind

This script adds and removes a TXT record to a BIND DNS zone file for using acme.sh to get a certificate, if you set up an authority dns server for your domain.

You can use this script after move this file into acme dir, add `dns dns_bind` while using acme.sh 
 
**NOTE:** This script assumes that the zone file is named after the `db.` like `db.domain.com` and is located in `/etc/bind/zones/`. Ensure the BIND configuration is set up accordingly.
 If you enabled `dnssec` function, you should change dir and name of ZSK and KSK below in `resign_zone` function, and add it into `dns_bind_add` and `dns_bind_rm` manully.
