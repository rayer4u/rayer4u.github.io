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
    # 去掉多余的''
    sub_domains = [sub for sub in os.getenv('SUB_DOMAIN').split(',') if sub]

    print("Checking Domain: %s at %s" % (domain, datetime.datetime.now().isoformat()))
    current_ip = get_ip()
    print("Host IP: %s" % current_ip)

    api = apicn.DomainInfo(domain_id='', domain=domain, login_token=login_token)
    domain_id = api().get("domain", {}).get("id")

    rl_api = apicn.RecordList(domain_id, record_type='A', login_token=login_token)
    records = rl_api().get('records')
    updated = False
    for record in records:
        if sub_domains and record['name'] not in sub_domains:
            print("Domain: %s.%s Skiped" % (record['name'], domain))
            continue
        sub_domain = record['name']
        record_ip = record.get('value')
        record_id = record.get('id')
        record_line = record.get('line')

        if current_ip != record_ip:
            api = apicn.RecordDdns(record_id, sub_domain, record_line, domain_id=domain_id, value=current_ip, login_token=login_token)
            ret = api()
            new_ip = ret.get('record').get('value')
            print("Domain: %s.%s IP %s changed to %s at %s!" % (sub_domain, domain, record_ip, new_ip, datetime.datetime.now().isoformat()))
            updated = True
        else:
            print("Domain: %s.%s IP reserved." % (sub_domain, domain))
    if updated:
        print('Updated at %s!' % (datetime.datetime.now().isoformat()))


if __name__ == '__main__':
    main()
