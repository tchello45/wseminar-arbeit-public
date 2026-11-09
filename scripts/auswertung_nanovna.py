#!/usr/bin/env python3
"""Reproduce chapter 7 from the 18 documented NanoVNA acquisitions."""
from pathlib import Path
import argparse
import csv
import hashlib
import io
import json
import subprocess
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
GROUPS = ['Open', 'Short', 'Load', 'Kabel1_Offen', 'Kabel1_Adapter_Open', 'Kabel1_Adapter_Short']
COLORS = dict(zip(GROUPS, ['#087f8c','#c06c28','#7354a5','#087f8c','#7354a5','#c06c28']))
LABELS = dict(zip(GROUPS, ['OPEN','SHORT','LOAD','Kabel, freies Ende','Kabel + Adapter + OPEN','Kabel + Adapter + SHORT']))


def load(root):
    records = json.loads((root/'nachweise/DONNERSTAG-standards.json').read_text())
    records += json.loads((root/'nachweise/DONNERSTAG-kabel1.json').read_text())
    groups = {name: [] for name in GROUPS}
    files = {name: [] for name in GROUPS}
    base = None
    for row in records:
        name = row.get('standard', row.get('configuration'))
        path = root/row['file']
        meta=json.loads((path.parent/'metadata.json').read_text())
        # Metadata belongs to the current export; the acquisition list may
        # retain a hash from before a comment-only Touchstone header cleanup.
        assert hashlib.sha256(path.read_bytes()).hexdigest() == meta['sha256'], path
        lines = [x for x in path.read_text().splitlines() if x and not x.startswith(('!', '#'))]
        data = np.loadtxt(io.StringIO('\n'.join(lines)))
        f = data[:,0]; g = data[:,1] + 1j*data[:,2]
        assert np.all(np.isfinite(data)) and len(f)==101
        if base is None: base=f
        assert np.array_equal(f,base) and f[0]==2.3e9 and f[-1]==2.5e9
        assert meta['synthetic'] is False
        groups[name].append((row['repeat'],g)); files[name].append((row['repeat'],path))
    assert len(records)==18
    return base, {k:np.array([g for _,g in sorted(v)]) for k,v in groups.items()}, files


def smith(ax):
    theta=np.linspace(0,2*np.pi,1500)
    ax.plot(np.cos(theta),np.sin(theta),color='#93a1ab',lw=.8)
    for r in [.2,.5,1,2,5]:
        ax.plot(r/(1+r)+np.cos(theta)/(1+r),np.sin(theta)/(1+r),color='#dce2e6',lw=.5)
    for x in [-5,-2,-1,-.5,-.2,.2,.5,1,2,5]:
        z=np.linspace(0,300,2000)+1j*x; g=(z-1)/(z+1)
        ax.plot(g.real,g.imag,color='#dce2e6',lw=.5)
    ax.axhline(0,color='#dce2e6',lw=.5)
    ax.set(xlim=(-1.12,1.12),ylim=(-1.12,1.12),aspect='equal',xlabel='Re Γ',ylabel='Im Γ',xticks=[-1,0,1],yticks=[-1,0,1])
    for x,label in [(-1,'SHORT'),(0,'50 Ω'),(1,'OPEN')]:
        ax.annotate(label,(x,0),xytext=(0,-15),textcoords='offset points',ha='center',fontsize=7,color='#596873')
    for spine in ax.spines.values(): spine.set_visible(False)


def save(fig,out,name):
    for ext in ('svg','png','pdf'):
        fig.savefig(out/f'{name}.{ext}',dpi=220,bbox_inches='tight',facecolor='white')
    plt.close(fig)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=ROOT)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--rust-binary',type=Path)
    args=parser.parse_args(); root=args.root.resolve(); out=args.output
    out.mkdir(parents=True,exist_ok=True)
    f,groups,files=load(root); i=50; assert f[i]==2.4e9
    stats={}; checks={}; point_rows=[]
    for name,g in groups.items():
        assert g.shape==(3,101)
        a=abs(g); phase=np.angle(g[:,i],deg=True)
        if name=='Short': phase=180+np.angle(-g[:,i],deg=True)
        unwrapped=np.unwrap(np.angle(g),axis=1)
        slopes=np.array([np.polyfit((f-f.mean())/1e9,p,1)[0] for p in unwrapped])
        tau=-slopes/(2*np.pi)
        stats[name]={'magnitude_mean':float(a[:,i].mean()),'magnitude_min':float(a[:,i].min()),
                     'magnitude_max':float(a[:,i].max()),'phase_mean_deg':None if name=='Load' else float(phase.mean()),
                     'phase_min_deg':None if name=='Load' else float(phase.min()),
                     'phase_max_deg':None if name=='Load' else float(phase.max()),
                     'all_band_magnitude_min':float(a.min()),'all_band_magnitude_max':float(a.max()),
                     'effective_round_trip_ns':None if name in ('Open','Short','Load') else tau.tolist(),
                     'rms_complex_spread_at_2_4GHz':float(np.sqrt(np.mean(abs(g[:,i]-g[:,i].mean())**2)))}
        for index,freq in enumerate(f):
            point_rows.append([name,int(freq),float(a[:,index].mean()),float(a[:,index].min()),float(a[:,index].max())])
        if args.rust_binary:
            maximum=0.
            for repeat,path in sorted(files[name]):
                result=subprocess.run([str(args.rust_binary.resolve()),'--import',str(path)],check=True,capture_output=True,text=True)
                (out/f'{name}_{repeat:02d}-rust.csv').write_text(result.stdout)
                rows=list(csv.DictReader(io.StringIO(result.stdout)))
                assert len(rows)==101
                expected=g[repeat-1]
                for row,freq,gamma in zip(rows,f,expected):
                    assert float(row['frequency_hz'])==freq
                    amp=abs(gamma); z=50*(1+gamma)/(1-gamma)
                    refs={'s11_re':gamma.real,'s11_im':gamma.imag,'magnitude':amp,
                          'phase_deg':np.angle(gamma,deg=True),'s11_db':20*np.log10(amp),
                          'z_re_ohm':z.real,'z_im_ohm':z.imag}
                    for key,ref in refs.items():
                        actual=float(row[key]); maximum=max(maximum,abs(actual-ref))
                        assert np.isclose(actual,ref,rtol=1e-9,atol=1e-9),(path,key)
                    if amp<1:
                        assert row['vswr_status']=='finite'
                        assert np.isclose(float(row['vswr']),(1+amp)/(1-amp),rtol=1e-9,atol=1e-9)
                    else:
                        assert row['vswr_status']=='outside_passive_range'
            checks[name]={'points':303,'max_absolute_error_without_vswr':maximum}
    result={'date':'2026-11-05','frequency_hz':2400000000,'repeats_per_configuration':3,'total_acquisitions':18,
            'source_hashes_checked':True,'identical_frequency_grids':True,'groups':stats,'rust_python':checks,
            'phase_separation_adapter_deg_at_2_4GHz':float(np.angle(np.exp(1j*np.deg2rad(stats['Kabel1_Adapter_Open']['phase_mean_deg']-stats['Kabel1_Adapter_Short']['phase_mean_deg'])),deg=True)),
            'script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    (out/'rechenwerte.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
    with (out/'betragsbereiche.csv').open('w') as stream:
        writer=csv.writer(stream); writer.writerow(['configuration','frequency_hz','mean_magnitude','min_magnitude','max_magnitude']); writer.writerows(point_rows)
    lines=['#figure(', '  table(', '    columns: (1.5fr, 0.7fr, 1.1fr, 0.7fr),', '    table.header([Konfiguration], [Mittleres $abs(Gamma)$], [Min.–Max. $abs(Gamma)$], [Mittlere Phase]),']
    labels=['OPEN direkt','SHORT direkt','LOAD direkt','Kabel, freies Ende','Kabel + Adapter + OPEN','Kabel + Adapter + SHORT']
    def de(value,digits): return f'{value:.{digits}f}'.replace('.',',')
    for name,label in zip(GROUPS,labels):
        row=stats[name]; phi='–' if row['phase_mean_deg'] is None else de(row['phase_mean_deg'],2)+'°'
        lines.append('    ['+label+'], ['+de(row['magnitude_mean'],4)+'], ['+de(row['magnitude_min'],4)+'–'+de(row['magnitude_max'],4)+'], ['+phi+'],')
    lines+=['  ),', '  kind: table,', '  supplement: [Tabelle],', '  caption: [Ergebnisse bei 2,4 GHz, jeweils drei Anschlusswiederholungen. Angegeben sind das arithmetische Mittel der Beträge und ihr beobachteter Bereich; die LOAD-Phase wird nicht interpretiert. Phasen sind lokal auf einen gemeinsamen Winkelzweig bezogen.],', ') <tab-vna-zentrum>']
    (out/'tabelle.typ').write_text('\n'.join(lines)+'\n')
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':8.5,'axes.titlesize':10,'axes.labelsize':8.5,
                         'axes.spines.top':False,'axes.spines.right':False,'svg.fonttype':'none','axes.titleweight':'bold'})
    styles=['-','--',':']
    fig,axes=plt.subplots(2,2,figsize=(7.2,5.25),layout='constrained')
    sm,ph,mag,loadmag=axes.ravel(); smith(sm)
    for name in GROUPS[:3]:
        for n,g in enumerate(groups[name]):
            c=COLORS[name]; label=LABELS[name] if n==0 else '_nolegend_'
            sm.plot(g.real,g.imag,styles[n],color=c,lw=1,alpha=.9,label=label)
            if name=='Load': loadmag.plot(f/1e9,20*np.log10(abs(g)),styles[n],color=c,lw=1,label=f'Anschluss {n+1}')
            else:
                mag.plot(f/1e9,20*np.log10(abs(g)),styles[n],color=c,lw=1,label=label)
                delta=np.angle(g if name=='Open' else -g,deg=True)
                ph.plot(f/1e9,delta,styles[n],color=c,lw=1,label=label)
    sm.set_title('(a) Direkte Standards',loc='left');sm.legend(loc='upper right',fontsize=7,frameon=False)
    ph.set_title('(b) Abweichung der Reflexionsphase',loc='left'); ph.set(ylabel='φ − φ ideal / Grad',xlabel='Frequenz / GHz');ph.legend(fontsize=7,frameon=False)
    mag.set_title('(c) OPEN und SHORT',loc='left');mag.set(ylabel='S11 / dB',xlabel='Frequenz / GHz')
    loadmag.set_title('(d) LOAD: gemessener Reflexionsrest',loc='left');loadmag.set(ylabel='S11 / dB',xlabel='Frequenz / GHz');loadmag.legend(fontsize=7,frameon=False)
    for ax in (ph,mag,loadmag): ax.grid(color='#e1e6eb',lw=.5);ax.set_axisbelow(True)
    save(fig,out,'standards')
    fig=plt.figure(figsize=(7.2,5.0),layout='constrained'); grid=fig.add_gridspec(2,2,width_ratios=[1,1.1])
    sm=fig.add_subplot(grid[:,0]);smith(sm);am=fig.add_subplot(grid[0,1]);ph=fig.add_subplot(grid[1,1])
    for name in GROUPS[3:]:
        g=groups[name]; c=COLORS[name]; a=abs(g)
        # Each phase is unwrapped along frequency; anchor branches consistently within one setup.
        p=np.unwrap(np.angle(g),axis=1)
        for n in range(1,3): p[n]+=2*np.pi*round((p[0,0]-p[n,0])/(2*np.pi))
        p=np.rad2deg(p)
        for trace in g: sm.plot(trace.real,trace.imag,color=c,alpha=.3,lw=.7)
        mean=g.mean(axis=0);sm.plot(mean.real,mean.imag,color=c,lw=1.25,label=LABELS[name]);sm.plot(mean.real[0],mean.imag[0],'o',color=c,ms=3)
        am.plot(f/1e9,20*np.log10(a.mean(axis=0)),color=c,lw=1.25,label=LABELS[name]);am.fill_between(f/1e9,20*np.log10(a.min(axis=0)),20*np.log10(a.max(axis=0)),color=c,alpha=.15)
        ph.plot(f/1e9,p.mean(axis=0),color=c,lw=1.25);ph.fill_between(f/1e9,p.min(axis=0),p.max(axis=0),color=c,alpha=.15)
    sm.set_title('(a) Reflexionsebene',loc='left')
    am.set_title('(b) Reflexionsbetrag',loc='left');am.set(ylabel='S11 / dB',xlabel='Frequenz / GHz')
    ph.set_title('(c) Stetig fortgesetzte Phase',loc='left');ph.set(ylabel='Phase / Grad',xlabel='Frequenz / GHz')
    for ax in (am,ph):ax.grid(color='#e1e6eb',lw=.5);ax.set_axisbelow(True)
    handles,labels=am.get_legend_handles_labels();fig.legend(handles,labels,loc='outside lower center',ncols=1,fontsize=8,frameon=False)
    save(fig,out,'kabel')
    from matplotlib.patches import FancyBboxPatch
    fig,ax=plt.subplots(figsize=(7.2,2.25),layout='constrained')
    ax.set(xlim=(0,10),ylim=(-.45,3.2));ax.axis('off')
    def box(x,y,w,label,color='#f2f5f7'):
        ax.add_patch(FancyBboxPatch((x,y-.23),w,.46,boxstyle='round,pad=.04',facecolor=color,edgecolor='#8295a2',lw=.8))
        ax.text(x+w/2,y,label,ha='center',va='center',fontsize=8.5)
    for y in [2.4,1.3,.2]:
        box(.1,y,1.5,'NanoVNA · CH0')
        ax.plot([1.65,2.25],[y,y],color='#243d4a',lw=1.2)
    ax.axvline(2.25,ymin=.06,ymax=.88,color='#c06c28',ls='--',lw=1)
    ax.text(2.25,3,'Kalibrier-/Referenzebene',ha='center',color='#9c501e',fontsize=9)
    ax.plot([2.25,3],[2.4,2.4],color='#243d4a',lw=1.2);box(3,2.4,2.4,'OPEN / SHORT / LOAD')
    for y in [1.3,.2]:
        ax.plot([2.25,5.8],[y,y],color='#087f8c',lw=2)
        ax.text(4,y+.16,'Kabel 1',ha='center',fontsize=9,color='#087f8c')
    ax.plot(5.8,1.3,'o',mfc='white',mec='#087f8c',ms=5)
    ax.text(6.05,1.3,'freies Ende, ohne Adapter',va='center',fontsize=8.5)
    box(5.8,.2,1.1,'Adapter');ax.plot([6.95,7.35],[.2,.2],color='#243d4a',lw=1.2)
    box(7.35,.2,2.1,'OPEN oder SHORT')
    save(fig,out,'aufbau')
    print(json.dumps(result,indent=2,ensure_ascii=False))

if __name__=='__main__':main()
