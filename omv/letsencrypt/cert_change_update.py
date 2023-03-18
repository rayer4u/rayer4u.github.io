#!/bin/python
# 检查文件是否变更，会在文件所在目录创建`.last_modify`记录上次修改时间，第一次不算修改
import os
import sys
import json


def file_changed(file_path):
    folder,name = os.path.split(file_path)
    modifies_path = os.path.join(folder, '.last_modify')
    if not os.path.exists(modifies_path):
        open(modifies_path, 'w').close()
    with open(modifies_path, 'r+') as f:
        try:
            modifies = json.loads(f.read())
        except json.JSONDecodeError:
            modifies = {}
        if name not in modifies:
            file_old_stat = os.stat(file_path).st_mtime
            modifies[name] = file_old_stat

            f.seek(0)
            f.write(json.dumps(modifies))
            f.truncate()
            return False
        else:
            file_old_stat = modifies[name]
            file_new_stat = os.stat(file_path).st_mtime

            if (file_old_stat != file_new_stat):
                modifies[name] = file_new_stat
                f.seek(0)
                f.write(json.dumps(modifies))
                f.truncate()
                return True
            else:
                return False


if __name__=="__main__":
    if len(sys.argv) > 1:
        file_path = sys.argv[1]
    else:
        print("need path")
        exit(0)

    changed = file_changed(file_path)
    if changed:
        print("file_path  is changed")
        os.system("docker exec -t omv_seafile_1 nginx -s reload")
        exit(1)
    else:
        print("file_path  is not changed")
        exit(0)

