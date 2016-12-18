%Estimating risk-neutral default probabilites from CDS
%set to 1 to test changes to file.  Takes too long otherwise.

if user==1
assignin('base','dir_user','/Users/jschreger/Dropbox/')
assignin('base','dir_csd','/Users/jschreger/Documents/CostofSovereignDefault')
elseif user==2
assignin('base','dir_user','/Users/bhebert/Dropbox')
assignin('base','dir_csd','/Users/bhebert/CostOfSovereignDefault')
end

assignin('base','apath',[dir_csd '/Datasets/'])
assignin('base','pod',[dir_user 'Cost of Sovereign Default/Markit/Prob of Default/'])
assignin('base','csvfile',[apath 'Matlab_spreads_zero.csv'])
assignin('base','csvfile_ust',[apath 'Matlab_spreads_zero_UST.csv'])
assignin('base','csvfile_june16',[apath 'Matlab_June16.csv'])
assignin('base','csvfile_europe',[apath 'Matlab_Europe_zero.csv'])
assignin('base','csvfile_newyork',[apath 'Matlab_NewYork_zero.csv'])
assignin('base','csvfile_london',[apath 'Matlab_London_zero.csv'])
assignin('base','csvfile_londonmidday',[apath 'Matlab_LondonMidday_zero.csv'])
assignin('base','csvfile_asia',[apath 'Matlab_Asia_zero.csv'])
assignin('base','csvfile_japan',[apath 'Matlab_Japan_zero.csv'])
assignin('base','csvfile_ust_europe',[apath 'Matlab_Europe_spreads_zero_UST.csv'])
assignin('base','csvfile_ust_newyork',[apath 'Matlab_NewYork_spreads_zero_UST.csv'])
assignin('base','csvfile_ust_london',[apath 'Matlab_London_spreads_zero_UST.csv'])
assignin('base','csvfile_ust_londonmidday',[apath 'Matlab_LondonMidday_spreads_zero_UST.csv'])
assignin('base','csvfile_ust_asia',[apath 'Matlab_Asia_spreads_zero_UST.csv'])
assignin('base','csvfile_ust_japan',[apath 'Matlab_Japan_spreads_zero_UST.csv'])
assignin('base','csvfile_bb',[apath 'Matlab_BBspreads_zero_UST.csv'])
assignin('base','csvfile_ds',[apath 'Matlab_DSspreads_zero_UST.csv'])


%COMPOSITE
 delete(gcp)
 parpool
for i=1:7
    if i==1
       dataset=csvread(csvfile);
    elseif i==2
        dataset=csvread(csvfile_europe);
    elseif i==3
        dataset=csvread(csvfile_newyork);    
    elseif i==4
        dataset=csvread(csvfile_london);    
    elseif i==5
        dataset=csvread(csvfile_londonmidday);
    elseif i==6
        dataset=csvread(csvfile_asia);    
    elseif i==7
        dataset=csvread(csvfile_japan);    
    end    
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

parfor xx=1:length(date)
    Settle=date(xx);
    Spread_Time=spread_length;
    Spread=100*parspreads(xx,:);
    Market_Dates=daysadd(date(xx),round(365.*spread_length)); %maturity dates of all CDS
    MarketData=[Market_Dates, Spread'];
    Zero_Time=[spread_length]';
    Zero_Rate=irs(xx,:)'/100;
    Zero_Dates=daysadd(date(xx),round(365.*irs_length)); %maturity dates of discount curve
    ZeroData=[Zero_Dates Zero_Rate];
    [ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recovery(xx));
    %assume constant hazard rate of 39.5%
    [ProbDataConH,HazDataConH] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recoveryConH(xx));
    ProbDef_mat(xx,:)=ProbData(:,2)';
    Haz_mat(xx,:)=HazData(:,2)';
    
    ProbDef_matConH(xx,:)=ProbDataConH(:,2)';
    Haz_matConH(xx,:)=HazDataConH(:,2)';
    if mod(xx,10)==0
        display xx
    end
end


% savefile=[mpath 'Bootstrap_results.mat'];
% save(savefile,'ProbDef_mat','Haz_mat','date','date_id','dataset')
% savefile=[mpath 'Bootstrap_resultsconH.mat'];
% save(savefile,'ProbDef_matConH','Haz_matConH','date','date_id','dataset')
date_stata=date-715876;
keymat=[date_stata,ProbDef_mat,Haz_mat];
keymatConH=[date_stata,ProbDef_matConH,Haz_matConH];

cd(apath)
if i==1
	csvwrite('Bootstrap_results.csv',keymat)
	csvwrite('Bootstrap_resultsConH.csv',keymatConH)
elseif i==2
    csvwrite('Bootstrap_Europe_results.csv',keymat)
    csvwrite('Bootstrap_Europe_resultsConH.csv',keymatConH)
elseif i==3
    csvwrite('Bootstrap_NewYork_results.csv',keymat)
    csvwrite('Bootstrap_NewYork_resultsConH.csv',keymatConH)
elseif i==4
    csvwrite('Bootstrap_London_results.csv',keymat)
    csvwrite('Bootstrap_London_resultsConH.csv',keymatConH) 
elseif i==5
    csvwrite('Bootstrap_LondonMidday_results.csv',keymat)
    csvwrite('Bootstrap_LondonMidday_resultsConH.csv',keymatConH)
elseif i==6
    csvwrite('Bootstrap_Asia_results.csv',keymat)
    csvwrite('Bootstrap_Asia_resultsConH.csv',keymatConH)
elseif i==7
    csvwrite('Bootstrap_Japan_results.csv',keymat)
    csvwrite('Bootstrap_Japan_resultsConH.csv',keymatConH)     
end
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%USING US Treasury Zeros to discount.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Estimating risk-neutral default probabilites from CDS
%COMPOSITE
for i=1:7
    if i==1
       dataset=csvread(csvfile_ust);
    elseif i==2
        dataset=csvread(csvfile_ust_europe);
    elseif i==3
        dataset=csvread(csvfile_ust_newyork);    
    elseif i==4
        dataset=csvread(csvfile_ust_london); 
    elseif i==5
        dataset=csvread(csvfile_ust_londonmidday);
    elseif i==6
        dataset=csvread(csvfile_ust_asia);    
    elseif i==7
        dataset=csvread(csvfile_ust_japan); 
    end
    
if test==1 
    dataset=dataset(700:710,:);
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
parfor xx=1:length(date)
    Settle=date(xx);
    Spread_Time=spread_length;
    Spread=100*parspreads(xx,:);
    Market_Dates=daysadd(date(xx),round(365.*spread_length)); %maturity dates of all CDS
    MarketData=[Market_Dates, Spread'];
    Zero_Time=[spread_length]';
    Zero_Rate=irs(xx,:)'/100;
    Zero_Dates=daysadd(date(xx),round(365.*irs_length)); %maturity dates of discount curve
    ZeroData=[Zero_Dates Zero_Rate];
    [ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recovery(xx));
    %assume constant hazard rate of 39.5%
    [ProbDataConH,HazDataConH] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recoveryConH(xx));
    ProbDef_mat(xx,:)=ProbData(:,2)';
    Haz_mat(xx,:)=HazData(:,2)';
    
    ProbDef_matConH(xx,:)=ProbDataConH(:,2)';
    Haz_matConH(xx,:)=HazDataConH(:,2)';
    if mod(xx,10)==0
        display xx
    end
end


%savefile=[mpath 'Bootstrap_results_UST.mat'];
%save(savefile,'ProbDef_mat','Haz_mat','date','date_id','dataset')
%savefile=[mpath 'Bootstrap_results_UST.mat'];
%save(savefile,'ProbDef_matConH','Haz_matConH','date','date_id','dataset')
date_stata=date-715876;
keymat=[date_stata,ProbDef_mat,Haz_mat];
keymatConH=[date_stata,ProbDef_matConH,Haz_matConH];

cd(apath)
if i==1
csvwrite('Bootstrap_results_UST.csv',keymat)
csvwrite('Bootstrap_resultsConH_UST.csv',keymatConH)
elseif i==2
   csvwrite('Bootstrap_Europe_results_UST.csv',keymat)
    csvwrite('Bootstrap_Europe_resultsConH_UST.csv',keymatConH)
elseif i==3
     csvwrite('Bootstrap_NewYork_results_UST.csv',keymat)
     csvwrite('Bootstrap_NewYork_resultsConH_UST.csv',keymatConH)
elseif i==4
     csvwrite('Bootstrap_London_results_UST.csv',keymat)
     csvwrite('Bootstrap_London_resultsConH_UST.csv',keymatConH)
elseif i==5
   csvwrite('Bootstrap_LondonMidday_results_UST.csv',keymat)
    csvwrite('Bootstrap_LondonMidday_resultsConH_UST.csv',keymatConH)
elseif i==6
     csvwrite('Bootstrap_Asia_results_UST.csv',keymat)
     csvwrite('Bootstrap_Asia_resultsConH_UST.csv',keymatConH)
elseif i==7
     csvwrite('Bootstrap_Japan_results_UST.csv',keymat)
     csvwrite('Bootstrap_Japan_resultsConH_UST.csv',keymatConH)     
end

end

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

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%BLOOMBERG and Datastream%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%USING US Treasury Zeros to discount.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear ProbDef_mat Haz_mat ProbDef_matConH Haz_matConH
for i=1:2
    if i==1
       dataset=csvread(csvfile_bb);
    elseif i==2
        dataset=csvread(csvfile_ds);
    elseif i==3
        %dataset=csvread(csvfile_ust_newyork);    
    end
    
if test==1 
    dataset=dataset(700:710,:);
end
date=dataset(:,1);
recovery=dataset(:,2)/100;
parspreads=dataset(:,3:7);
irs=dataset(:,8:12);
date=date+715876; %convert Stata date to Matlab
date_id=datestr(date);
irs_length=linspace(1,5,5); %maturities of interest rate swaps
spread_length=[1,2,3,4,5]; %maturities of CDS
days_to_add=round(365.*irs_length);
recoveryConH=ones(size(recovery))*.395;

%Run code in parallel to spped up
for xx=1:length(date)
    Settle=date(xx);
    Spread_Time=spread_length;
    Spread=100*parspreads(xx,:);
    Market_Dates=daysadd(date(xx),round(365.*spread_length)); %maturity dates of all CDS
    MarketData=[Market_Dates, Spread'];
    Zero_Time=spread_length';
    Zero_Rate=irs(xx,:)'/100;
    Zero_Dates=daysadd(date(xx),round(365.*irs_length)); %maturity dates of discount curve
    ZeroData=[Zero_Dates Zero_Rate];
    [ProbData,HazData] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recovery(xx));
    %assume constant hazard rate of 39.5%
    [ProbDataConH,HazDataConH] = cdsbootstrap(ZeroData,MarketData,Settle,'RecoveryRate',recoveryConH(xx));
    ProbDef_mat(xx,:)=ProbData(:,2)';
    Haz_mat(xx,:)=HazData(:,2)';
    
    ProbDef_matConH(xx,:)=ProbDataConH(:,2)';
    Haz_matConH(xx,:)=HazDataConH(:,2)';
    if mod(xx,10)==0
        display xx
    end
end


%savefile=[mpath 'Bootstrap_results_UST.mat'];
%save(savefile,'ProbDef_mat','Haz_mat','date','date_id','dataset')
%savefile=[mpath 'Bootstrap_results_UST.mat'];
%save(savefile,'ProbDef_matConH','Haz_matConH','date','date_id','dataset')
date_stata=date-715876;
keymat=[date_stata,ProbDef_mat,Haz_mat];
keymatConH=[date_stata,ProbDef_matConH,Haz_matConH];

cd(apath)
if i==1
csvwrite('Bootstrap_results_BBUST.csv',keymat)
csvwrite('Bootstrap_resultsConH_BBUST.csv',keymatConH)
elseif i==2
   csvwrite('Bootstrap_results_DSUST.csv',keymat)
    csvwrite('Bootstrap_resultsConH_DSUST.csv',keymatConH)
elseif i==3
end

end


