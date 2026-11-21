import zipfile,re,sys
src,dst=sys.argv[1],sys.argv[2]
DEAD='https://localhost.invalid/'
bad=b'http://repo.tl.vg/update/downloads/libraries/org/tlauncher/updater/TLauncherUpdater.exe'
off=b'https://127.0.0.1/disabled/'+b'x'*(len(bad)-31)+b'.exe'
HOMEPAGE='https://raw.githubusercontent.com/vassu-v/clean-t_launcher/main/'
hp_old=b'\x01\x00\x10main.server.repo'; hp_new=b'\x01\x00\x0ehome.page.repo'
ssl_old=b'\x01\x00\x0ddeactivateSSL'; ssl_new=b'\x01\x00\x0fcreateTimeStart'
zi=zipfile.ZipFile(src);zo=zipfile.ZipFile(dst,'w',zipfile.ZIP_DEFLATED);c={'upd':0,'ssl':0,'props':0,'home':0}
for i in zi.infolist():
    b=zi.read(i);n=i.filename
    if n=='inner.tlauncher.properties':
        out=[]
        for ln in b.decode().split('\n'):
            ln=ln.rstrip('\r');m=re.match(r'^([^=]+)=(.*)$',ln)
            if not ln.startswith('#') and m:
                k,v=m.groups()
                if k in('statistics.url','skin.server.advertising','log.system'): v=DEAD;c['props']+=1
                elif k=='file.server.downloader.comparing': v='https://res.tlauncher.org/unb,https://res.tl.vg/unb';c['props']+=1
                elif re.search('https?://',v) and ',' in v:
                    keep=[x for x in v.split(',') if not x.startswith('http://') and 'fastrepo.org' not in x]
                    if keep and keep!=v.split(','): v=','.join(keep);c['props']+=1
                ln=f'{k}={v}'
            out.append(ln)
        out=[l for l in out if not l.startswith('home.page.repo=')]
        while out and out[-1]=='': out.pop()
        out+=['home.page.repo='+HOMEPAGE,'']
        b='\n'.join(out).encode()
    elif n.endswith('.class'):
        if bad in b: b=b.replace(bad,off);c['upd']+=1
        if ssl_old in b and not n.startswith('org/tlauncher/util/TlauncherUtil'): b=b.replace(ssl_old,ssl_new);c['ssl']+=1
    if n=='org/tlauncher/util/TlauncherUtil.class' and hp_old in b: b=b.replace(hp_old,hp_new);c['home']+=1
    zo.writestr(i,b)
zo.close();print(c)
assert c['upd']==1 and c['ssl']==2 and c['home']==1, 'patch targets changed'
