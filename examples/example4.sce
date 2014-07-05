p=[-2 -1 0 2];
sci2oct('polyout',p,'x')
x=[2 4 6]
y=sci2oct('polyval(p,x)')
q=[1 2 9 8 2]
r=sci2oct('conv(p,q)')
r=sci2oct('polyder(p)')
r=sci2oct('polyint(p)')
