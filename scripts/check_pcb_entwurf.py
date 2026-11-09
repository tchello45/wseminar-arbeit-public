"""Rechenbelege und Prinzipskizzen zu Kapitel 5; kein EM-Antennenmodell.
Aufruf: tools/.venv/bin/python scripts/check_pcb_entwurf.py
Nur die Skizzen benötigen Matplotlib; Rechnungen verwenden Python/math/cmath.
"""
from pathlib import Path
import cmath
import hashlib
import itertools
import json
import math
import platform

ROOT = Path(__file__).resolve().parents[1]
F0 = 2.44e9
OMEGA = 2 * math.pi * F0

def microstrip(u, er):
    if u < 1 or er <= 1:
        raise ValueError('Nur u >= 1 und epsilon_r > 1 unterstützt')
    eff = (er + 1)/2 + (er - 1)/2 / math.sqrt(1 + 12/u)
    return 120*math.pi/(math.sqrt(eff)*(u + 1.393 + 0.667*math.log(u + 1.444))), eff

def width_ratio(er):
    lo, hi = 1., 10.
    assert microstrip(lo, er)[0] > 50 > microstrip(hi, er)[0]
    for _ in range(80):
        mid = (lo + hi)/2
        if microstrip(mid, er)[0] > 50:
            lo = mid
        else:
            hi = mid
    return (lo+hi)/2

def zin(l, c, za=25+10j):
    return 1 / (1/(za + 1j*OMEGA*l) + 1j*OMEGA*c)

def gamma(z):
    return (z-50)/(z+50)

def record(z):
    g = abs(gamma(z))
    return dict(z_real_ohm=z.real, z_imag_ohm=z.imag, gamma_abs=g,
                s11_db=None if g == 0 else 20*math.log10(g))

def main():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from matplotlib.patches import Rectangle, Circle, Arc
    u = width_ratio(4.3)
    z0, eff = microstrip(u, 4.3)
    assert abs(z0-50) < 1e-11
    l, c = 15/OMEGA, .02/OMEGA
    z = zin(l,c)
    # Unabhängiger Rechenweg über ABCD: Shunt-Y gefolgt von Serie-Z.
    a, b, cc, d = 1, 1j*OMEGA*l, 1j*OMEGA*c, 1 + (1j*OMEGA*c)*(1j*OMEGA*l)
    z_abcd = (a*(25+10j)+b)/(cc*(25+10j)+d)
    assert abs(z-50) < 1e-11 and abs(z_abcd-z) < 1e-11
    assert abs(gamma(50)) == 0
    assert abs(abs(gamma(25+10j))-.35586170710706266) < 1e-12
    corners = []
    for dl, dc in itertools.product([-.05,.05], repeat=2):
        corners.append(dict(l_relative=dl,c_relative=dc,**record(zin(l*(1+dl),c*(1+dc)))))
    # Raster ergänzt Ecken; kein globaler Worst-Case-Beweis.
    sweep = [record(zin(l*(.95+i*.001),c*(.95+j*.001)))
             for i in range(101) for j in range(101)]
    worst = max(sweep,key=lambda row:row['gamma_abs'])
    line_corners = [dict(epsilon_r=er,h_mm=h,z0_ohm=microstrip(u/h,er)[0])
                    for er,h in itertools.product([4.1,4.5],[.9,1.1])]
    values = dict(python=platform.python_version(), f0_hz=F0,
        wavelength_mm=299792458/F0*1e3, quarterwave_mm=299792458/F0*250,
        relative_bandwidth_percent=83.5/2440*100,
        microstrip=dict(u=u,epsilon_eff=eff,z0_back_ohm=z0,
            widths_mm={str(h):u*h for h in [.2,1.,1.6]},
            redesigned=[dict(epsilon_r=er,u=width_ratio(er)) for er in [4.1,4.3,4.5]],
            fixed_width_tolerance_corners=line_corners),
        matching=dict(l_nh=l*1e9,c_pf=c*1e12,ideal=record(z),
            abcd_difference_ohm=abs(z_abcd-z),unmatched=record(25+10j),
            rounded=record(zin(1e-9,1.3e-12)),corners=corners,
            grid_count=len(sweep),grid_worst=worst),
        efficiencies=[(1-10**(-20/10))*.3,(1-10**(-10/10))*.8],
        script_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        scope='Analytische Leitungs-/Netzwerkmodelle, keine EM-Simulation oder Messung')
    out=ROOT/'nachweise'; out.mkdir(exist_ok=True)
    (out/'PCB04-rechenwerte.json').write_text(json.dumps(values,indent=2,ensure_ascii=False)+'\n')
    figdir=ROOT/'arbeit/abbildungen'; figdir.mkdir(exist_ok=True)
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':12,'svg.fonttype':'none'})
    fig,(ax,side)=plt.subplots(1,2,figsize=(10,5.5),gridspec_kw={'width_ratios':[1.5,1]})
    ax.add_patch(Rectangle((0,0),35,45,fill=False,lw=1.4))
    ax.add_patch(Rectangle((0,0),35,35,facecolor='#d9e5e9',edgecolor='#607d8b'))
    ax.add_patch(Rectangle((0,35),35,10,facecolor='#faf1d9',edgecolor='#a48027',linestyle='--'))
    # Eigene topologische Zeichnung, bewusst kein Nachzeichnen der TI-Maßgeometrie.
    ax.plot([5,5,30],[35,41,41],color='#9c5126',lw=4,solid_capstyle='butt')
    ax.plot([10,10],[30,41],color='#9c5126',lw=3)
    ax.plot([5,5],[30,35],color='#455a64',lw=2)
    ax.scatter([5],[30],s=40,color='#455a64')
    ax.text(17.5,20,'Massefläche\n35 × 35 mm\nL1 und L2',ha='center')
    ax.annotate('offenes Ende',xy=(30,41),xytext=(21,48),arrowprops={'arrowstyle':'->'},ha='center')
    ax.annotate('Strahler',xy=(19,41),xytext=(18,36.5),ha='center',arrowprops={'arrowstyle':'->'})
    ax.annotate('Short → Masse',xy=(5,36),xytext=(-4,39),ha='right',arrowprops={'arrowstyle':'->'})
    ax.annotate('Feed',xy=(10,38),xytext=(38,38),arrowprops={'arrowstyle':'->'})
    ax.annotate('50-Ω-Leitung\nüber Masse',xy=(10,30),xytext=(37,28),arrowprops={'arrowstyle':'->'})
    ax.annotate('Massekante',xy=(25,35),xytext=(37,33),arrowprops={'arrowstyle':'->'})
    ax.text(17.5,-4,'Platinenbreite 35 mm; Länge 45 mm',ha='center')
    ax.text(17.5,-8,'Prinzipskizze: Strahlerweg nicht bemaßt',ha='center',fontsize=9)
    ax.set(xlim=(-18,61),ylim=(-10,52));ax.set_aspect('equal');ax.axis('off')
    ax.set_title('(a) IFA und Flächenaufteilung',loc='left',pad=15)
    side.add_patch(Rectangle((0,0),32,1,facecolor='#eee5cc',edgecolor='#888'))
    side.plot([0,32],[0,0],color='#607d8b',lw=3)
    side.plot([0,22],[1,1],color='#9c5126',lw=3)
    side.annotate('L1: Speiseleitung',xy=(12,1),xytext=(8,5),arrowprops={'arrowstyle':'->'},ha='center')
    side.annotate('FR4, h = 1,00 mm',xy=(28,.5),xytext=(16,-4),ha='center',arrowprops={'arrowstyle':'->'})
    side.text(16,-7,'L2: durchgehende Bezugsmasse',ha='center')
    side.text(16,-13,'Strahlerzone: auf beiden Lagen\nkein weiteres Kupfer; Ausnahmen\nsind Strahler, Feed und Short.\nKeine Bauteile in dieser Zone.',ha='center',va='top',linespacing=1.7)
    side.set(xlim=(-3,36),ylim=(-28,10));side.axis('off')
    side.set_title('(b) Schnitt durch die Zuleitung',loc='left',pad=15)
    fig.tight_layout(); fig.savefig(figdir/'pcb-ifa-prinzip.svg');plt.close(fig)
    fig,ax=plt.subplots(figsize=(9,3))
    ax.plot([.5,2,2.7],[2,2,2],color='black',lw=1.5)
    # Vier Bögen als eindeutiges Spulensymbol.
    for k in range(4):
        ax.add_patch(Arc((2.9+.4*k,2),.4,.55,theta1=0,theta2=180,lw=1.5))
    ax.text(3.5,2.65,'L = 0,9784 nH',ha='center')
    ax.plot([4.3,6.5,6.5],[2,2,1.6],color='black',lw=1.5)
    ax.add_patch(Rectangle((6.2,.7),.6,.9,fill=False,lw=1.5))
    ax.text(7,1.1,r'$Z_A = (25 + j10)\,\Omega$',va='center')
    ax.plot([6.5,6.5],[.7,.4],color='black')
    ax.plot([2,2],[2,1.4],color='black')
    ax.plot([1.7,2.3],[1.4,1.4],color='black',lw=1.5)
    ax.plot([1.7,2.3],[1.2,1.2],color='black',lw=1.5)
    ax.plot([2,2],[1.2,.4],color='black')
    ax.text(1.45,.9,'C = 1,3045 pF',ha='right')
    for x in [2,6.5]:
        for y,w in [(.4,.55),(.27,.35),(.14,.15)]:
            ax.plot([x-w/2,x+w/2],[y,y],color='black')
    ax.add_patch(Circle((2,2),.055,color='black'))
    ax.text(.5,2.45,'Eingang\n50 Ω',ha='center')
    ax.text(4.5,-.3,'Ideales Netzwerk bei 2,44 GHz; keine gemessene Antennenlast',ha='center',fontsize=10)
    ax.set(xlim=(-.3,9.3),ylim=(-.55,3));ax.axis('off');fig.tight_layout()
    fig.savefig(figdir/'pcb-lc-anpassung.svg');plt.close(fig)
    print(json.dumps(values,indent=2,ensure_ascii=False))

if __name__ == '__main__':
    main()
