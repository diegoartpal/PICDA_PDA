
%% d50
clear all;
data1=importdata("S3.txt");
wavelength=data1.data(:,1);
S3=data1.data(:,2);

data2=importdata("S4.txt");
wavelength2=data2.data(:,1);
S4=data2.data(:,2);

figure()
yyaxis left
plot(wavelength*1e9,S3./S4,'LineWidth',3);
ylabel("|S_{31}|^2|S_{41}|^2 [a.u.]","FontSize",15)
hold on
yyaxis right
plot(wavelength*1e9,S4+S3,'LineWidth',3);
ylabel("Transmission [a.u.]","FontSize",15)

title("L=29.8")

xlabel("Wavelength [nm]","FontSize",15)
grid on

%xlim([1500,1600])

%%

yq = interp1(wavelength*1e9, S4, 1550)
yq = interp1(wavelength*1e9, S3, 1550)

L=3.52e-6;
k = (1/L)*asin(sqrt(0.2425))

L = (1/k)*asin(sqrt(0.1))

beta = 2*pi*2.3/(1.55e-6)

k/beta


%%
clear all;
data1=importdata("S3_2.txt");
wavelength=data1.data(:,1);
S3=data1.data(:,2);

data2=importdata("S4_2.txt");
wavelength2=data2.data(:,1);
S4=data2.data(:,2);

figure()
plot(wavelength*1e9,S3,'LineWidth',3);
hold on

plot(wavelength*1e9,S4,'LineWidth',3);
plot(wavelength*1e9,S4+S3,'LineWidth',3);


xlabel("Wavelength [nm]","FontSize",15)
ylabel("Transmission [a.u.]","FontSize",15)
grid on

legend('|S31|^2','|S41|^2','Total')


