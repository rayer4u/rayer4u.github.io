#!/usr/bin/env python3
# -*- coding:utf-8 -*-
import os
import datetime

from dnspod import apicn
from get_ip import get_ip
from dotenv import load_dotenv
load_dotenv()


def main():
    login_token = os.getenv('LOGIN_TOKEN')
    domain = os.getenv('DOMAIN')
    sub_domain = os.getenv('SUB_DOMAIN')

    print("Updating Domain: %s.%s at %s" % (sub_domain, domain, datetime.datetime.now().isoformat()))
    current_ip = get_ip()
    print("Host Ip: %s" % current_ip)

    api = apicn.DomainInfo(domain_id='', domain=domain, login_token=login_token)
    domain_id = api().get("domain", {}).get("id")

    api = apicn.RecordList(domain_id, sub_domain=sub_domain, record_type='A', login_token=login_token)
    record = api().get('records')[0]
    record_ip = record.get('value')
    record_id = record.get('id')
    record_line = record.get('line')
    print("Last Ip: %s" % record_ip)
    
    if current_ip != record_ip:
        api = apicn.RecordDdns(record_id, sub_domain, record_line, domain_id=domain_id, value=current_ip, login_token=login_token)
        ret = api()
        new_ip = ret.get('record').get('value')
        print('Updated: %s at %s' % (new_ip, datetime.datetime.now().isoformat()))
    else:
        print('Last IP is the same as current IP!')


if __name__ == '__main__':
    main()
