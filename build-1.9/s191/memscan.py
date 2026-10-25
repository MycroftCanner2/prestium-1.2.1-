import sys
pat=b'PRESTIUM-WIPE-'+b'7f3c9a1e5d2b'
f=open(sys.argv[1],'rb'); n=0; tail=b''; CH=64<<20
while True:
    b=f.read(CH)
    if not b: break
    d=tail+b; n+=d.count(pat); tail=d[-(len(pat)-1):]
    # avoid double count across boundary: occurrences fully inside tail were counted already
    n-=tail.count(pat)
print('pattern occurrences:',n)
