%% 

gain25=readtable("gain_25ohm");
gain50=readtable("gain_50ohm");
gain100=readtable("gain_100ohm");

f=table2array(gain25(:,1));

figure()

plot(f,table2array(gain25(:,2)),'-',LineWidth=4)
hold on
plot(f,table2array(gain50(:,2)),'-',LineWidth=4)
plot(f,table2array(gain100(:,2)),'-',LineWidth=4)


xlabel("Frequency [GHz]","FontSize",15)
ylabel("gain [dB]","FontSize",15)
grid on

legends = ["25\Omega" "50\Omega" "100\Omega"]
legend(legends)



setnamed('TW_1','junction capacitance table',C_);






