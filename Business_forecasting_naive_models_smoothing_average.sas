libname bsta477 "D:\sas_code\r\DMBA-R-datasets";

*NAIVE FORECASTING - SIMPLE NAIVE;
data naive; *creating a new dataset;
set bsta477.AMTRAK_DATA_TR; *using the existing dataset;
Forecast = lag(Ridership); *forecast at a lag of 1;
Abs=abs(Ridership-Forecast); *adding variables for error calculations;
Diff=Ridership-Forecast;
Diff2=Diff**2;
Div_Abs=Abs/Ridership;
Div_Reg=Diff/Ridership;
run;

*Creating a dataset with only one value;
data x (keep =Forecast); *creating a new set;
set naive; *using the existing dataset;
where Date="01Mar01"d; *adding a subsetting condition;
run;

*Add the value from the previous dataset to the validation set;
data naive_valid; *creating a validation dataset with forecasts;
set bsta477.amtrak_data_v; *using the existing dataset;
if _n_=1 then set x; *calling on the dataset with only one value to be replicated later;
Abs=abs(Ridership-Forecast); *adding variables for error calculations;
Diff=Ridership-Forecast;
Diff2=Diff**2;
Div_Abs=Abs/Ridership;
Div_Reg=Diff/Ridership;
run;

/*ERROR TERMS*/
/*MAD=(sum|Actual - Forecast|)/n
MSE=(sum(Actual-Forecast)^2/n)
RMSE=Square root of MSE
MAPE=100%*(sum(|Actual-Forecast|/Actual))/n
MPE=100%*(sum((Actual-Forecast)/Actual)/n)*/

*CALCULATING TRAIN ERRORS;
proc means data=naive noprint; *running proc means to summarize variables;
vars Abs Diff2 Div_Abs Div_Reg;
output out=sum_naive_tr sum= / autoname; *sum= makes sure we will get a sum;
run;

data naive_fc_err;
set naive;
if _n_=1 then set sum_naive_tr;
n=_freq_-1;
	MAD=Abs_Sum/n;
	MSE=Diff2_Sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_Sum/n;
	MPE=Div_Reg_Sum/n;
	format MAPE MPE percent10.2;
run;

data ntr_err (keep=n	MAD	MSE	RMSE	MAPE	MPE);
set naive_fc_err;
where Date="01Jan1991"d;
run;


*CALCULATING NAIVE ERRORS - VALIDATION;
proc means data=naive_valid noprint;
vars Abs Diff2 Div_Abs Div_Reg;
output out=sum_naive_vd sum= / autoname;
run;

data naive_vd_err;
set naive_valid;
if _n_=1 then set sum_naive_vd;
n=_freq_;
	MAD=Abs_Sum/n;
	MSE=Diff2_Sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_Sum/n;
	MPE=Div_Reg_Sum/n;
	format MAPE MPE percent10.2;
run;

data nvd_err (keep=n	MAD	MSE	RMSE	MAPE	MPE);
set naive_vd_err;
where Date="01Apr2001"d;
run;


*SEASONAL NAIVE FORECASTING;
*SEASONAL FORECAST - TRAINING;
data seas_naive_tr;
set bsta477.AMTRAK_DATA_TR;
	Forecast=lag12(Ridership); *adding a lag of 12;
	Abs=abs(Ridership-Forecast);
	Diff=Ridership-Forecast;
	Diff2=Diff**2;
	Div_Abs=Abs/Ridership;
	Div_Reg=Diff/Ridership;
run;

*SUMMING THE VALUES;
proc means data=seas_naive_tr noprint;
vars Abs Diff2 Div_Abs Div_Reg;
output out=seas_naive_tr_sum sum=/autoname;
run;

*CALCULATING TRAINING ERRORS;
data seas_naive_tr_err (keep=n MAD MSE RMSE MAPE MPE);
	set seas_naive_tr;
		where date="01Jan1991"d;
	if _n_=1 then set seas_naive_tr_sum;
	n=_freq_-12;
	MAD=Abs_sum/n;
	MSE=Diff2_sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_sum/n;
	MPE=Div_reg_sum/n;
	format MAPE MPE percent10.2;
run;


/*ERROR TERMS*/
/*MAD=(sum|Actual - Forecast|)/n
MSE=(sum(Actual-Forecast)^2/n)
RMSE=Square root of MSE
MAPE=100%*(sum(|Actual-Forecast|/Actual))/n
MPE=100%*(sum((Actual-Forecast)/Actual)/n)*/


*STEP1: USE THE TRAINING FORECASTS AND SUBSET THEM (KEEP ONLY THE LAST 12 MONTHS)
STEP2: CREATE A PRIMARY KEY
STEP3: SORT THE DATASETS (BY PRIMARY KEY)
STEP4: MERGE THE DATASETS
STEP5: SORT AGAIN BY DATE;

*SUBSETTING THE FORECASTS;
data months;
set seas_naive_tr;
where date>="01Apr2000"d;
month=month(date);
run;

*SORTING THE MONTHS DATA;
proc sort data=months out=months_sorted(drop=date ridership);
by month;
run;

*CREATING A PRIMARY KEY IN THE VALIDATION DATA;
data validation_amtrak;
set bsta477.AMTRAK_DATA_V;
month=month(date);
run;

*SORTING THE VALIDATION DATA;
proc sort data=validation_amtrak out=valid_sorted;
by month;
run;

*MERGING THE DATASETS;
data seas_valid;
	merge valid_sorted months_sorted;
	by month;
run;

*SEASONAL FORECAST - VALIDATION;
proc sort data=seas_valid out=seas_naive_vd;
by date;
run;

*CALCULATING ERRORS - VALIDATION;
data seas_naive_vd_err;
	set seas_naive_vd;
	Abs=abs(Ridership-Forecast);
	Diff=Ridership-Forecast;
	Diff2=Diff**2;
	Div_Abs=Abs/Ridership;
	Div_Reg=Diff/Ridership;
run;

proc means data=seas_naive_vd_err;
vars Abs Diff2 Div_Abs Div_Reg;
output out=seas_naive_vd_sum sum=/autoname;
run;

*VALIDATION ERRORS CALCULATED;
data seas_nvd_err (keep=n MAD MSE RMSE MAPE MPE);
set seas_naive_vd;
where date="01Apr2001"d;
if _n_=1 then set seas_naive_vd_sum;
	n=_freq_;
	MAD=Abs_sum/n;
	MSE=Diff2_sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_sum/n;
	MPE=Div_reg_sum/n;
	format MAPE MPE percent10.2;
run;


*SIMPLE AVERAGE/MEAN FORECASTING;
proc means data=bsta477.AMTRAK_DATA_TR noprint;
vars Ridership;
output out=naive_mean(keep=Forecast) mean=Forecast;
run;

*ADDING THE SIMPLE AVERAGE TO THE TRAINING DATASET;
data mean_tr;
set bsta477.AMTRAK_DATA_TR;
if _n_=1 then set naive_mean;
	Abs=abs(Ridership-Forecast);
	Diff=Ridership-Forecast;
	Diff2=Diff**2;
	Div_Abs=Abs/Ridership;
	Div_Reg=Diff/Ridership;
run;

*SUMMING THE RESIDUAL VALUES;
proc means data=mean_tr noprint;
vars Abs Diff2 Div_Abs Div_Reg;
output out=sum_mean_err_tr sum= / autoname;
run;

*FINALIZING ERROR CALCULATIONS - TRAINING;
data mean_err_tr (keep= n MAD MSE RMSE MAPE MPE);
set mean_tr (where=( date = "01Jan1991"d));
if _n_=1 then set sum_mean_err_tr;
	n=_freq_;
	MAD=Abs_sum/n;
	MSE=Diff2_sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_sum/n;
	MPE=Div_reg_sum/n;
	format MAPE MPE percent10.2;
run;

/*ERROR TERMS*/
/*MAD=(sum|Actual - Forecast|)/n
MSE=(sum(Actual-Forecast)^2/n)
RMSE=Square root of MSE
MAPE=100%*(sum(|Actual-Forecast|/Actual))/n
MPE=100%*(sum((Actual-Forecast)/Actual)/n)*/

*ADDING THE SIMPLE AVERAGE TO THE VALIDATION DATASET;
data mean_vd;
set bsta477.AMTRAK_DATA_V;
if _n_=1 then set naive_mean;
	Abs=abs(Ridership-Forecast);
	Diff=Ridership-Forecast;
	Diff2=Diff**2;
	Div_Abs=Abs/Ridership;
	Div_Reg=Diff/Ridership;
run;

*SUMMING THE RESIDUAL VALUES - VALIDATION;
proc means data=mean_vd noprint;
vars Abs Diff2 Div_Abs Div_Reg;
output out=sum_mean_err_vd sum= / autoname;
run;

*FINALIZING ERROR CALCULATIONS - TRAINING;
data mean_err_vd (keep= n MAD MSE RMSE MAPE MPE);
set mean_vd (where=( date = "01Apr2001"d));
if _n_=1 then set sum_mean_err_vd;
	n=_freq_;
	MAD=Abs_sum/n;
	MSE=Diff2_sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_sum/n;
	MPE=Div_reg_sum/n;
	format MAPE MPE percent10.2;
run;


*MOVING AVERAGE;
*MOVING AVERAGE (MA) FORECASTING - TRAINING DATA;
proc expand data=bsta477.AMTRAK_DATA_TR out=ma4_tr method=none;
	id date;
	convert Ridership=MA / transout=(movave 4);
run;

data ma4_tr_fc (where =(date>"01Apr1991"d) drop=MA);
set ma4_tr;
	Forecast=lag(MA);
	Abs=abs(Ridership-Forecast);
	Diff=Ridership-Forecast;
	Diff2=Diff**2;
	Div_Abs=Abs/Ridership;
	Div_Reg=Diff/Ridership;
run;

*SUMMING THE TRAINING VALUES;
proc means data=ma4_tr_fc noprint;
vars Abs Diff2 Div_Abs Div_Reg;
output out=ma4_tr_sum sum=/autoname;
run;

*CALCULATING TRAINING ERRORS - MA;
data ma4_tr_err (keep=n MAD MSE RMSE MAPE MPE);
set ma4_tr_fc;
	where date="01May1991"d;
	if _n_=1 then set ma4_tr_sum;
	n=_freq_;
	MAD=Abs_sum/n;
	MSE=Diff2_sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_sum/n;
	MPE=Div_Reg_sum/n;
	format MAPE MPE percent10.2;
run;

/*ERROR TERMS*/
/*MAD=(sum|Actual - Forecast|)/n
MSE=(sum(Actual-Forecast)^2/n)
RMSE=Square root of MSE
MAPE=100%*(sum(|Actual-Forecast|/Actual))/n
MPE=100%*(sum((Actual-Forecast)/Actual)/n)*/

*MOVING AVERAGE (ma) FORECASTING - VALIDATION DATA;
data ma4 (keep=Forecast);
set ma4_tr (rename=(ma=Forecast));
	where date="01Mar2001"d;
run;

data ma4_vd_fc;
set bsta477.AMTRAK_DATA_V;
if _n_=1 then set ma4;
	Abs=abs(Ridership-Forecast);
	Diff=Ridership-Forecast;
	Diff2=Diff**2;
	Div_Abs=Abs/Ridership;
	Div_Reg=Diff/Ridership;
run;

*SUMMING THE VALIDATION VALUES;
proc means data=ma4_vd_fc noprint;
vars Abs Diff2 Div_Abs Div_Reg;
output out=ma4_vd_sum sum=/autoname;
run;

*CALCULATING TRAINING ERRORS - MA VALIDATION;
data ma4_vd_err (keep=n MAD MSE RMSE MAPE MPE);
set ma4_vd_fc;
	where date="01Apr2001"d;
	if _n_=1 then set ma4_vd_sum;
	n=_freq_;
	MAD=Abs_sum/n;
	MSE=Diff2_sum/n;
	RMSE=sqrt(MSE);
	MAPE=Div_Abs_sum/n;
	MPE=Div_Reg_sum/n;
	format MAPE MPE percent10.2;
run;



