%11a plots

%% xres
neff_TE=importdata("convergence_sweeps\neff_TE_sweep_xres.txt");
neff_TE=neff_TE.data;
neff_TM=importdata("convergence_sweeps\neff_TM_sweep_xres.txt");
neff_TM=neff_TM.data;
xres=importdata("convergence_sweeps\xres.txt");
xres=xres.data;

dn_TE=abs(diff(neff_TE));
dn_TM=abs(diff(neff_TM));
xres=xres(1:end-1);

plot(xres,dn_TE,'LineWidth',3);
x=[xres(1),xres(end)];
y=[0.001,0.001]
hold on
plot(xres,dn_TM,'LineWidth',3);
plot(x,y,'k--',"LineWidth",2);

xlabel("dx [\mu m]","FontSize",15)
ylabel("|\Delta n|","FontSize",15)
grid on
legend("TE","TM","0.001",fontsize=14)

%% yres
neff_TE=importdata("convergence_sweeps\neff_TE_sweep_yres.txt");
neff_TE=neff_TE.data;
neff_TM=importdata("convergence_sweeps\neff_TM_sweep_yres.txt");
neff_TM=neff_TM.data;
xres=importdata("convergence_sweeps\yres.txt");
xres=xres.data;

dn_TE=abs(diff(neff_TE));
dn_TM=abs(diff(neff_TM));
xres=xres(1:end-1);

plot(xres,dn_TE,'LineWidth',3);
x=[xres(1),xres(end)];
y=[0.001,0.001]
hold on
plot(xres,dn_TM,'LineWidth',3);
plot(x,y,'k--',"LineWidth",2);

xlabel("dy [\mu m]","FontSize",15)
ylabel("|\Delta n|","FontSize",15)
grid on
legend("TE","TM","0.001",fontsize=14)

%% xspan

neff_TE=importdata("convergence_sweeps\neff_TE_sweep_xspan.txt");
neff_TE=neff_TE.data;
neff_TM=importdata("convergence_sweeps\neff_TM_sweep_xspan.txt");
neff_TM=neff_TM.data;
xres=importdata("convergence_sweeps\xspan.txt");
xres=xres.data;

neff_TE=neff_TE(1:end);
neff_TM=neff_TM(1:end);

xres=xres(1:end);


dn_TE=abs(diff(neff_TE));
dn_TM=abs(diff(neff_TM));
xres=xres(2:end);

plot(xres,dn_TE,'LineWidth',3);
x=[xres(1),xres(end)];
y=[0.001,0.001]
hold on
plot(xres,dn_TM,'LineWidth',3);
plot(x,y,'k--',"LineWidth",2);

xlabel("xspan [\mu m]","FontSize",15)
ylabel("|\Delta n|","FontSize",15)
grid on
legend("TE","TM","0.001",fontsize=14)

%% yspan

neff_TE=importdata("convergence_sweeps\neff_TE_sweep_yspan.txt");
neff_TE=neff_TE.data;
neff_TM=importdata("convergence_sweeps\neff_TM_sweep_yspan.txt");
neff_TM=neff_TM.data;
xres=importdata("convergence_sweeps\yspan.txt");
xres=xres.data;

neff_TE=neff_TE(1:end);
neff_TM=neff_TM(1:end);
xres=xres(1:end);


dn_TE=abs(diff(neff_TE));
dn_TM=abs(diff(neff_TM));
xres=xres(2:end);

plot(xres,dn_TE,'LineWidth',3);
x=[xres(1),xres(end)];
y=[0.001,0.001]
hold on
plot(xres,dn_TM,'LineWidth',3);
plot(x,y,'k--',"LineWidth",2);

xlabel("yspan [\mu m]","FontSize",15)
ylabel("|\Delta n|","FontSize",15)
grid on
legend("TE","TM","0.001",fontsize=14)

%% Plot w vs neff
nmodes=importdata("width/nmodes_geo.txt");
nmodes=nmodes.data
width=importdata("width/neff_Geow.txt");
width=width.data


plot(width,nmodes,"*",LineWidth=3);
hold on

xlabel("Waveguide width [\mu m]","FontSize",15)
ylabel("Number of modes","FontSize",15)
grid on

