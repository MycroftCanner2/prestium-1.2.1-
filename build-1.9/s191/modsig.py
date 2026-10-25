import os, lzma, zlib, sys, subprocess
from concurrent.futures import ThreadPoolExecutor
R='/workspace/work/prestium/v20/rootfs/lib/modules'
MAGIC=b'~Module signature appended~\n'
files=[]
for root,_,fs in os.walk(R):
    for f in fs:
        if '.ko' in f: files.append(os.path.join(root,f))
def chk(p):
    try:
        d=open(p,'rb').read()
        if p.endswith('.xz'): d=lzma.decompress(d)
        elif p.endswith('.zst'): d=subprocess.run(['zstd','-dc',p],capture_output=True).stdout
        elif p.endswith('.gz'): d=zlib.decompress(d,47)
        return p, d.endswith(MAGIC)
    except Exception as e:
        return p, 'ERR %s'%e
bad=[];n=0
with ThreadPoolExecutor(16) as ex:
    for p,ok in ex.map(chk,files):
        n+=1
        if ok is not True: bad.append((p,ok))
print('TOTAL',n,'UNSIGNED',len(bad))
for p,ok in bad: print('UNSIGNED',ok,p)
print('MODSIG-DONE')
