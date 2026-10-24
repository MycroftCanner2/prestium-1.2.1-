#!/usr/bin/env python3
# copy paths from the 1.8 rootfs into the 1.9 rootfs, preserving mode/symlinks,
# mapping ownership by user/group NAME (uids differ between the two systems)
import os,sys,shutil,stat
OLD='/workspace/work/prestium/v19/rootfs'; NEW='/workspace/work/prestium/v20/rootfs'
def db(root,f):
    m={}
    for l in open(root+f):
        p=l.split(':')
        if len(p)>2: m[int(p[2])]=p[0]
    return m
def rdb(root,f):
    return {v:k for k,v in db(root,f).items()}
ou,og=db(OLD,'/etc/passwd'),db(OLD,'/etc/group')
nu,ng=rdb(NEW,'/etc/passwd'),rdb(NEW,'/etc/group')
def mapid(st):
    un=ou.get(st.st_uid); gn=og.get(st.st_gid)
    if un not in nu or gn not in ng:
        raise SystemExit(f"MISSING-ID {un}/{gn} ({st.st_uid}:{st.st_gid})")
    return nu[un],ng[gn]
def cp1(rel):
    s=OLD+rel; d=NEW+rel
    st=os.lstat(s)
    pd=os.path.dirname(d)
    if not os.path.isdir(pd):
        cp1(os.path.dirname(rel))
    if stat.S_ISLNK(st.st_mode):
        if os.path.lexists(d) and not os.path.isdir(d) or os.path.islink(d): os.unlink(d)
        os.symlink(os.readlink(s),d)
    elif stat.S_ISDIR(st.st_mode):
        if os.path.islink(d): os.unlink(d)
        os.makedirs(d,exist_ok=True)
    elif stat.S_ISREG(st.st_mode):
        if os.path.islink(d): os.unlink(d)
        shutil.copyfile(s,d)
    else:
        print("SKIP-SPECIAL",rel); return
    u,g=mapid(st); os.lchown(d,u,g)
    if not stat.S_ISLNK(st.st_mode): os.chmod(d,stat.S_IMODE(st.st_mode))
def cptree(rel):
    cp1(rel)
    s=OLD+rel
    if os.path.isdir(s) and not os.path.islink(s):
        for root,dirs,files in os.walk(s):
            r=root[len(OLD):]
            for x in dirs+files: cp1(r+'/'+x)
if __name__=='__main__':
    n=0
    for line in open(sys.argv[1]):
        rel=line.strip()
        if not rel or rel.startswith('#'): continue
        if rel.endswith('/**'): cptree(rel[:-3])
        else: cp1(rel)
        n+=1
    print("OVERLAY-OK",n)
