%
clear all
%Estimating risk-neutral default probabilites from CDS
%set to 1 to test changes to file.  Takes too long otherwise.
test=0;

%ESTIMATE OF PV LOSS
%GDP_VAR ESTIMATE
pvest=9.792;
%gdp_con1y ESTIMATE
pvest_con=4.262;
rho=.99552436;

%*Forecast figures
%assignin('base','dir_user','C:/Users/Benjamin/Dropbox')
%assignin('base','dir_user','/Users/bhebert/Dropbox')
assignin('base','dir_user','/Users/jesseschreger/Dropbox/')
assignin('base','fname',[dir_user 'Cost of Sovereign Default/ResultsForSlides'])

lambda=.1;
PVL=@(beta,delta) (log(1-delta)*(1-beta)/(1-beta*(1-lambda)))*100
PVG=@(beta,delta) (log(1-delta)*(1/(1-beta+beta*lambda)))*100

PVL(.8,.02)
PVG(.8,.02)

beta_list=[.7,.75,.8,.85,.9,.95,.976,.98,.99];
delta_list=[.001,.005,.01,.015,.02,.025,.03];
nb=length(beta_list);
nd=length(delta_list);
for i=1:nb
    for j=1:nd
    PVLmat(i,j)=PVL(beta_list(i),delta_list(j));
    PVGmat(i,j)=PVG(beta_list(i),delta_list(j));
    end
end

lambda=.01
PVL=@(beta,delta) (log(1-delta)*(1-beta)/(1-beta*(1-lambda)))*100
PVG=@(beta,delta) (log(1-delta)*(1/(1-beta+beta*lambda)))*100

beta_list=[.7,.75,.8,.85,.9,.95,.976,.98,.99];
delta_list=[.001,.005,.01,.015,.02,.025,.03];
nb=length(beta_list);
nd=length(delta_list);
for i=1:nb
    for j=1:nd
    PVLmat(i,j)=PVL(beta_list(i),delta_list(j));
    PVGmat(i,j)=PVG(beta_list(i),delta_list(j));
    end
end




%NOW let's show the output path
%AG
t=15;
deft=6;
Gammat=.02;
Gammat0=0;

red=11;
delta=.03;
y_repay=ones(t,1);
y_default=y_repay;
y_repay0=ones(t,1);
y_default0=y_repay;
for i=2:t
    y_repay(i)=y_repay(i-1)*(1+Gammat)
    y_default(i)=y_default(i-1)*(1+Gammat)
    y_repay0(i)=y_repay0(i-1)*(1+Gammat0)
    y_default0(i)=y_default0(i-1)*(1+Gammat0)
end
for i=deft:red-1
    y_default(i)=y_default(i)*(1-delta)
    y_default0(i)=y_default0(i)*(1-delta)
end




%alt default cost
deltag=.01
y_defg=y_repay;
y_defg0=y_repay0;

for i=1:deft-1
    y_defg(i)=y_repay(i)
    y_defg0(i)=y_repay0(i)
end

for i=deft:red-1
    y_defg(i)=y_defg(i-1)*(1+Gammat)*(1-deltag);
    y_defg0(i)=y_defg0(i-1)*(1+Gammat0)*(1-deltag);
end

for i=red:t
    y_defg(i)=y_defg(i-1)*(1+Gammat);
    y_defg0(i)=y_defg0(i-1)*(1+Gammat0);
end

for i=2:t
    g_repay(i)=(log(y_repay(i))-log(y_repay(i-1)))*100
    g_default(i)=(log(y_default(i))-log(y_default(i-1)))*100
    g_defg(i)=(log(y_defg(i))-log(y_defg(i-1)))*100
    g_defg0(i)=(log(y_defg0(i))-log(y_defg0(i-1)))*100
end

close all
figure(1)
plot(1:t,y_repay(1:t),'LineWidth',3)
hold on
plot(1:t, y_default(1:t),'LineWidth',3)
plot(1:t, y_defg(1:t),'LineWidth',3)
h_legend=legend('Repay','Default, Level','Default, Growth')
set(h_legend,'fontsize',14,'Location','Northwest')
title('Output Level','FontSize',16)
xlabel('Time Period','fontsize',16)
ylabel('Y','fontsize',16)
h=figure(1)
saveas(h,fullfile(fname,'output'),'png')

figure(2)
plot(1:t,g_repay(1:t),'LineWidth',3)
hold on
plot(1:t, g_default(1:t),'LineWidth',3)
plot(1:t, g_defg(1:t),'LineWidth',3)
 h_legend=legend('Repay','Default, Level','Default, Growth')
set(h_legend,'fontsize',14,'Location','Northwest')
title('Growth Rate','FontSize',16)
xlabel('Time Period','fontsize',16)
ylabel('g','fontsize',16)
h=figure(2)
saveas(h,fullfile(fname,'growth_rate'),'png')

%LEVEL FIGURE
figure(3)
h=figure(3)
hax=axes;
plot(1:t, y_repay,'r','LineWidth',3)
hold on
h_legend=legend('Repay')
set(h_legend,'fontsize',14,'Location','Northwest')
%title('xxx','fontsize',16)
xlabel('Period','fontsize',16)
ylabel('Output','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
axis([1 15 1 1.4])
h=figure(3)
saveas(h,fullfile(fname,'level_fig1'),'png')
%axis([1 15 .9 1.05])
scatter(1:t, y_default(1:t),'b','LineWidth',3)
h_legend=legend('Repay','Default-Level')
set(h_legend,'fontsize',14,'Location','Northwest')
redmin1=red-1;
plot([deft deft],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
plot([redmin1 redmin1],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
saveas(h,fullfile(fname,'level_fig2'),'png')


%Level Figure with default 
figure(4)
hax=axes;
plot(1:t, y_repay,'r','LineWidth',3)
hold on
xlabel('Period','fontsize',16)
ylabel('Output','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
axis([1 15 1 1.4])
%axis([1 15 .9 1.05])
scatter(1:t, y_default(1:t),'b','LineWidth',3)
redmin1=red-1;
scatter(1:t, y_defg(1:t),'MarkerEdgeColor',[0 .5 0],'MarkerFaceColor',[0 .5 0],'LineWidth',3)
plot([deft deft],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
plot([redmin1 redmin1],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
h_legend=legend('Repay','Default-Level','Default-Growth Rate')
set(h_legend,'fontsize',14,'Location','Northwest')
h=figure(4)
saveas(h,fullfile(fname,'level_fig3'),'png')


figure(5)
h=figure(5)
hax=axes;
plot(1:t, y_repay0,'r','LineWidth',3)
hold on
h_legend=legend('Repay')
set(h_legend,'fontsize',14,'Location','Northwest')
%title('xxx','fontsize',16)
xlabel('Period','fontsize',16)
ylabel('Output','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
%axis([1 15 1 1.4])
axis([1 15 .9 1.05])
h=figure(5)
saveas(h,fullfile(fname,'level0_fig1'),'png')
scatter(1:t, y_default0(1:t),'b','LineWidth',3)
h_legend=legend('Repay','Default-Level')
set(h_legend,'fontsize',14,'Location','Northwest')
redmin1=red-1;
plot([deft deft],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
plot([redmin1 redmin1],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
h=figure(5)
saveas(h,fullfile(fname,'level0_fig2'),'png')

%with def
figure(6)
h=figure(6)
hax=axes;
plot(1:t, y_repay0,'r','LineWidth',3)
hold on
h_legend=legend('Repay')
set(h_legend,'fontsize',14,'Location','Northwest')
%title('xxx','fontsize',16)
xlabel('Period','fontsize',16)
ylabel('Output','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
%axis([1 15 1 1.4])
axis([1 15 .9 1.05])
scatter(1:t, y_default0(1:t),'b','LineWidth',3)
h_legend=legend('Repay','Default-Level')
set(h_legend,'fontsize',14,'Location','Northwest')
redmin1=red-1;
scatter(1:t, y_defg0(1:t),'MarkerEdgeColor',[0 .5 0],'MarkerFaceColor',[0 .5 0],'LineWidth',3)
h_legend=legend('Repay','Default-Level','Default-Growth Rate')
set(h_legend,'fontsize',14,'Location','Northwest')
plot([deft deft],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
plot([redmin1 redmin1],get(hax,'Ylim'),'LineWidth',1.5,'Color',[0 0 0],'LineStyle',':')
h=figure(6)
saveas(h,fullfile(fname,'level0_fig3'),'png')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output Costs: Level or Growth Rate%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PVL=@(beta,delta,lambda) (log(1-delta)*(1-beta)/(1-beta*(1-lambda)))*100
deltafun=@(PV,beta,lambda) PV*(1-beta*(1-lambda))/(1-beta);
deltagfun=@(PV,beta,lambda) PV*(1-beta+beta*lambda);

%ANNUALIZED
lambda_vec=linspace(.0667,.9)';
delta_vec=ones(size(lambda_vec));
beta=rho^4;

for i=1:length(lambda_vec)
    delta_vec_var(i)=deltafun(pvest,beta,lambda_vec(i));
    deltag_vec_var(i)=deltagfun(pvest,beta,lambda_vec(i));
    delta_vec_con(i)=deltafun(pvest_con,beta,lambda_vec(i));
    deltag_vec_con(i)=deltagfun(pvest_con,beta,lambda_vec(i));
end

figure(12)
hold all
plot(1./lambda_vec, delta_vec_var,'linewidth',3)
plot(1./lambda_vec, delta_vec_con,'linewidth',3)
h_legend=legend('VAR','Survey')
set(h_legend,'fontsize',14,'Location','Northeast')
xlabel('Mean Duration (Years)','fontsize',16)
ylabel('\delta_L','fontsize',22)
title('Level','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
h=figure(12)
saveas(h,fullfile(fname,'DefaultL_Cost_Params_est'),'png')


figure(13)
hold all
plot(1./lambda_vec, deltag_vec_var,'linewidth',3)
plot(1./lambda_vec, deltag_vec_con,'linewidth',3)
h_legend=legend('VAR','Survey')
set(h_legend,'fontsize',14,'Location','Northeast')
xlabel('Mean Duration (Years)','fontsize',16)
ylabel('\delta_g','fontsize',22)
title('Growth Rate','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
h=figure(13)
saveas(h,fullfile(fname,'Defaultg_Cost_Params_est'),'png')





%%%%%%%%%%%%%%%%%%%%
%IMPULSE RESPONSES
%%%%%%%%%%%%%%%%%%%
lambda=1/2.5;
deltaL=(pvest/((1-beta)/(1-beta*(1-lambda))))/100
deltaL_con=(pvest_con/((1-beta)/(1-beta*(1-lambda))))/100
deltag=(pvest/(1/(1-beta*(1-lambda))))/100
deltag_con=(pvest_con/(1/(1-beta*(1-lambda))))/100
period=[0,1,2,3,4,5];
dy_level=NaN(length(period),1);
dy_level(1)=-deltaL;
dy_grow(1)=-deltag;
y_level(1)=exp(dy_level(1));
y_grow(1)=exp(dy_grow(1))

dy_level_con=NaN(length(period),1);
dy_level_con(1)=-deltaL_con;
dy_grow_con(1)=-deltag_con;
y_level_con(1)=exp(dy_level_con(1));
y_grow_con(1)=exp(dy_grow_con(1))
for i=2:length(period)
    dy_level(i)=deltaL*lambda*(1-lambda)^(i-2);
    y_level(i)=y_level(i-1)*exp(dy_level(i));
    dy_grow(i)=-deltag*(1-lambda)^(i-1);
    y_grow(i)=y_grow(i-1)*exp(dy_grow(i));
    dy_level_con(i)=deltaL_con*lambda*(1-lambda)^(i-2);
    y_level_con(i)=y_level_con(i-1)*exp(dy_level_con(i));
    dy_grow_con(i)=-deltag_con*(1-lambda)^(i-1);
    y_grow_con(i)=y_grow_con(i-1)*exp(dy_grow_con(i));    
end

y_level=(y_level-1)*100;
y_grow=(y_grow-1)*100;
dy_level=(dy_level)*100;
dy_grow=(dy_grow)*100;

y_level_con=(y_level_con-1)*100;
y_grow_con=(y_grow_con-1)*100;
dy_level_con=(dy_level_con)*100;
dy_grow_con=(dy_grow_con)*100;

figure(14)
hold all
plot(period,y_level,'linewidth',3)
plot(period,y_grow,'linewidth',3)
plot(period,y_level_con,'linewidth',3)
plot(period,y_grow_con,'linewidth',3)
h_legend=legend('\delta_L - VAR','\delta_g - VAR', '\delta_L - Survey','\delta_g - Survey')
set(h_legend,'fontsize',16,'Location','Southeast')
xlabel('Year','fontsize',16)
ylabel('Percent','fontsize',22)
title('GDP Level','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
h=figure(14)
saveas(h,fullfile(fname,'IRF_level'),'png')


figure(15)
hold all
plot(period,dy_level,'linewidth',3)
plot(period,dy_level_con,'linewidth',3)
h_legend=legend('\delta_L - VAR', '\delta_L - Survey')
set(h_legend,'fontsize',16,'Location','Northeast')
xlabel('Year','fontsize',16)
ylabel('Percent','fontsize',22)
title('GDP Growth Rate','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
h=figure(15)
saveas(h,fullfile(fname,'IRF_growth_L'),'png')

figure(16)
hold all
plot(period, dy_grow,'linewidth',3)
plot(period, dy_grow_con,'linewidth',3)
h_legend=legend('\delta_g - VAR', '\delta_g - Survey')
set(h_legend,'fontsize',16,'Location','Southeast')
xlabel('Year','fontsize',16)
ylabel('Percent','fontsize',22)
title('GDP Growth Rate','fontsize',16)
set(gca,'FontSize',16)
set(gca,'FontSize',16)
h=figure(16)
saveas(h,fullfile(fname,'IRF_growth_g'),'png')

% %%%%%%%%%%%%
% %PLOTTING PV
% %%%%%%%%%%%%%
% figure(7)
% hax=axes;
% deltaPV=@(PV) deltafun(PV,(10/11)^(1/4),.1)
% fplot(deltaPV,[0,8])
% hold all
% deltaPV=@(PV) deltafun(PV,(10/11)^(1/4),.0357)
% fplot(deltaPV,[0,8])
% deltaPV=@(PV) deltafun(PV,(10/11)^(1/4),.01)
% fplot(deltaPV,[0,8])
% set(findall(gca, 'Type', 'Line'),'LineWidth',3)
% xlabel('\Delta PV','fontsize',16)
% ylabel('\delta','fontsize',16)
% set(gca,'FontSize',16)
% set(gca,'FontSize',16)
% plot([pvest pvest],get(hax,'Ylim'),'LineWidth',2,'Color',[0 0 0],'LineStyle',':')
% h_legend=legend('Duration=2.5 years','Duration=7 years','Duration=25 years')
% set(h_legend,'fontsize',14,'Location','Northwest')
% h=figure(7)
% saveas(h,fullfile(fname,'Delta_crit'),'png')

%
% figure(8)
% hax=axes;
% deltaPV=@(PV) deltagfun(PV,(10/11)^(1/4),.1)
% fplot(deltaPV,[0,8])
% hold all
% deltaPV=@(PV) deltagfun(PV,(10/11)^(1/4),.0357)
% fplot(deltaPV,[0,8])
% deltaPV=@(PV) deltagfun(PV,(10/11)^(1/4),.01)
% fplot(deltaPV,[0,8])
% set(findall(gca, 'Type', 'Line'),'LineWidth',3)
% xlabel('\Delta PV','fontsize',16)
% ylabel('\delta','fontsize',16)
% set(gca,'FontSize',16)
% set(gca,'FontSize',16)
% plot([pvest pvest],get(hax,'Ylim'),'LineWidth',2,'Color',[0 0 0],'LineStyle',':')
% h_legend=legend('Duration=2.5 years','Duration=7 years','Duration=25 years')
% set(h_legend,'fontsize',14,'Location','Northwest')
% h=figure(8)
% saveas(h,fullfile(fname,'Deltag_crit'),'png')



% figure(9)
% hax=axes;
% deltaPV=@(PV) deltagfun(PV,(10/11),1/2.5)
% fplot(deltaPV,[0,8])
% hold all
% deltaPV=@(PV) deltagfun(PV,(10/11),1/7)
% fplot(deltaPV,[0,8])
% deltaPV=@(PV) deltagfun(PV,(10/11),1/25)
% fplot(deltaPV,[0,8])
% set(findall(gca, 'Type', 'Line'),'LineWidth',3)
% xlabel('\Delta PV','fontsize',16)
% ylabel('\delta','fontsize',16)
% set(gca,'FontSize',16)
% set(gca,'FontSize',16)
% plot([pvest pvest],get(hax,'Ylim'),'LineWidth',2,'Color',[0 0 0],'LineStyle',':')
% h_legend=legend('Duration=2.5 years','Duration=7 years','Duration=25 years')
% set(h_legend,'fontsize',14,'Location','Northwest')
% h=figure(9)
% saveas(h,fullfile(fname,'Deltag_crit_annual'),'png')
% axis([0 8 0 40])
% plot([pvest pvest],get(hax,'Ylim'),'LineWidth',2,'Color',[0 0 0],'LineStyle',':')
% saveas(h,fullfile(fname,'Deltag_crit_annual_altaxis'),'png')

% 
% figure(10)
% hax=axes;
% deltaPV=@(PV) deltafun(PV,(10/11),1/2.5)
% fplot(deltaPV,[0,8])
% hold all
% deltaPV=@(PV) deltafun(PV,(10/11),1/7)
% fplot(deltaPV,[0,8])
% deltaPV=@(PV) deltafun(PV,(10/11),1/25)
% fplot(deltaPV,[0,8])
% set(findall(gca, 'Type', 'Line'),'LineWidth',3)
% xlabel('\Delta PV','fontsize',16)
% ylabel('\delta','fontsize',16)
% set(gca,'FontSize',16)
% set(gca,'FontSize',16)
% plot([pvest pvest],get(hax,'Ylim'),'LineWidth',2,'Color',[0 0 0],'LineStyle',':')
% h_legend=legend('Duration=2.5 years','Duration=7 years','Duration=25 years')
% set(h_legend,'fontsize',14,'Location','Northwest')
% h=figure(10)
%saveas(h,fullfile(fname,'Delta_crit_annual'),'png')




