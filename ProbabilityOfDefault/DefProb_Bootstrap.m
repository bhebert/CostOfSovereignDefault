clear all
%Estimating risk-neutral default probabilites from CDS
%set to 1 to test changes to file.  Takes too long otherwise.
test=0


assignin('base','dir_user','/Users/jesseschreger/Dropbox/')
assignin('base','dir_csd','/Users/jesseschreger/Documents/CostofSovereignDefault')
assignin('base','apath',['/Users/jesseschreger/Documents/CostofSovereignDefault/Datasets'])
assignin('base','pod',[dir_user 'Cost of Sovereign Default/Markit/Prob of Default/'])
assignin('base','apath',[dir_csd '/Datasets/'])
assignin('base','csvfile',[apath 'Matlab_spreads_zero.csv'])
assignin('base','csvfile_ust',[apath 'Matlab_spreads_zero_UST.csv'])
assignin('base','csvfile_june16',[apath 'Matlab_June16.csv'])


%COMPOSITE
dataset=csvread(csvfile);
if test==1 
    dataset=dataset(700:710,:);
end
date=dataset(:,1);
recovery=dataset(:,2)/100;
parspreads=dataset(:,3:13);
irs=dataset(:,14:end);
date=date+715876; %convert Stata date to Matlab
date_id=datestr(date);
irs_length=[.5, 1, 3 ,4 ,5 ,7,10,30]; %maturities of interest rate swaps
spread_length=[.5,1,2,3,4,5,7,10,15,20,30]; %maturities of CDS
days_to_add=round(365.*irs_length);
recoveryConH=ones(size(recovery))*.395;

%Run code in parallel to spped up
matlabpool close force local
matlabpool
parfor i=1:length(date)
    Settle=date(i);
    Spread_Time=spread_length;
    Spread=100*parspreads(i,:);
    Market_Dates=daysadd(date(i),round(365.*spread_length)); %maturity dates of all CDS
    MarketData=[Market_Dates, Spread'];
    Zero_Time=[spread_length]';
    Zero_Rate=irs(i,:)'/100;
    Zero_Dates=daysadd(date(i),round(365.*irs_length)); %maturity dates of discount curve
    ZeroData=[Zero_Dates Zero_Rate];
    [ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recovery(i));
    %assume constant hazard rate of 39.5%
    [ProbDataConH,HazDataConH] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recoveryConH(i));
    ProbDef_mat(i,:)=ProbData(:,2)';
    Haz_mat(i,:)=HazData(:,2)';
    
    ProbDef_matConH(i,:)=ProbDataConH(:,2)';
    Haz_matConH(i,:)=HazDataConH(:,2)';
    if mod(i,10)==0
        display i
    end
end


% savefile=[apath 'Bootstrap_results.mat'];
% save(savefile,'ProbDef_mat','Haz_mat','date','date_id','dataset')
% savefile=[apath 'Bootstrap_resultsconH.mat'];
% save(savefile,'ProbDef_matConH','Haz_matConH','date','date_id','dataset')
date_stata=date-715876;
keymat=[date_stata,ProbDef_mat,Haz_mat];
keymatConH=[date_stata,ProbDef_matConH,Haz_matConH];

cd(apath)
csvwrite('Bootstrap_results.csv',keymat)
csvwrite('Bootstrap_resultsConH.csv',keymatConH)




%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%USING US Treasury Zeros to discount.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Estimating risk-neutral default probabilites from CDS
%COMPOSITE
dataset=csvread(csvfile_ust);
if test==1 
    dataset=dataset(700:710,:)
end
date=dataset(:,1);
recovery=dataset(:,2)/100;
parspreads=dataset(:,3:13);
irs=dataset(:,14:end);
date=date+715876; %convert Stata date to Matlab
date_id=datestr(date);
irs_length=linspace(1,30,30); %maturities of interest rate swaps
spread_length=[.5,1,2,3,4,5,7,10,15,20,30]; %maturities of CDS
days_to_add=round(365.*irs_length);
recoveryConH=ones(size(recovery))*.395;

%Run code in parallel to spped up
matlabpool close force local
matlabpool
parfor i=1:length(date)
    Settle=date(i);
    Spread_Time=spread_length;
    Spread=100*parspreads(i,:);
    Market_Dates=daysadd(date(i),round(365.*spread_length)); %maturity dates of all CDS
    MarketData=[Market_Dates, Spread'];
    Zero_Time=[spread_length]';
    Zero_Rate=irs(i,:)'/100;
    Zero_Dates=daysadd(date(i),round(365.*irs_length)); %maturity dates of discount curve
    ZeroData=[Zero_Dates Zero_Rate];
    [ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recovery(i));
    %assume constant hazard rate of 39.5%
    [ProbDataConH,HazDataConH] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recoveryConH(i));
    ProbDef_mat(i,:)=ProbData(:,2)';
    Haz_mat(i,:)=HazData(:,2)';
    
    ProbDef_matConH(i,:)=ProbDataConH(:,2)';
    Haz_matConH(i,:)=HazDataConH(:,2)';
    if mod(i,10)==0
        display i
    end
end


%savefile=[apath 'Bootstrap_results_UST.mat'];
%save(savefile,'ProbDef_mat','Haz_mat','date','date_id','dataset')
%savefile=[apath 'Bootstrap_results_UST.mat'];
%save(savefile,'ProbDef_matConH','Haz_matConH','date','date_id','dataset')
date_stata=date-715876;
keymat=[date_stata,ProbDef_mat,Haz_mat];
keymatConH=[date_stata,ProbDef_matConH,Haz_matConH];

cd(apath)
csvwrite('Bootstrap_results_UST.csv',keymat)
csvwrite('Bootstrap_resultsConH_UST.csv',keymatConH)

%%
%%%%%%%%%
%JUNE 16%
%%%%%%%%%
clear ProbDef_mat Haz_mat
%Estimating risk-neutral default probabilites from CDS
dataset=csvread(csvfile_june16);
date=dataset(:,1);
recovery=dataset(:,2)/100;
parspreads=dataset(:,3:13);
irs=dataset(:,14:end-1);
time_est=dataset(:,end);
%we want first date to display jan 3 2011
irs_length=[.5, 1, 3 ,4 ,5 ,7,10,30];
spread_length=[.5,1,2,3,4,5,7,10,15,20,30];
days_to_add=round(365.*irs_length);

%NOT USING THE BOOTSTRAPPED ZEROS
for i=1:length(date)
    Settle=date(i);
    Spread_Time=spread_length;
    Spread=100*parspreads(i,:);
    Market_Dates=daysadd(date(i),round(365.*spread_length));
    MarketData=[Market_Dates, Spread'];
    Zero_Time=[spread_length]';
    Zero_Rate=irs(i,:)'/100;
    Zero_Dates=daysadd(date(i),round(365.*irs_length));
    ZeroData=[Zero_Dates Zero_Rate];
    [ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recovery(i));
    ProbDef_mat(i,:)=ProbData(:,2)';
    Haz_mat(i,:)=HazData(:,2)';
end

keymat=[date,ProbDef_mat,Haz_mat,time_est];
cd(apath)
csvwrite('Bootstrap_June16.csv',keymat)


