sci2oct('pkg load control');
sci2oct('s=tf','s');
sci2oct('w0=2*pi*5; ');
sci2oct('w1=2*pi*1e5;');
sci2oct('A0=2e5; ');
sci2oct('A=A0/[(1+s/w0)*(1+s/w1)]')
