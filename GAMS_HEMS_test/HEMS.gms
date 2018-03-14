* static data
$SETGLOBAL STATIC "D:\PSOC\LWang\Comparison-between-ADP--and-MIP--HEMS\GAMS_HEMS_test\1_Static\";

* gridlabd data
$SETGLOBAL FROMGLD "D:\PSOC\LWang\Comparison-between-ADP--and-MIP--HEMS\GAMS_HEMS_test\2_from_GLD\";

* time series data
$SETGLOBAL FROMINPUTFILE "D:\PSOC\LWang\Comparison-between-ADP--and-MIP--HEMS\GAMS_HEMS_test\3_from_input_file\";

scalar M /10000/;
scalar epsilon /0.01/;
scalar coolingSP;
scalar heatingSP;
scalar EVCharRateResult;

set t time period ;
set s scenario for stochastic;
set ss(s)  subset of s;
Set hm HVAC_mode;
Set nWH
Set nEV
set nStorage
set nObj
set weight
;


* Parameters are read from the files

parameters HVACPar,AppPar,EPrice,GPrice,tempOut,desiredTEMP,fridgePar,WHPar,waterUsage,EVPar,dishWasherPar,clothesWasherDryerPar,poolPumpPar,windGen,solarGenf;
parameters storPar,nonControlLoad,gasPrice,ancPrice,occupLevel,lightingPar,tsLighting,emiPar;
parameters coObj,CHPPar,sysTimePar,solarIns,interSource,penPar;

* Read data in

$call csv2gdx %STATIC%HVAC_PAR id=HVACTable index=1 values=2..10 useheader=y StoreZero=y
$gdxin HVAC_PAR.gdx
$LOAD hm<HVACTable.dim1 HVACPar=HVACTable
$gdxin


$call csv2gdx %STATIC%CONTROL_DEV id=appTable index=1 values=2 useheader=y StoreZero=y
$gdxin CONTROL_DEV.gdx
$LOAD AppPar=AppTable
$gdxin


$call csv2gdx %FROMGLD%TS_ELEC_PRICE id=elecPriceTable index=1 values=5..56 useheader=y StoreZero=y
$gdxin TS_ELEC_PRICE
$LOAD t<ElecPriceTable.dim1 s<ElecPriceTable.dim2 Eprice=ElecPriceTable
$gdxin


$call csv2gdx %FROMINPUTFILE%TS_OUTDOOR_TEMP id=outDoorTempTable index=1 values=5..56 useheader=y StoreZero=y
$gdxin TS_OUTDOOR_TEMP
$LOAD tempOut=outdoorTempTable
$gdxin

************** added on 02-03-2015 ********************
$call csv2gdx %FROMINPUTFILE%TS_SOLAR_INSOLATION id=solarInsolationTable index=1 values=5..56 useheader=y StoreZero=y
$gdxin TS_SOLAR_INSOLATION
$LOAD solarIns=solarInsolationTable
$gdxin

$call csv2gdx %FROMINPUTFILE%TS_INTERNAL_SOURCE id=internalSourceTable index=1 values=5..56 useheader=y StoreZero=y
$gdxin TS_INTERNAL_SOURCE
$LOAD interSource=internalSourceTable
$gdxin
************** end on 02-03-2015 ********************

$call csv2gdx %FROMINPUTFILE%TS_DESIRED_TEMP id=desiredTempTable index=1 values=5..16 useheader=y StoreZero=y
$gdxin TS_DESIRED_TEMP
$LOAD desiredTemp=desiredTempTable
$gdxin

$call csv2gdx %STATIC%WATER_HEATER_PAR id=WHTable index=1 values=2..9 useheader=y StoreZero=y
$gdxin WATER_HEATER_PAR
$Load  WHPar=WHTable nWH<WHTable.dim1
$gdxin

$call csv2gdx %FROMINPUTFILE%TS_HOTWATER_USAGE id=waterUseTable index=1 values=5..56 useheader=y StoreZero=y
$gdxin TS_HOTWATER_USAGE
$Load waterUsage=waterUseTable
$gdxin

$call csv2gdx %STATIC%EV_PAR id=EVTable index=1 values=2..21 useheader=y StoreZero=y
$gdxin EV_PAR
$Load  nEV<EVTable.dim1 EVPar=EVTable
$gdxin

$call csv2gdx %STATIC%STORAGE_PAR id=storageTable index=1 values=2..11 useheader=y StoreZero=y
$gdxin STORAGE_PAR
$Load nStorage<storageTable.dim1 storPar=storageTable
$gdxin


$call csv2gdx %FROMINPUTFILE%TS_WIND_GEN id=windGenTable index=1 values=5..56 useheader=y StoreZero=y
$gdxin TS_WIND_GEN
$Load windGen=windGenTable
$gdxin

$call csv2gdx %FROMINPUTFILE%TS_SOLAR_GEN id=solarGenTable index=1 values=6..56 useheader=y StoreZero=y
$gdxin TS_SOLAR_GEN
$Load solarGenf=solarGenTable
$gdxin

$call csv2gdx %FROMGLD%TS_NONCONTROL_LOAD id=nonControlLoadTable index=1 values=6..56 useheader=y StoreZero=y
$gdxin TS_NONCONTROL_LOAD
$Load  nonControlLoad=nonControlLoadTable
$gdxin


$call csv2gdx %STATIC%OBJECTIVE id=objTable index=1 values=2 useheader=y StoreZero=y
$gdxin OBJECTIVE
$Load  nobj<objTable.dim1 coObj=objTable
$gdxin


$call csv2gdx %STATIC%PENALTY id=penTable index=1 values=2 useheader=y StoreZero=y
$gdxin PENALTY
$Load  penPar=penTable
$gdxin


* Change IntervalLength / SysTimePar if you run energy constraints
$call csv2gdx %STATIC%SYSTIME_PAR id=sysTimeTable index=1 values=2 useheader=y StoreZero=y
$gdxin SYSTIME_PAR
$Load sysTimePar=sysTimeTable
$gdxin

*ss(s)=yes$(ord(s)>=1);
*deterministic, use the first scenario
ss(s)=yes$(ord(s)>=1 and ord(s)<=1);

display waterUsage, tempOut, nEV,s,ss,t,Eprice,penPar;

$SETGLOBAL STOR_INC "NO";
$SETGLOBAL HVAC_INC "YES";
$SETGLOBAL WH_INC "YES";
$SETGLOBAL EV_INC "YES";
$SETGLOBAL PV_INC "NO";
$SETGLOBAL WIND_INC "NO";
$SETGLOBAL NCL_INC "NO";
* For fixing setpoint and testing in old version
$SETGLOBAL FIXSPTEST "NO";
* For testing, should not take effect
$SETGLOBAL SECOND_THIRD_RUN_TEMPINBOUND "NO";
* Setpoint in bound
$SETGLOBAL SPINBOUND "YES";
* Should not take effect, without integer may be faster but solution may not be feasible
$SETGLOBAL INTEGER "YES";
* Should not take effect
$SETGLOBAL ONLYCOOLING "YES";
* Penalty for charging rate variation
$SETGLOBAL STORPOWER_SMOOTH "NO";
* Penalty for smoothing charging/discharing rate
$SETGLOBAL EVPOWER_SMOOTH "NO";
* Decides if solar is dispatchable (0-max capacity)
$SETGLOBAL DISPAT_SOLAR "NO";
* battery degradation
$SETGLOBAL EVBD "NO";

****************************** Number of applicances consistency check **********************************

abort$(appPar('WATER_HEATER')-card(nWH) <> 0)
"Number of Water Heaters inconsistentency, Please check !!";

abort$(appPar('EV')-card(nEV) <> 0)
"Number of Electric Vehicles inconsistentency, Please check !!";


abort$(appPar('STORAGE')-card(nStorage) <> 0)
"Number of Storages inconsistentency, Please check !!";


abort$(abs(coObj('ENERGY_COST')+coObj('DISCOMFORT')+coObj('ELEC_CONSUMPTION')+coObj('EMISSION')+coObj('PEAK_LOAD'))-1.0000>0.0001)
"Sum of objective coefficients not equal to 1, Please check !!";


********************************** System Time Parameters ***********************************
parameter intervalLength;
* Number of hours that an interval represents (e.g. .25 hours == 15 minutes)
intervalLength=sysTimePar('INTERVAL_LENGTH');

parameter singleRunHorizon;
* Should not take effect
singleRunHorizon=sysTimePar('SINGLE_RUN_HORIZON');

parameter timeGapMultiRun;
* Should not take effect, for future development
timeGapMultiRun=sysTimePar('TIME_GAP_MULTI_RUN');

parameter elecPricef(t);
elecPricef(t)=EPRICE(t,'BASE_CASE');

parameter outTempf(t);
outTempf(t)=tempOut(t,'BASE_CASE');
display tempOut;

parameter hotWaterUsagef(t);
hotWaterUsagef(t)=waterUsage(t,'BASE_CASE');

parameter objWeight(nObj);
objWeight(nObj)=coObj(nObj);

parameter sceProbability(s);
sceProbability(ss)=1/card(ss);

display sceProbability;

* End system Time Parameters  *

* 1 HVAC Parameters *

parameters coRmTemp(hm);
coRmTemp(hm)=HVACPar(hm,'CO_RM_TEMP');
display HVACPar;

parameter coOutTemp(hm);
coOutTemp(hm)=HVACPar(hm,'CO_OUT_TEMP');
display coOutTemp;

parameter coPowerToTemp(hm);
coPowerToTemp(hm)=HVACPar(hm,'CO_POWER_TO_TEMP');
display coPowerToTemp;

* added on 02-03-2015 *
parameter coSolarInsolation(hm);
coSolarInsolation(hm)=HVACPar(hm,'CO_SOLAR_INSOLATION');
display coSolarInsolation;

parameter coInternalSource(hm);
coInternalSource(hm)=HVACPar(hm,'CO_INTERNAL_SOURCE');
display coInternalSource;
* End added on 02-03-2015 *

parameter ratedHVACPower(hm);
ratedHVACPower(hm)=HVACPar(hm,'RATED_POWER');
display ratedHVACPower;

parameter minHVACPower(hm);
minHVACPower(hm)=HVACPar(hm,'MIN_POWER');
*loop(hm,if(minHVACPower(hm)=0,minHVACPower(hm)=epsilon;););

scalar iniRmTemp;
*$IFI "%HEATPARUSE%"=="YES" iniRmTemp=HVACPar('heating','INI_RM_TEMP');
iniRmTemp=HVACPar('cooling','INI_RM_TEMP');

display iniRmTemp;

Parameter HVACCOP(hm);
HVACCOP(hm)=HVACPar(hm,'COP');
display HVACCOP;

*replace the bound later on 07-15-14
Parameter rmTempUB(t);
*$IFI "%HEATPARUSE%"=="YES" rmTempUB(t)=desiredTEMP(t,'DESIRED_HEATING_TEMP_UB');
rmTempUB(t)=desiredTEMP(t,'DESIRED_COOLING_TEMP_UB');
display rmTempUB;


Parameter rmTempLB(t);
*$IFI "%HEATPARUSE%"=="YES" rmTempLB(t)=desiredTEMP(t,'DESIRED_HEATING_TEMP_LB');
rmTempLB(t)=desiredTEMP(t,'DESIRED_COOLING_TEMP_LB');
display rmTempLB;


Parameter desiredRmTemp(t);
desiredRmTemp(t)=desiredTEMP(t,'DESIRED_COOLING_TEMP');
display desiredRmTEMP, desiredTEMP;

******************** HVAC consistency Check ****************************************************************************
*abort$(HVACPar('heating','INI_RM_TEMP')-HVACPar('cooling','INI_RM_TEMP') <> 0)
*"Initial Temperature inconsistency, Please check !!";
******************************************* End HVAC ++++++++++++++++++++++++++++++++++++++++++ ***********************************************************

**************************************   3 Water Heater Parameters   *******************************

parameters coWHTemp(nWH);
coWHTemp(nWH)=WHPar(nWH,'CO_WH_TEMP');


parameter coWaterUsage(nWH);
coWaterUsage(nWH)=WHPar(nWH,'CO_HOTWATER_USAGE');

parameter coWHPowerToTemp(nWH);
coWHPowerToTemp(nWH)=WHPar(nWH,'CO_WHPOWER_TO_TEMP');

parameter ratedWHPower(nWH);
ratedWHPower(nWH)=WHPar(nWH,'RATED_WHPOWER');

parameter minWHPower(nWH);
minWHPower(nWH)=WHPar(nWH,'min_WHPOWER');
loop(nWH,if(minWHPower(nWH)=0,minWHPower(nWH)=epsilon;););

Parameters iniWHTemp(nWH);
iniWHTemp(nWH)=WHPar(nWH,'INI_WH_TEMP');

Parameters coWHAmbTemp(nWH);
coWHAmbTemp(nWH)=WHPar(nWH,'CO_WH_AMBIENT');

Parameter WHCOP(nWH);
WHCOP(nWH)=WHPar(nWH,'COP');

Parameter WHTempUB(t);
WHTempUB(t)=desiredTEMP(t,'DESIRED_WH_TEMP_UB');

Parameter WHTempLB(t);
WHTempLB(t)=desiredTEMP(t,'DESIRED_WH_TEMP_LB');

Parameter desiredWHTemp(t);
desiredWHTemp(t)=desiredTEMP(t,'DESIRED_WH_TEMP');

parameter hotWaterUsage(t,s);
hotWaterUsage(t,ss)=waterUsage(t,ss);

*********************************** 4 EV Parameters  ***********************************************
Parameter EVCapac(nEV);
EVCapac(nEV)=EVPar(nEV,'CAPACITY');

Parameter maxEVCharge(nEV);
maxEVCharge(nEV)=EVPar(nEV,'MAX_CHARGE');

Parameter minEVCharge(nEV);
minEVCharge(nEV)=EVPar(nEV,'MIN_CHARGE');
loop(nEV,if(minEVCharge(nEV)=0,minEVCharge(nEV)=epsilon;););

Parameter maxEVDischarge(nEV);
maxEVdischarge(nEV)=EVPar(nEV,'MAX_DISCHARGE');

Parameter minEVDischarge(nEV);
minEVdischarge(nEV)=EVPar(nEV,'MIN_DISCHARGE');
loop(nEV,if(minEVDischarge(nEV)=0,minEVDischarge(nEV)=epsilon;););

parameter minEVSOC(nEV);
minEVSOC(nEV)=EVPar(nEV,'MIN_SOC');

parameter maxEVSOC(nEV);
maxEVSOC(nEV)=EVPar(nEV,'MAX_SOC');

Parameter ArrEVTime(nEV);
ArrEVTime(nEV)=EVPar(nEV,'ARRIVAL_TIME');

Parameter DepEVTime(nEV);
DepEVTime(nEV)=EVPar(nEV,'DEPART_TIME');

Parameter ArrEVSOC(nEV);
ArrEVSOC(nEV)=EVPar(nEV,'ARRIVAL_SOC');

Parameter DepEVSOC(nEV);
DepEVSOC(nEV)=EVPar(nEV,'DEPART_SOC');

Parameter EVEff(nEV);
EVEff(nEV)=EVPar(nEV,'EFFICIENCY');

parameter EVBDTMAX(nEV);
EVBDTMAX(nEV)=(DepEVTime(nEV)-ArrEVTime(nEV))*intervalLength;
parameter EVBDPMIN(nEV);
EVBDPMIN(nEV)=(DepEVSOC(nEV)-ArrEVSOC(nEV))*EVCapac(nEV)*1000/EVBDTMAX(nEV)/EVEff(nEV);


Parameter InitEVSOC(nEV);
InitEVSOC(nEV)=EVPar(nEV,'INITIAL_SOC');

Parameter EndEVSOC(nEV);
EndEVSOC(nEV)=EVPar(nEV,'END_SOC');

display InitEVSOC,EndEVSOC;

Parameter StartChargeTime(nEV);
parameter StopChargeTime(nEV);
parameter StartChargeEVSOC(nEV);
parameter StopChargeEVSOC(nEV);

loop (nEV,if(card(t)-1 ge DepEVTime(nEV) and DepEVTime(nEV) ge ArrEVTime(nEV) and ArrEVTime(nEV) ge 0,
StartChargeTime(nEV)=ArrEVTime(nEV);
StartChargeEVSOC(nEV)=ArrEVSOC(nEV);
StopChargeTime(nEV)=DepEVTime(nEV);
StopChargeEVSOC(nEV)=DepEVSOC(nEV););
if(card(t)-1 ge ArrEVTime(nEV) and ArrEVTime(nEV) ge DepEVTime(nEV) and DepEVTime(nEV) ge 0,
StartChargeTime(nEV)=0;
StartChargeEVSOC(nEV)=InitEVSOC(nEV);
StopChargeTime(nEV)=DepEVTime(nEV);
StopChargeEVSOC(nEV)=DepEVSOC(nEV););
if(card(t)-1 ge ArrEVTime(nEV) and ArrEVTime(nEV) ge 0 and (0 gt DepEVTime(nEV) or DepEVTime(nEV) gt card(t)-1),
StartChargeTime(nEV)=ArrEVTime(nEV);
StartChargeEVSOC(nEV)=ArrEVSOC(nEV);
StopChargeTime(nEV)=card(t)-1;
StopChargeEVSOC(nEV)=EndEVSOC(nEV););
if(card(t)-1 ge DepEVTime(nEV) and DepEVTime(nEV) ge 0 and (0 gt ArrEVTime(nEV) or ArrEVTime(nEV) gt card(t)-1),
StartChargeTime(nEV)=0;
StartChargeEVSOC(nEV)=InitEVSOC(nEV);
StopChargeTime(nEV)=DepEVTime(nEV);
StopChargeEVSOC(nEV)=DepEVSOC(nEV););
if((0 gt ArrEVTime(nEV) or ArrEVTime(nEV) gt card(t)-1) and (0 gt DepEVTime(nEV) or DepEVTime(nEV) gt card(t)-1),
StartChargeTime(nEV)=0;
StartChargeEVSOC(nEV)=0;
StopChargeTime(nEV)=0;
StopChargeEVSOC(nEV)=0;););
*end addition
display StartChargeTime,StartChargeEVSOC,StopChargeTime,StopChargeEVSOC;



*********************************** end EV Parameters **********************************************

*********************************** Storage Parameters *********************************************
Parameter storCapac(nStorage);
storCapac(nStorage)=storPar(nStorage,'CAPACITY');

Parameter maxstorCharge(nStorage);
maxstorCharge(nStorage)=storPar(nStorage,'MAX_CHARGE');

Parameter minStorCharge(nStorage);
minStorCharge(nStorage)=storPar(nStorage,'MIN_CHARGE');
loop(nStorage,if(minStorCharge(nStorage)=0,minStorCharge(nStorage)=epsilon;););

Parameter maxstorDischarge(nStorage);
maxStorDischarge(nStorage)=storPar(nStorage,'MAX_DISCHARGE');

Parameter minStorDischarge(nStorage);
minStorDischarge(nStorage)=storPar(nStorage,'MIN_DISCHARGE');
loop(nStorage,if(minStorDischarge(nStorage)=0,minStorDischarge(nStorage)=epsilon;););

parameter minStorSOC(nStorage);
minStorSOC(nStorage)=storPar(nStorage,'MIN_SOC');

parameter maxStorSOC(nStorage);
maxStorSOC(nStorage)=storPar(nStorage,'MAX_SOC');

Parameter iniStorSOC(nStorage);
iniStorSOC(nStorage)=storPar(nStorage,'INI_SOC');

Parameter endStorSOC(nStorage);
endStorSOC(nStorage)=storPar(nStorage,'END_SOC');

Parameter storEff(nStorage);
storEff(nStorage)=storPar(nStorage,'EFFICIENCY');
*********************************** end Storage parameters *****************************************


********************************** Global variables *****************************************
* small `p` represents power

variable pGrid(t,s);
variable pGridUB;
positive variable pGridSlack1(t,s);
positive variable pGridSlack2(t,s);
variable gasConsump(t,s);
variable energyCost total energy cost;
variable discom total discomfort;
variable elecConsump total energy comsumption;
variable carbFoot carbon footprint;
variable peakLoad peak load;
variable sumObj overall objective function;


****** dispatchable renewable *************
positive variable dispSolarGen(t,s);

****** end dispatchable renewable *********

*added on 07-09-14

variable HVACEnergyCost;
variable WHEnergyCost;
variable EVEnergyCost;
variable StorEnergyCost;
variable PVEnergyCost;
variable WindEnergyCost;
variable NCLEnergycost;
********************************** End Global variables *************************************


**********************************  HVAC variables  ***********************************************************

variable rmTemp(t,s);
variable rmTempSP(t) room temperature set point;
positive variable pHVAC(t,s) HVAC power consumption;
variable calRmTemp_noCool(t,s) calculated room temperature without HVAC;
variable calRmTemp_ratedCool(t,s) calculated room temperature with rated HVAC power;
variable calPHVAC_CoolSP(t,s) calculated HVAC power with room temperature cooling setpoint;
variable calPHVAC_HeatSP(t,s) calculated HVAC power with room temperature heating setpoint;
variable calRmTemp_noHeat(t,s) calculated room temperature without HVAC;
variable calRmTemp_ratedHeat(t,s) calculated room temperature with rated HVAC power;
variable calPHVAC_SP(t,s) calculated HVAC power with room temperature setpoint;
positive variable s1(t,s);
positive variable s2(t,s);
integer variable decision(t,s);
$IFI "%INTEGER%"=="YES" binary variable ON(t) HVAC ON=1 or OFF=0 state;
$IFI "%INTEGER%"=="NO" variable ON(t);
ON.up(t)=1;
ON.lo(t)=0;

$IFI "%INTEGER%"=="YES" binary variable c(t)  cooling state;
$IFI "%INTEGER%"=="NO" variable c(t);
c.up(t)=1;
c.lo(t)=0;
$IFI "%INTEGER%"=="YES" binary variable h(t)  heating state;
$IFI "%INTEGER%"=="NO"  variable h(t);
h.up(t)=1;
h.lo(t)=0;
$IFI "%INTEGER%"=="YES" binary variable b1(t) cooling ancillary variables;
$IFI "%INTEGER%"=="YES" binary variable b2(t) cooling ancillary variables;
$IFI "%INTEGER%"=="YES" binary variable b3(t) heating ancillary variables;
$IFI "%INTEGER%"=="YES" binary variable b4(t) heating ancillary variables;
$IFI "%INTEGER%"=="NO"  variable b1(t);
$IFI "%INTEGER%"=="NO"  variable b2(t);
$IFI "%INTEGER%"=="NO"  variable b3(t);
$IFI "%INTEGER%"=="NO"  variable b4(t);
b1.up(t)=1;
b1.lo(t)=0;
b2.up(t)=1;
b2.lo(t)=0;
b3.up(t)=1;
b3.lo(t)=0;
b4.up(t)=1;
b4.lo(t)=0;

********************************** End HVAC Variables ***********************************************************

***********************************  WH variables  **************************************************************
variable WHTemp(nWH,t,s);
variable WHTempSP(nWH,t);
positive variable pWH(nWH,t,s);
variable calWHTemp_noHeat(nWH,t,s);
variable calWHTemp_ratedHeat(nWH,t,s);
variable calPWH_HeatSP(nWH,t,s);
positive variable s5(nWH,t,s);
positive variable s6(nWH,t,s);
$IFI "%INTEGER%"=="YES" binary variable WHON(nWH,t);
$IFI "%INTEGER%"=="NO" variable WHON(nWH,t);
WHON.up(nWH,t)=1;
WHON.lo(nWH,t)=0;
$IFI "%INTEGER%"=="YES" binary variable bbb1(nWH,t);
$IFI "%INTEGER%"=="YES" binary variable bbb2(nWH,t);
$IFI "%INTEGER%"=="NO" variable bbb1(nWH,t);
$IFI "%INTEGER%"=="NO" variable bbb2(nWH,t);
bbb1.up(nWH,t)=1;
bbb2.up(nWH,t)=1;
bbb1.lo(nWH,t)=0;
bbb2.lo(nWH,t)=0;
*added on 07-01-14
variable WHAmbTemp(nWH,t,s);

***********************************  End WH variables  **************************************************************

***********************************  EV variables  ***************************************************************
variable EVCharRate(nEV,t,s);
variable EVDischarRate(nEV,t,s);
positive variable EVSOC(nEV,t,s);
positive variable EVSOCSlack(t);
$IFI "%INTEGER%"=="YES" binary variable EVChargeState(nEV,t);
$IFI "%INTEGER%"=="NO" variable EVChargeState(nEV,t);
$IFI "%INTEGER%"=="YES" binary variable EVDischargeState(nEV,t);
$IFI "%INTEGER%"=="NO" variable EVDischargeState(nEV,t);
EVChargeState.up(nEV,t)=1;
EVChargeState.lo(nEV,t)=0;
EVDischargeState.up(nEV,t)=1;
EVDischargeState.lo(nEV,t)=0;
positive variable EVCharPosDiff(nEV,t,s);
positive variable EVCharNegDiff(nEV,t,s);
positive variable EVDischarPosDiff(nEV,t,s);
positive variable EVDischarNegDiff(nEV,t,s);
variable CostBD_Q_SOC(nEV,s);
variable CostBD_Q_T(nEV,s);
variable CostBD_P_T(nEV,s);
variable CostBD_UB(nEV,s);
variable debug_variable1(nEV,s);
variable debug_variable2(nEV,s);

***********************************  End of EV variables *********************************************************
*********************************** Storage variables ************************************************************
variable storCharRate(nStorage,t,s);
variable storDischarRate(nStorage,t,s);
positive variable storSOC(nStorage,t,s);
$IFI "%INTEGER%"=="YES" binary variable storChargeState(nStorage,t);
$IFI "%INTEGER%"=="NO"  variable storChargeState(nStorage,t);
$IFI "%INTEGER%"=="YES" binary variable storDischargeState(nStorage,t);
$IFI "%INTEGER%"=="NO"  variable storDischargeState(nStorage,t);
storChargeState.up(nStorage,t)=1;
storChargeState.lo(nStorage,t)=0;
storDischargeState.up(nStorage,t)=1;
storDischargeState.lo(nStorage,t)=0;
positive variable storCharPosDiff(nStorage,t,s);
positive variable storCharNegDiff(nStorage,t,s);
positive variable storDischarPosDiff(nStorage,t,s);
positive variable storDischarNegDiff(nStorage,t,s);

*********************************** end storage variables ********************************************************

*********************************** Equations for objective functions ***************************************
equations
objDefEnerCost
objDefDiscom
objDefElecConsump
objDefCarbFoot
objDefPeakLoad
elecLoadBalanceCon
gasLoadBalanceCon
;
equations
gridPowerUB
gridPowerLB
dispSolarUB
inverterUB
inverterLB
;

********************************** Equation for energy cost breakdown ****************************************
equations
HVACEnergyCostDef
WHEnergyCostDef
EVEnergyCostDef
StorEnergyCostDef
PVEnergyCostDef
WindEnergyCostDef
NCLEnergycostDef
;
********************************** End equation for energy cost breakdown ************************************

**********************************  HVAC equaitons ***********************************************************
equations
inirmTempcon
thermEqONCool1
thermEqONCool2
ancON1
ancON2
ancON3
ancON4
thermEqOFF1
thermEqOFF2
ubrmtemp                 upper bound of room temperature
lbrmtemp
ubrmSetTemp              upper bound of room set temprature
lbrmSetTemp              lower bound of room set temprature
ubpHVACONCool                  upper bound of HVAC power
lbpHVACONCool
ubpHVACOFF1
ubpHVACOFF2
calRmTempNoCooling       calculate room temperature without cooling from HVAC
calRmTempRatedCooling    calculate room temperature with full power from HVAC
calPHVACSP1
calPHVACSP2               calculate power consumption of HVAC system with room temperature setpoint
ancbin1
ancbin2
ancbin3
ancbin4
ancbin5
ancbin6
ancbin7
ancbin8
ancbin9
ancbin10
ancbin11
ancbin12
ancbin13
ancbin14
ancbin15
ancbin16
extraCon1
extraCon2
;

equations
calRmTempNoHeat       calculate room temperature without heating from HVAC
calRmTempRatedHeat    calculate room temperature with rated power from HVAC for heating
calPHVACHeatSP1               calculate power consumption of HVAC system with room temperature setpoint
calPHVACHeatSP2
thermEqONHeat1
thermEqONHeat2
ubpHVACONHeat
lbpHVACONHeat
ancbin17
ancbin18
ancbin19
ancbin20
ancbin21
ancbin22
ancbin23
ancbin24
ancbin25
ancbin26
ancbin27
ancbin28
ancbin29
ancbin30
ancbin31
ancbin32
branch1 huristic prunning condition
branch2
lbrmSetPoint1
lbrmSetPoint2
ubrmTemp1
lbrmTemp1
;
**********************************  End HVAC Equations ***********************************************************


************************************* WH equations *************************************************************
Equations
iniWHTempcon
thermEqWH
ubWHtemp
lbWHtemp
ubWHSetTemp
lbWHSetTemp
ubpWHONHeat
ubpWHOFF1
ubpWHOFF2
calWHTempNoHeating
calWHTempRatedHeating
calPWHSP1
calPWHSP2
ancbin1WH
ancbin2WH
ancbin3WH
ancbin4WH
ancbin5WH
ancbin6WH
ancbin7WH
ancbin8WH
ancbin9WH
ancbin10WH
ancbin11WH
ancbin12WH
ancbin13WH
ancbin14WH
ancbin15WH
ancbin16WH
lbWHSetPoint1
lbWHSetPoint2
AmbTempCal
lbpWHONHeat
ubWHtemp1
lbWHtemp1
extraWHCon1
extraWHCon2
;
************************************* End WH equations *********************************************************

************************************* EV equations *************************************************************
equations
EVSOCdynamicEq1Charge
EVSOCdynamicEq2Charge
EVSOCdynamicEq1Discharge
EVSOCdynamicEq2Discharge
EVSOCdynamicEq1Idle
EVSOCdynamicEq2Idle
EVOfflineEq1
EVOfflineEq2
EViniSOCEq
EVendSOCEq
EVubChargeCon
EVlbChargeCon
EVubDischargeCon
EVlbDischargeCon
EVStateCon
EVubSOC
EVlbSOC
EVCharABS
EVDischarABS
EVCostBD_Q_SOC_Con
EVCostBD_P_T_Con
EVCostBD_Q_T_Con
EVCostBD_UP_Con1
EVCostBD_UP_Con2
debug_1
debug_2
;

****************************************************************************************************************
************************************** Storage Equations *******************************************************
equations
storSOCdynamicEq1Charge
storSOCdynamicEq2Charge
storSOCdynamicEq1Discharge
storSOCdynamicEq2Discharge
storSOCdynamicEq1Idle
storSOCdynamicEq2Idle
storIniSOCEq
storEndSOCEq
storUbChargeCon
storLbChargeCon
storUbDischargeCon
storLbDischargeCon
storSOCCon
storStateCon
storUbSOC
storLbSOC
storCharABS
storDischarABS
;
************************************** End Storage Equations ***************************************************


**********************************  HVAC Constraints *************************************************************
objDefEnerCost..      energyCost =e= sum((t,ss)$(ord(t)>1),sceProbability(ss)*EPrice(t,ss)*pGrid(t,ss)*intervalLength)
$IFI "%EVPOWER_SMOOTH%"=="YES" +penPar('PEV_DELTA')*sum((nEV,t,ss),EVCharPosDiff(nEV,t,ss)+EVCharNegDiff(nEV,t,ss))+penPar('PEV_DELTA')*sum((nEV,t,ss),EVDischarPosDiff(nEV,t,ss)+EVDischarNegDiff(nEV,t,ss))
+sum(t$(ord(t)>1),EVSOCSlack(t)*penPar('EV_SOC_INSUF')*EVCapac('EV_1')+pGridSlack1(t,'BASE_CASE')*penPar('PGRID_UB_VIO')+pGridSlack2(t,'BASE_CASE')*penPar('PGRID_LB_VIO'))
$IFI "%EVBD%"=="YES" +sum((nEV,ss),sceProbability(ss)*CostBD_UB(nEV,ss))
;

objDefDiscom..       discom =e= 0
*$IFI "%HVAC_INC%"=="YES"    +sum((t,ss)$(ord(t)>1),sceProbability(ss)*desiredTEMP(t,'PENALTY')*(s1(t,ss)+s2(t,ss)))
$IFI "%HVAC_INC%"=="YES"    +sum((t,ss)$(ord(t)>1),sceProbability(ss)*0.38*(s1(t,ss)+s2(t,ss)))
$IFI "%WH_INC%"=="YES"      +sum((t,ss)$(ord(t)>1),sceProbability(ss)*0.12*sum(nWH,s5(nWH,t,ss)+s6(nWH,t,ss)))
;

*** changed for Google Honeybee ***
objDefElecConsump..  elecConsump =e= intervalLength*(sum((t,ss)$(ord(t)>1),pGrid(t,ss)*0.08))
$IFI "%EVPOWER_SMOOTH%"=="YES" +penPar('PEV_DELTA')*sum((nEV,t,ss),EVCharPosDiff(nEV,t,ss)+EVCharNegDiff(nEV,t,ss))+penPar('PEV_DELTA')*sum((nEV,t,ss),EVDischarPosDiff(nEV,t,ss)+EVDischarNegDiff(nEV,t,ss))
$IFI "%STORPOWER_SMOOTH%"=="YES" +penPar('PBAT_DELTA')*sum((nStorage,t,ss),storCharPosDiff(nStorage,t,ss)+storCharNegDiff(nStorage,t,ss))+penPar('PBAT_DELTA')*sum((nStorage,t,ss),storDischarPosDiff(nStorage,t,ss)+storDischarNegDiff(nStorage,t,ss))
+sum(t$(ord(t)>1),EVSOCSlack(t)*penPar('EV_SOC_INSUF')*EVCapac('EV_1')+pGridSlack1(t,'BASE_CASE')*penPar('PGRID_UB_VIO')+pGridSlack2(t,'BASE_CASE')*penPar('PGRID_LB_VIO'));
*** end of change for Google Honeybee ***

objDefCarbFoot.. carbFoot =e= sum((t,ss)$(ord(t)>1),sceProbability(ss)*emiPar('CO_EFFICIENT','ELECTRICITY')*pGrid(t,ss)*intervalLength)
;

**************** peak electricity price hour ****************************
parameter PeakElecPrice;
peakElecPrice=smax(t$(ord(t)>1), EPrice(t,'BASE_CASE'));
set peakInterval(t);
peakInterval(t)=yes$(EPrice(t,'BASE_CASE') eq peakElecPrice);
*************** end get peak electricity price hour *********************

objDefPeakLoad.. peakLoad =e= pGridUB+sum(t$(ord(t)>1),EVSOCSlack(t)*penPar('EV_SOC_INSUF'));

gasLoadBalanceCon(t,ss)$(ord(t)>1).. gasConsump(t,ss) =e= 0
;

elecLoadBalancecon(t,ss)$(ord(t)>1).. pGrid(t,ss)
$IFI "%WIND_INC%"=="YES"           +windGen(t,ss)
$IFI "%PV_INC%"=="YES"             +dispSolarGen(t,ss)
                               =e=
$IFI "%HVAC_INC%"=="YES"           pHVAC(t,ss)
$IFI "%EV_INC%"=="YES"             +sum(nEV,EVCharRate(nEV,t,ss)-EVDischarRate(nEV,t,ss))
$IFI "%STOR_INC%"=="YES"           +sum(nStorage,storCharRate(nStorage,t,ss)-storDischarRate(nStorage,t,ss))
$IFI "%WH_INC%"=="YES"             +sum(nWH,pWH(nWH,t,ss))
$IFI "%NCL_INC%"=="YES"            +nonControlLoad(t,ss)
;


inirmTempcon(t,s)$(ord(t)=1 and ss(s)).. rmTemp(t,s) =e= iniRmTemp;
ubrmtemp(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s) =l= desiredRmTemp(t)+s1(t,s);
lbrmtemp(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s) =g= desiredRmTemp(t)-s2(t,s);
ubrmSetTemp(t)$(ord(t)>1).. rmTempSP(t) =l= rmTempUB(t);
lbrmSetTemp(t)$(ord(t)>1).. rmTempSP(t) =g= rmTempLB(t);
ubrmTemp1(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s) =l= rmTempUB(t);
lbrmTemp1(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s) =g= rmTempLB(t);

***** Revised on 02-03-2015
thermEqOFF1(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-coRmTemp('cooling')*rmTemp(t-1,s)-coOutTemp('cooling')*tempOut(t,s)-coSolarInsolation('cooling')*solarIns(t,s)-coInternalSource('cooling')*interSource(t,s) =l= M*ON(t);
thermEqOFF2(t,s)$(ord(t)>1 and ss(s)).. -rmTemp(t,s)+coRmTemp('cooling')*rmTemp(t-1,s)+coOutTemp('cooling')*tempOut(t,s)+coSolarInsolation('cooling')*solarIns(t,s)+coInternalSource('cooling')*interSource(t,s) =l= M*ON(t);
***** End of revison 02-03-2015


ubpHVACOFF1(t,s)$(ord(t)>1 and ss(s)).. pHVAC(t,s) =l= M*ON(t);
ubpHVACOFF2(t,s)$(ord(t)>1  and ss(s)).. -pHVAC(t,s) =l= M*ON(t);

************************   End of HVAC is OFF  *************************************

************************   HVAC is ON  *************************************
ancON1(t)$(ord(t)>1)..  c(t)-1 =l= M*(1-ON(t));
ancON2(t)$(ord(t)>1)..  -c(t)+1 =l= M*(1-ON(t));
ancON3(t)$(ord(t)>1).. c(t) =l= M*ON(t);
ancON4(t)$(ord(t)>1).. -c(t) =l= M*ON(t);
************************   End of HVAC is ON  *************************************

** added on 02-03-2015
calRmTempNoCooling(t,ss)$(ord(t)>1)..  calRmTemp_noCool(t,ss) =e= coRmTemp('cooling')*rmTemp(t-1,ss)+coOutTemp('cooling')*tempOut(t,ss)+coSolarInsolation('cooling')*solarIns(t,ss)+coInternalSource('cooling')*interSource(t,ss);
calRmTempRatedCooling(t,ss)$(ord(t)>1).. calRmTemp_ratedCool(t,ss)=e=coRmTemp('cooling')*rmTemp(t-1,ss)+coPowerToTemp('Cooling')*ratedHVACPower('Cooling')+coOutTemp('cooling')*tempOut(t,ss)+coSolarInsolation('cooling')*solarIns(t,ss)+coInternalSource('cooling')*interSource(t,ss);
calPHVACSP1(t,ss)$(ord(t)>1)..  calPHVAC_CoolSP(t,ss)-(rmTempSP(t)-coRmTemp('cooling')*rmTemp(t-1,ss)-coOutTemp('cooling')*tempOut(t,ss)-coSolarInsolation('cooling')*solarIns(t,ss)-coInternalSource('cooling')*interSource(t,ss))/coPowerToTemp('Cooling') =l= M*(2-ON(t)-c(t));
calPHVACSP2(t,ss)$(ord(t)>1)..  -calPHVAC_CoolSP(t,ss)+(rmTempSP(t)-coRmTemp('cooling')*rmTemp(t-1,ss)-coOutTemp('cooling')*tempOut(t,ss)-coSolarInsolation('cooling')*solarIns(t,ss)-coInternalSource('cooling')*interSource(t,ss))/coPowerToTemp('Cooling') =l= M*(2-ON(t)-c(t));
** end addition on 02-03-2015


*added on 11-17-14
extraCon1(t,ss)$(ord(t)>1)..  rmTempSP(t)-calRmTemp_noCool(t,ss) =l= M*(1-c(t));
extraCon2(t,ss)$(ord(t)>1)..  calRmTemp_noCool(t,ss)+epsilon-rmTempSP(t) =l= M*c(t);

*added on 02-04-15
thermEqONCool1(t,ss)$(ord(t)>1).. rmTemp(t,ss)-coRmTemp('cooling')*rmTemp(t-1,ss)-coPowerToTemp('Cooling')*pHVAC(t,ss)-coOutTemp('cooling')*tempOut(t,ss)-coSolarInsolation('cooling')*solarIns(t,ss)-coInternalSource('cooling')*interSource(t,ss) =l=M*(1-c(t));
thermEqONCool2(t,ss)$(ord(t)>1).. -rmTemp(t,ss)+coRmTemp('cooling')*rmTemp(t-1,ss)+coPowerToTemp('Cooling')*pHVAC(t,ss)+coOutTemp('cooling')*tempOut(t,ss)+coSolarInsolation('cooling')*solarIns(t,ss)+coInternalSource('cooling')*interSource(t,ss) =l=M*(1-c(t));
*end addition

ubpHVACONCool(t,ss).. pHVAC(t,ss)=l=ratedHVACPower('Cooling')*c(t);
lbpHVACONCool(t,ss).. minHVACPower('Cooling')*c(t)=l=pHVAC(t,ss);

*Cooling constraint regarding ancillary binary variable
ancbin1(t,ss)$(ord(t)>1)..  calRmTemp_noCool(t,ss)-rmTempSP(t) =l= M*(2-b1(t)-c(t));
ancbin2(t,ss)$(ord(t)>1)..  pHVAC(t,ss) =l= M*(2-b1(t)-c(t));
ancbin3(t,ss)$(ord(t)>1)..  -pHVAC(t,ss) =l= M*(2-b1(t)-c(t));
ancbin4(t,ss)$(ord(t)>1)..  rmTemp(t,ss)-calRmTemp_noCool(t,ss) =l= M*(2-b1(t)-c(t));
ancbin5(t,ss)$(ord(t)>1)..  calRmTemp_noCool(t,ss)-rmTemp(t,ss) =l= M*(2-b1(t)-c(t));
ancbin6(t,ss)$(ord(t)>1)..  rmTempSP(t)-calRmTemp_noCool(t,ss) =l= M*(1+b1(t)-c(t));
ancbin7(t,ss)$(ord(t)>1)..  ratedHVACPower('Cooling')-calPHVAC_CoolSP(t,ss) =l=M*(b1(t)+2-b2(t)-c(t));
ancbin8(t,ss)$(ord(t)>1)..  pHVAC(t,ss)-ratedHVACPower('Cooling') =l= M*(b1(t)+2-b2(t)-c(t));
ancbin9(t,ss)$(ord(t)>1)..  ratedHVACPower('Cooling')-pHVAC(t,ss) =l= M*(b1(t)+2-b2(t)-c(t));
ancbin10(t,ss)$(ord(t)>1).. rmTemp(t,ss)-calRmTemp_ratedCool(t,ss) =l= M*(b1(t)+2-b2(t)-c(t));
ancbin11(t,ss)$(ord(t)>1).. calRmTemp_ratedCool(t,ss)-rmTemp(t,ss) =l= M*(b1(t)+2-b2(t)-c(t));
ancbin12(t,ss)$(ord(t)>1).. calPHVAC_CoolSP(t,ss)-ratedHVACPower('Cooling') =l= M*(b1(t)+b2(t)+1-c(t));
ancbin13(t,ss)$(ord(t)>1).. pHVAC(t,ss)-calPHVAC_CoolSP(t,ss) =l= M*(b1(t)+b2(t)+1-c(t));
ancbin14(t,ss)$(ord(t)>1).. calPHVAC_CoolSP(t,ss)-pHVAC(t,ss) =l= M*(b1(t)+b2(t)+1-c(t));
ancbin15(t,ss)$(ord(t)>1).. rmTemp(t,ss)-rmTempSP(t) =l= M*(b1(t)+b2(t)+1-c(t));
ancbin16(t,ss)$(ord(t)>1).. rmTempSP(t)-rmTemp(t,ss) =l= M*(b1(t)+b2(t)+1-c(t));

*********************************   Heating   ***********************************************************************
* Pre_calculation
calRmTempNoHeat(t,s)$(ord(t)>1 and ss(s))..  calRmTemp_noHeat(t,s)=e= coRmTemp('heating')*rmTemp(t-1,s)+coOutTemp('heating')*tempOut(t,s);
calRmTempRatedHeat(t,s)$(ord(t)>1 and ss(s)).. calRmTemp_ratedHeat(t,s)=e=coRmTemp('heating')*rmTemp(t-1,s)+coPowerToTemp('heating')*ratedHVACPower('Heating')+coOutTemp('heating')*tempOut(t,s);

calPHVACHeatSP1(t,s)$(ord(t)>1 and ss(s))..  calpHVAC_HeatSP(t,s)-(rmTempSP(t)-coRmTemp('heating')*rmTemp(t-1,s)-coOutTemp('heating')*tempOut(t,s))/coPowerToTemp('heating') =l= M*(1-h(t));
calPHVACHeatSP2(t,s)$(ord(t)>1 and ss(s))..  -calpHVAC_HeatSP(t,s)+(rmTempSP(t)-coRmTemp('heating')*rmTemp(t-1,s)-coOutTemp('heating')*tempOut(t,s))/coPowerToTemp('heating') =l= M*(1-h(t));


thermEqONHeat1(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-coRmTemp('heating')*rmTemp(t-1,s)-coPowerToTemp('heating')*pHVAC(t,s)-coOutTemp('heating')*tempOut(t,s)
$IFI "%CHP_INC%"=="YES"        -sum(nCHP,CHPHeat(nCHP,t,s)*porCHPHeatToHVAC(nCHP)*coCHPHeatToRmTemp(nCHP))
                               =l=M*(1-h(t));
thermEqONHeat2(t,s)$(ord(t)>1 and ss(s)).. -rmTemp(t,s)+coRmTemp('heating')*rmTemp(t-1,s)+coPowerToTemp('heating')*pHVAC(t,s)+coOutTemp('heating')*tempOut(t,s)
$IFI "%CHP_INC%"=="YES"        +sum(nCHP,CHPHeat(nCHP,t,s)*porCHPHeatToHVAC(nCHP)*coCHPHeatToRmTemp(nCHP))
                               =l=M*(1-h(t));

ubpHVACONHeat(t,s)$ss(s).. pHVAC(t,s)=l=ratedHVACPower('Heating')*h(t)+c(t)*M;
lbpHVACONHeat(t,s)$ss(s).. minHVACPower('Heating')*h(t)=l=pHVAC(t,s)+c(t)*M;

* heating constraint regarding ancillary binary variable
ancbin17(t,s)$(ord(t)>1 and ss(s))..  rmTempSP(t)-calRmTemp_noHeat(t,s) =l= M*(2-b3(t)-h(t));
ancbin18(t,s)$(ord(t)>1 and ss(s))..  pHVAC(t,s) =l= M*(2-b3(t)-h(t));
ancbin19(t,s)$(ord(t)>1 and ss(s))..  -pHVAC(t,s) =l= M*(2-b3(t)-h(t));
ancbin20(t,s)$(ord(t)>1 and ss(s))..  rmTemp(t,s)-calRmTemp_noHeat(t,s) =l= M*(2-b3(t)-h(t));
ancbin21(t,s)$(ord(t)>1 and ss(s))..  calRmTemp_noHeat(t,s)-rmTemp(t,s) =l= M*(2-b3(t)-h(t));
ancbin22(t,s)$(ord(t)>1 and ss(s))..  calRmTemp_noHeat(t,s)-rmTempSP(t) =l= M*(1-h(t)+b3(t));
ancbin23(t,s)$(ord(t)>1 and ss(s))..  ratedHVACPower('Heating')-calPHVAC_HeatSP(t,s) =l=M*(b3(t)+2-b4(t)-h(t));
ancbin24(t,s)$(ord(t)>1 and ss(s))..  pHVAC(t,s)-ratedHVACPower('Heating') =l= M*(b3(t)+2-b4(t)-h(t));
ancbin25(t,s)$(ord(t)>1 and ss(s))..  ratedHVACPower('Heating')-pHVAC(t,s) =l= M*(b3(t)+2-b4(t)-h(t));
ancbin26(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-calRmTemp_ratedHeat(t,s) =l= M*(b3(t)+2-b4(t)-h(t));
ancbin27(t,s)$(ord(t)>1 and ss(s)).. calRmTemp_ratedHeat(t,s)-rmTemp(t,s) =l= M*(b3(t)+2-b4(t)-h(t));
ancbin28(t,s)$(ord(t)>1 and ss(s)).. calPHVAC_HeatSP(t,s)-ratedHVACPower('Heating') =l= M*(b3(t)+b4(t)+1-h(t));
ancbin29(t,s)$(ord(t)>1 and ss(s)).. pHVAC(t,s)-calPHVAC_HeatSP(t,s) =l= M*(b3(t)+b4(t)+1-h(t));
ancbin30(t,s)$(ord(t)>1 and ss(s)).. calPHVAC_HeatSP(t,s)-pHVAC(t,s) =l= M*(b3(t)+b4(t)+1-h(t));
ancbin31(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-rmTempSP(t) =l= M*(b3(t)+b4(t)+1-h(t));
ancbin32(t,s)$(ord(t)>1 and ss(s)).. rmTempSP(t)-rmTemp(t,s) =l= M*(b3(t)+b4(t)+1-h(t));

branch1(t,s)$((ord(t)>1  and ss(s))) .. h(t)=e=0;

***************************************** End HVAC Constraints **********************************************




***************************************** WH constraints chaned on 07-01-14***************************************************
iniWHTempcon(nWH,t,ss)$(ord(t)=1).. WHTemp(nWH,t,ss) =e= iniWHTemp(nWH);
ubWHtemp(nWH,t,ss)$(ord(t)>1).. WHTemp(nWH,t,ss) =l= desiredTEMP(t,'DESIRED_WH_TEMP')+s5(nWH,t,ss);
lbWHtemp(nWH,t,ss)$(ord(t)>1).. WHTemp(nWH,t,ss) =g= desiredTEMP(t,'DESIRED_WH_TEMP')-s6(nWH,t,ss);

*modified on 06-30-14
ubWHSetTemp(nWH,t)$(ord(t)>1).. WHTempSP(nWH,t) =l= desiredTEMP(t,'DESIRED_WH_TEMP_UB');
lbWHSetTemp(nWH,t)$(ord(t)>1).. WHTempSP(nWH,t) =g= desiredTEMP(t,'DESIRED_WH_TEMP_LB');
thermEqWH(nWH,t,ss)$(ord(t)>1).. WHTemp(nWH,t,ss)=e=coWHTemp(nWH)*WHTemp(nWH,t-1,ss)+coWHAmbTemp(nWH)*WHAmbTemp(nWH,t,ss)+coWHPowerToTemp(nWH)*pWH(nWH,t,ss)+coWaterUsage(nWH)*waterUsage(t,ss)
$IFI "%CHP_INC%"=="YES"                       +sum(nCHP,CHPHeat(nCHP,t,ss)*porCHPHeatToWH(nCHP)*coCHPHeatToWHTemp(nCHP))
;



************************   WH is OFF  *************************************
ubpWHOFF1(nWH,t,ss)$(ord(t)>1).. pWH(nWH,t,ss) =l= M*WHON(nWH,t);
ubpWHOFF2(nWH,t,ss)$(ord(t)>1).. -pWH(nWH,t,ss) =l= M*WHON(nWH,t);


*********************************   WH Heating   ***********************************************************************

calWHTempNoHeating(nWH,t,ss)$(ord(t)>1)..  calWHTemp_noHeat(nWH,t,ss) =e= coWHTemp(nWH)*WHTemp(nWH,t-1,ss)+coWHAmbTemp(nWH)*WHAmbTemp(nWH,t,ss)+coWaterUsage(nWH)*waterUsage(t,ss);
calWHTempRatedHeating(nWH,t,ss)$(ord(t)>1).. calWHTemp_ratedHeat(nWH,t,ss)=e=coWHTemp(nWH)*WHTemp(nWH,t-1,ss)+coWHAmbTemp(nWH)*WHAmbTemp(nWH,t,ss)+coWHPowerToTemp(nWH)*ratedWHPower(nWH)+coWaterUsage(nWH)*waterUsage(t,ss);
calPWHSP1(nWH,t,ss)$(ord(t)>1)..  calPWH_HeatSP(nWH,t,ss)-(WHTempSP(nWH,t)-coWHTemp(nWH)*WHTemp(nWH,t-1,ss)-coWHAmbTemp(nWH)*WHAmbTemp(nWH,t,ss)-coWaterUsage(nWH)*waterUsage(t,ss))/coWHPowerToTemp(nWH) =l= M*(1-WHON(nWH,t));
calPWHSP2(nWH,t,ss)$(ord(t)>1)..  -calPWH_HeatSP(nWH,t,ss)+(WHTempSP(nWH,t)-coWHTemp(nWH)*WHTemp(nWH,t-1,ss)-coWHAmbTemp(nWH)*WHAmbTemp(nWH,t,ss)-coWaterUsage(nWH)*waterUsage(t,ss))/coWHPowerToTemp(nWH) =l= M*(1-WHON(nWH,t));

*added on 03-06-2017
extraWHCon1(nWH,t,ss)$(ord(t)>1)..  WHTempSP(nWH,t)-calWHTemp_noHeat(nWH,t,ss) =g= -M*(1-WHON(nWH,t));
extraWHCon2(nWH,t,ss)$(ord(t)>1)..  calWHTemp_noHeat(nWH,t,ss)-epsilon-WHTempSP(nWH,t) =g= -M*WHON(nWH,t);

ubpWHONHeat(nWH,t,ss).. pWH(nWH,t,ss)=l=ratedWHPower(nWH)*WHON(nWH,t);
lbpWHONHeat(nWH,t,ss).. pWH(nWH,t,ss)=g=minWHPower(nWH)*WHON(nWH,t);
*added on 07-01-14
AmbTempCal(nWH,t,ss).. WHAmbTemp(nWH,t,ss)=e=(rmTemp(t,ss)+tempOut(t,ss))/2;

*WH constraint regarding ancillary binary variable
ancbin1WH(nWH,t,ss)$(ord(t)>1)..  WHTempSP(nWH,t)-calWHTemp_noHeat(nWH,t,ss) =l= M*(2-bbb1(nWH,t)-WHON(nWH,t));
ancbin2WH(nWH,t,ss)$(ord(t)>1)..  pWH(nWH,t,ss) =l= M*(2-bbb1(nWH,t)-WHON(nWH,t));
ancbin3WH(nWH,t,ss)$(ord(t)>1)..  -pWH(nWH,t,ss) =l= M*(2-bbb1(nWH,t)-WHON(nWH,t));
ancbin4WH(nWH,t,ss)$(ord(t)>1)..  WHTemp(nWH,t,ss)-calWHTemp_noHeat(nWH,t,ss) =l= M*(2-bbb1(nWH,t)-WHON(nWH,t));
ancbin5WH(nWH,t,ss)$(ord(t)>1)..  calWHTemp_noHeat(nWH,t,ss)-WHTemp(nWH,t,ss) =l= M*(2-bbb1(nWH,t)-WHON(nWH,t));
ancbin6WH(nWH,t,ss)$(ord(t)>1)..  calWHTemp_noHeat(nWH,t,ss)-WHTempSP(nWH,t) =l= M*(1+bbb1(nWH,t)-WHON(nWH,t));
ancbin7WH(nWH,t,ss)$(ord(t)>1)..  ratedWHPower(nWH)-calPWH_HeatSP(nWH,t,ss) =l=M*(bbb1(nWH,t)+2-bbb2(nWH,t)-WHON(nWH,t));
ancbin8WH(nWH,t,ss)$(ord(t)>1)..  pWH(nWH,t,ss)-ratedWHPower(nWH) =l= M*(bbb1(nWH,t)+2-bbb2(nWH,t)-WHON(nWH,t));
ancbin9WH(nWH,t,ss)$(ord(t)>1)..  ratedWHPower(nWH)-pWH(nWH,t,ss) =l= M*(bbb1(nWH,t)+2-bbb2(nWH,t)-WHON(nWH,t));
ancbin10WH(nWH,t,ss)$(ord(t)>1).. WHTemp(nWH,t,ss)-calWHTemp_ratedHeat(nWH,t,ss) =l= M*(bbb1(nWH,t)+2-bbb2(nWH,t)-WHON(nWH,t));
ancbin11WH(nWH,t,ss)$(ord(t)>1).. calWHTemp_ratedHeat(nWH,t,ss)-WHTemp(nWH,t,ss) =l= M*(bbb1(nWH,t)+2-bbb2(nWH,t)-WHON(nWH,t));
ancbin12WH(nWH,t,ss)$(ord(t)>1).. calPWH_HeatSP(nWH,t,ss)-ratedWHPower(nWH) =l= M*(bbb1(nWH,t)+bbb2(nWH,t)+1-WHON(nWH,t));
ancbin13WH(nWH,t,ss)$(ord(t)>1).. pWH(nWH,t,ss)-calPWH_HeatSP(nWH,t,ss) =l= M*(bbb1(nWH,t)+bbb2(nWH,t)+1-WHON(nWH,t));
ancbin14WH(nWH,t,ss)$(ord(t)>1).. calPWH_HeatSP(nWH,t,ss)-pWH(nWH,t,ss) =l= M*(bbb1(nWH,t)+bbb2(nWH,t)+1-WHON(nWH,t));
ancbin15WH(nWH,t,ss)$(ord(t)>1).. WHTemp(nWH,t,ss)-WHTempSP(nWH,t) =l= M*(bbb1(nWH,t)+bbb2(nWH,t)+1-WHON(nWH,t));
ancbin16WH(nWH,t,ss)$(ord(t)>1).. WHTempSP(nWH,t)-WHTemp(nWH,t,ss) =l= M*(bbb1(nWH,t)+bbb2(nWH,t)+1-WHON(nWH,t));
***************************************** End WH Constraints ***********************************************

****************************************** EV Constraints **************************************************
EVSOCdynamicEq1Charge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. EVSOC(nEV,t,ss)-EVSOC(nEV,t-1,ss)-EVEff(nEV)*EVCharRate(nEV,t,ss)*intervalLength/EVCapac(nEV) =l= M*(1-EVChargeState(nEV,t));
EVSOCdynamicEq2Charge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. -EVSOC(nEV,t,ss)+EVSOC(nEV,t-1,ss)+EVEff(nEV)*EVCharRate(nEV,t,ss)*intervalLength/EVCapac(nEV) =l= M*(1-EVChargeState(nEV,t));
EVSOCdynamicEq1Discharge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. EVSOC(nEV,t,ss)-EVSOC(nEV,t-1,ss)+EVDischarRate(nEV,t,ss)*intervalLength/EVCapac(nEV)/EVEff(nEV)=l= M*(1-EVDischargeState(nEV,t));
EVSOCdynamicEq2Discharge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. -EVSOC(nEV,t,ss)+EVSOC(nEV,t-1,ss)-EVDischarRate(nEV,t,ss)*intervalLength/EVCapac(nEV)/EVEff(nEV)=l= M*(1-EVDischargeState(nEV,t));
EVSOCdynamicEq1Idle(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1)..  EVSOC(nEV,t,ss)-EVSOC(nEV,t-1,ss)=l= M*(EVChargeState(nEV,t)+EVDischargeState(nEV,t));
EVSOCdynamicEq2Idle(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1)..  -EVSOC(nEV,t,ss)+EVSOC(nEV,t-1,ss)=l= M*(EVChargeState(nEV,t)+EVDischargeState(nEV,t));
EVOfflineEq1(nEV,t,ss)$(ord(t)<StartChargeTime(nEV)+2 or ord(t)>StopChargeTime(nEV)+1).. EVCharRate(nEV,t,ss) =e= 0;
EVOfflineEq2(nEV,t,ss)$(ord(t)<StartChargeTime(nEV)+2 or ord(t)>StopChargeTime(nEV)+1).. EVDischarRate(nEV,t,ss) =e= 0;
EViniSOCEq(nEV,t,ss)$(ord(t)=StartChargeTime(nEV)+1).. EVSOC(nEV,t,ss)=e=StartChargeEVSOC(nEV);

EVendSOCEq(nEV,t,ss)$(ord(t)=StopChargeTime(nEV)+1).. EVSOC(nEV,t,ss)=e=StopChargeEVSOC(nEV)-EVSOCSlack(t);


EVubChargeCon(nEV,t,ss)$(ord(t)>1)..   EVCharRate(nEV,t,ss) =l= maxEVCharge(nEV)*EVChargeState(nEV,t);
EVlbChargeCon(nEV,t,ss)$(ord(t)>1)..   EVCharRate(nEV,t,ss) =g= minEVCharge(nEV)*EVChargeState(nEV,t);
EVubDischargeCon(nEV,t,ss)$(ord(t)>1)..   EVDischarRate(nEV,t,ss) =l= maxEVDischarge(nEV)*EVDischargeState(nEV,t);
EVlbDischargeCon(nEV,t,ss)$(ord(t)>1)..   EVDischarRate(nEV,t,ss) =g= minEVDischarge(nEV)*EVDischargeState(nEV,t);
EVStateCon(nEV,t,ss)$(ord(t)>1)..  EVChargeState(nEV,t)+EVDischargeState(nEV,t) =l= 1;
EVubSOC(nEV,t,ss)$((ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1))..  EVSOC(nEV,t,ss)=l=maxEVSOC(nEV);
EVlbSOC(nEV,t,ss)$((ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1))..  EVSOC(nEV,t,ss)=g=minEVSOC(nEV);

*added on 03-10-2015
EVCharABS(nEV,t,ss)$((ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1)).. EVCharRate(nEV,t,ss)-EVCharRate(nEV,t-1,ss)=e=EVCharPosDiff(nEV,t,ss)-EVCharNegDiff(nEV,t,ss);
EVDischarABS(nEV,t,ss)$((ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1)).. EVDisCharRate(nEV,t,ss)-EVDisCharRate(nEV,t-1,ss)=e=EVDischarPosDiff(nEV,t,ss)-EVDischarNegDiff(nEV,t,ss);
*added on 04-08-2015 for battery degradation
EVCostBD_Q_SOC_Con(nEV,ss).. CostBD_Q_SOC(nEV,ss)=e=sum(t$((ord(t)>=ArrEVTime(nEV)+2 and ord(t)<=DepEVTime(nEV)+1)), EVPar(nEV,'DEG_CBAT')*(EVPar(nEV,'DEG_M')*EVSOC(nEV,t,ss)-EVPar(nEV,'DEG_D'))*intervalLength/EVPar(nEV,'DEG_CFMAX')/15/8760);
debug_1(nEV,ss).. debug_variable1(nEV,ss)=e=sum(t$((ord(t)>=ArrEVTime(nEV)+2 and ord(t)<=DepEVTime(nEV)+1)),intervalLength*(EVPar(nEV,'DEG_SLOPE_P')*EVCharRate(nEV,t,ss)*1000+0.0472));
debug_2(nEV,ss).. debug_variable2(nEV,ss)=e=EVBDTMAX(nEV)*(EVPar(nEV,'DEG_SLOPE_P')*EVBDPMIN(nEV)+0.0472);
EVCostBD_P_T_Con(nEV,ss).. CostBD_P_T(nEV,ss)=e=EVPar(nEV,'DEG_CBAT')*(sum(t$((ord(t)>=ArrEVTime(nEV)+2 and ord(t)<=DepEVTime(nEV)+1)),intervalLength*(EVPar(nEV,'DEG_SLOPE_P')*EVCharRate(nEV,t,ss)*1000+0.0472))-EVBDTMAX(nEV)*(EVPar(nEV,'DEG_SLOPE_P')*EVBDPMIN(nEV)+0.0472));
EVCostBD_Q_T_Con(nEV,ss).. CostBD_Q_T(nEV,ss)=e=EVPar(nEV,'DEG_CBAT')*(sum(t$((ord(t)>=ArrEVTime(nEV)+2 and ord(t)<=DepEVTime(nEV)+1)),intervalLength*(EVPar(nEV,'DEG_SLOPE_Q')*EVCharRate(nEV,t,ss)*1000+0.03627))-EVBDTMAX(nEV)*(EVPar(nEV,'DEG_SLOPE_Q')*EVBDPMIN(nEV)+0.03627));
EVCostBD_UP_Con1(nEV,ss).. CostBD_UB(nEV,ss) =g= CostBD_Q_T(nEV,ss)+ CostBD_Q_SOC(nEV,ss);
EVCostBD_UP_Con2(nEV,ss).. CostBD_UB(nEV,ss) =g= CostBD_P_T(nEV,ss);
************************************************************************************************************
************************************************************************************************************

*********************************** Storage constraints ****************************************************
storSOCdynamicEq1Charge(nStorage,t,ss)$(ord(t)>1).. storSOC(nStorage,t,ss)-storSOC(nStorage,t-1,ss)-storEff(nStorage)*storCharRate(nStorage,t,ss)*intervalLength/storCapac(nStorage) =l= M*(1-storChargeState(nStorage,t));
storSOCdynamicEq2Charge(nStorage,t,ss)$(ord(t)>1).. -storSOC(nStorage,t,ss)+storSOC(nStorage,t-1,ss)+storEff(nStorage)*storCharRate(nStorage,t,ss)*intervalLength/storCapac(nStorage) =l= M*(1-storChargeState(nStorage,t));
storSOCdynamicEq1Discharge(nStorage,t,ss)$(ord(t)>1).. storSOC(nStorage,t,ss)-storSOC(nStorage,t-1,ss)+storDischarRate(nStorage,t,ss)*intervalLength/storCapac(nStorage)/storEff(nStorage)=l= M*(1-storDischargeState(nStorage,t));
storSOCdynamicEq2Discharge(nStorage,t,ss)$(ord(t)>1).. -storSOC(nStorage,t,ss)+storSOC(nStorage,t-1,ss)-storDischarRate(nStorage,t,ss)*intervalLength/storCapac(nStorage)/storEff(nStorage)=l= M*(1-storDischargeState(nStorage,t));
storSOCdynamicEq1Idle(nStorage,t,ss)$(ord(t)>1)..  storSOC(nStorage,t,ss)-storSOC(nStorage,t-1,ss)=l= M*(storChargeState(nStorage,t)+storDischargeState(nStorage,t));
storSOCdynamicEq2Idle(nStorage,t,ss)$(ord(t)>1)..  -storSOC(nStorage,t,ss)+storSOC(nStorage,t-1,ss)=l= M*(storChargeState(nStorage,t)+storDischargeState(nStorage,t));
storSOCCon(nStorage,t,ss)$(ord(t)>1).. storSOC(nStorage,t,ss) =l= 1;
storIniSOCEq(nStorage,t,ss)$(ord(t)=1).. storSOC(nStorage,t,ss) =e= iniStorSOC(nStorage);
storEndSOCEq(nStorage,t,ss)$(ord(t)=card(t)).. storSOC(nStorage,t,ss) =e= endStorSOC(nStorage);
storubChargeCon(nStorage,t,ss)$(ord(t)>1)..   storCharRate(nStorage,t,ss) =l= maxstorCharge(nStorage)*storChargeState(nStorage,t);
storlbChargeCon(nStorage,t,ss)$(ord(t)>1)..   storCharRate(nStorage,t,ss) =g= minStorCharge(nStorage)*storChargeState(nStorage,t);
storubDischargeCon(nStorage,t,ss)$(ord(t)>1)..   storDischarRate(nStorage,t,ss) =l= maxStorDischarge(nStorage)*storDischargeState(nStorage,t);
storlbDischargeCon(nStorage,t,ss)$(ord(t)>1)..   storDisCharRate(nStorage,t,ss) =g= minStorDischarge(nStorage)*storDischargeState(nStorage,t);
storStateCon(nStorage,t,ss)$(ord(t)>1)..  storChargeState(nStorage,t)+storDischargeState(nStorage,t) =l= 1;
storUbSOC(nStorage,t,ss)$(ord(t)>1)..  storSOC(nStorage,t,ss)=l=maxStorSOC(nStorage);
storLbSOC(nStorage,t,ss)$(ord(t)>1)..  storSOC(nStorage,t,ss)=g=minStorSOC(nStorage);

storCharABS(nStorage,t,ss)$(ord(t)>1).. storCharRate(nStorage,t,ss)-storCharRate(nStorage,t-1,ss)=e=storCharPosDiff(nStorage,t,ss)-storCharNegDiff(nStorage,t,ss);
storDischarABS(nStorage,t,ss)$(ord(t)>1).. storDischarRate(nStorage,t,ss)-storDischarRate(nStorage,t-1,ss)=e=storDischarPosDiff(nStorage,t,ss)-storDischarNegDiff(nStorage,t,ss);


*********************************** End Storage Constraints ************************************************

*solve SHEMS using mip minimzing sumObj;
parameter ubEnergyCost;
parameter ubElecConsump;
parameter ubCarbFoot;
parameter ubPeakLoad;
parameter ubDiscom;

scalar objcounter;
objcounter=0;

parameter ifSingleObjective;
ifSingleObjective=0;

if(coObj('ENERGY_COST')>0,
objcounter=objcounter+1;
);

if(coObj('ELEC_CONSUMPTION')>0,
objcounter=objcounter+1;
);

if(coObj('EMISSION')>0,
objcounter=objcounter+1;
);

if(coObj('PEAK_LOAD')>0,
objcounter=objcounter+1;
);

if(coObj('DISCOMFORT')>0,
objcounter=objcounter+1;
);

* if single objective function
if(objcounter=1,
         ifSingleObjective=1;
         ubEnergyCost=1;
         ubElecConsump=1;
         ubDiscom=1;
         ubPeakLoad=1;
         ubCarbFoot=1;
);

*Added on 07-02-14
equations
objDefSumObj
ObjDefSumObjToGetDiscomUB
fixObjDefSumObj
fixSetTemp
fixWHSetTemp
;


ObjDefSumObjToGetDiscomUB..  sumObj =e= sum((t,ss)$(ord(t)>1),sceProbability(ss)*EPrice(t,ss)*(sum(nWH,pWH(nWH,t,ss))+pHVAC(t,ss))*intervalLength);
fixSetTemp(t)$(ord(t)>1).. rmTempSP(t) =e= desiredTEMP(t,'DESIRED_COOLING_TEMP');
fixWHSetTemp(nWH,t)$(ord(t)>1).. WHTempSP(nWH,t) =e= desiredTEMP(t,'DESIRED_WH_TEMP');
HVACEnergyCostDef.. HVACEnergyCost =e=  sum((t,ss)$(ord(t)>1),sceProbability(ss)*EPrice(t,ss)*pHVAC(t,ss)*intervalLength);
WHEnergyCostDef.. WHEnergyCost =e= sum((nWH,t,ss)$(ord(t)>1),sceProbability(ss)*EPrice(t,ss)*pWH(nWH,t,ss)*intervalLength);



*first run: MINIMIZE THERMAL-APPLICANCE-ONLY ELECTRICITY COST TO GET DISCOMFORT UPPER BOUND
model SHEMS_GETDISCOMUB/
ObjDefSumObjToGetDiscomUB
objDefEnerCost
objDefDiscom
objDefElecConsump
objDefPeakLoad
elecLoadBalanceCon
HVACEnergyCostDef
WHEnergyCostDef

$IFI "%HVAC_INC%"=="YES" inirmTempcon
$IFI "%HVAC_INC%"=="YES" thermEqONCool1
$IFI "%HVAC_INC%"=="YES" thermEqONCool2
$IFI "%HVAC_INC%"=="YES" ancON1
$IFI "%HVAC_INC%"=="YES" ancON2
$IFI "%HVAC_INC%"=="YES" ancON3
$IFI "%HVAC_INC%"=="YES" ancON4
$IFI "%HVAC_INC%"=="YES" thermEqOFF1
$IFI "%HVAC_INC%"=="YES" thermEqOFF2 ubrmtemp lbrmtemp
$IFI "%SPINBOUND%"=="YES"  ubrmSetTemp lbrmSetTemp
$IFI "%HVAC_INC%"=="YES" ubpHVACONCool
$IFI "%HVAC_INC%"=="YES" lbpHVACONCool
$IFI "%HVAC_INC%"=="YES" ubpHVACOFF1
$IFI "%HVAC_INC%"=="YES" ubpHVACOFF2
$IFI "%HVAC_INC%"=="YES" calRmTempNoCooling
$IFI "%HVAC_INC%"=="YES" calRmTempRatedCooling
$IFI "%HVAC_INC%"=="YES" calPHVACSP1
$IFI "%HVAC_INC%"=="YES" calPHVACSP2
$IFI "%HVAC_INC%"=="YES" ancbin1 ancbin2 ancbin3 ancbin4 ancbin5 ancbin6 ancbin7 ancbin8 ancbin9 ancbin10 ancbin11 ancbin12 ancbin13 ancbin14 ancbin15 ancbin16
ubrmTemp1 lbrmTemp1
extraCon1
extraCon2


$IFI "%WH_INC%"=="YES" iniWHTempcon
$IFI "%WH_INC%"=="YES" thermEqWH
$IFI "%WH_INC%"=="YES" ubWHtemp
$IFI "%WH_INC%"=="YES" lbWHtemp
$IFI "%WH_INC%"=="YES" ubWHSetTemp
$IFI "%WH_INC%"=="YES" lbWHSetTemp
$IFI "%WH_INC%"=="YES" ubpWHONHeat
$IFI "%WH_INC%"=="YES" ubpWHOFF1
$IFI "%WH_INC%"=="YES" ubpWHOFF2
$IFI "%WH_INC%"=="YES" calWHTempNoHeating
$IFI "%WH_INC%"=="YES" calWHTempRatedHeating
$IFI "%WH_INC%"=="YES" calPWHSP1
$IFI "%WH_INC%"=="YES" calPWHSP2
$IFI "%WH_INC%"=="YES" ancbin1WH
$IFI "%WH_INC%"=="YES" ancbin2WH
$IFI "%WH_INC%"=="YES" ancbin3WH
$IFI "%WH_INC%"=="YES" ancbin4WH
$IFI "%WH_INC%"=="YES" ancbin5WH
$IFI "%WH_INC%"=="YES" ancbin6WH
$IFI "%WH_INC%"=="YES" ancbin7WH
$IFI "%WH_INC%"=="YES" ancbin8WH
$IFI "%WH_INC%"=="YES" ancbin9WH
$IFI "%WH_INC%"=="YES" ancbin10WH
$IFI "%WH_INC%"=="YES" ancbin11WH
$IFI "%WH_INC%"=="YES" ancbin12WH
$IFI "%WH_INC%"=="YES" ancbin13WH
$IFI "%WH_INC%"=="YES" ancbin14WH
$IFI "%WH_INC%"=="YES" ancbin15WH
$IFI "%WH_INC%"=="YES" ancbin16WH
$IFI "%WH_INC%"=="YES" AmbTempCal
$IFI "%WH_INC%"=="YES" lbpWHONHeat
* added on 03-06-17
$IFI "%WH_INC%"=="YES" extraWHCon1
$IFI "%WH_INC%"=="YES" extraWHCon2

$IFI "%FIXSPTEST%"=="YES" fixSetTemp
$IFI "%FIXSPTEST%"=="YES" fixWHSetTemp

/;
SHEMS_GETDISCOMUB.OptCR=0.01;
SHEMS_GETDISCOMUB.ResLim=60;
* FIRST RUN to get the discomfort upper bound

*if(coObj('DISCOMFORT')>0 and ifSingleObjective=0,

*solve SHEMS_GETDISCOMUB using mip minimizing sumObj;

*UbDiscom=discom.l;
*else
*UbDiscom=1;
*);

*display 'First Run Results (minimizing THERMAL-APPLICANCE-ONLY Electricity Cost)';
*display sumObj.l, discom.l, ON.l, c.l, h.l,rmtemp.l,pHVAC.l;


binary variable f_ON(t) HVAC ON=1 or OFF=0 state;
binary variable f_c(t)  cooling state;
binary variable f_h(t)  heating state;
binary variable f_b1(t) cooling ancillary variables;
binary variable f_b2(t) cooling ancillary variables;
binary variable f_b3(t) heating ancillary variables;
binary variable f_b4(t) heating ancillary variables;


********************************** End HVAC Variables ***********************************************************

***********************************  WH variables  **************************************************************
binary variable f_WHON(nWH,t);
binary variable f_bbb1(nWH,t);
binary variable f_bbb2(nWH,t);

***********************************  End WH variables  **************************************************************

***********************************  EV variables  ***************************************************************

binary variable f_EVChargeState(nEV,t);
binary variable f_EVDischargeState(nEV,t);

***********************************  End of EV variables *********************************************************
*********************************** Storage variables ************************************************************

binary variable f_storChargeState(nStorage,t);
binary variable f_storDischargeState(nStorage,t);

*********************************** end storage variables ********************************************************


**********************************  HVAC equaitons ***********************************************************
equations
f_thermEqONCool1
f_thermEqONCool2
f_ancON1
f_ancON2
f_ancON3
f_ancON4
f_thermEqOFF1
f_thermEqOFF2
f_ubpHVACONCool                  upper bound of HVAC power
f_lbpHVACONCool
f_ubpHVACOFF1
f_ubpHVACOFF2
f_calPHVACSP1
f_calPHVACSP2               calculate power consumption of HVAC system with room temperature setpoint
f_ancbin1
f_ancbin2
f_ancbin3
f_ancbin4
f_ancbin5
f_ancbin6
f_ancbin7
f_ancbin8
f_ancbin9
f_ancbin10
f_ancbin11
f_ancbin12
f_ancbin13
f_ancbin14
f_ancbin15
f_ancbin16
f_extraCon1
f_extraCon2
;

equations
f_calPHVACHeatSP1               calculate power consumption of HVAC system with room temperature setpoint
f_calPHVACHeatSP2
f_thermEqONHeat1
f_thermEqONHeat2
f_ubpHVACONHeat
f_lbpHVACONHeat
f_ancbin17
f_ancbin18
f_ancbin19
f_ancbin20
f_ancbin21
f_ancbin22
f_ancbin23
f_ancbin24
f_ancbin25
f_ancbin26
f_ancbin27
f_ancbin28
f_ancbin29
f_ancbin30
f_ancbin31
f_ancbin32
f_lbrmSetPoint1
f_lbrmSetPoint2
f_branch1
;
**********************************  End HVAC Equations ***********************************************************

************************************* WH equations *************************************************************
Equations
f_ubpWHONHeat
f_ubpWHOFF1
f_ubpWHOFF2
f_calPWHSP1
f_calPWHSP2
f_ancbin1WH
f_ancbin2WH
f_ancbin3WH
f_ancbin4WH
f_ancbin5WH
f_ancbin6WH
f_ancbin7WH
f_ancbin8WH
f_ancbin9WH
f_ancbin10WH
f_ancbin11WH
f_ancbin12WH
f_ancbin13WH
f_ancbin14WH
f_ancbin15WH
f_ancbin16WH
f_lbWHSetPoint1
f_lbWHSetPoint2
f_lbpWHONHeat
f_extraWHCon1
f_extraWHCon2
;
************************************* End WH equations *********************************************************

************************************* EV equations *************************************************************
equations
f_EVSOCdynamicEq1Charge
f_EVSOCdynamicEq2Charge
f_EVSOCdynamicEq1Discharge
f_EVSOCdynamicEq2Discharge
f_EVSOCdynamicEq1Idle
f_EVSOCdynamicEq2Idle
f_EVubChargeCon
f_EVlbChargeCon
f_EVubDischargeCon
f_EVlbDischargeCon
f_EVStateCon
;

****************************************************************************************************************
************************************** Storage Equations *******************************************************
equations
f_storSOCdynamicEq1Charge
f_storSOCdynamicEq2Charge
f_storSOCdynamicEq1Discharge
f_storSOCdynamicEq2Discharge
f_storSOCdynamicEq1Idle
f_storSOCdynamicEq2Idle
f_storUbChargeCon
f_storLbChargeCon
f_storUbDischargeCon
f_storLbDischargeCon
f_storStateCon
;
************************************** End Storage Equations ***************************************************


*added on 02-04-15
f_thermEqOFF1(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-coRmTemp('cooling')*rmTemp(t-1,s)-coOutTemp('cooling')*tempOut(t,s)-coSolarInsolation('cooling')*solarIns(t,s)-coInternalSource('cooling')*interSource(t,s) =l=M*f_ON(t);
f_thermEqOFF2(t,s)$(ord(t)>1 and ss(s)).. -rmTemp(t,s)+coRmTemp('cooling')*rmTemp(t-1,s)+coOutTemp('cooling')*tempOut(t,s)+coSolarInsolation('cooling')*solarIns(t,s)+coInternalSource('cooling')*interSource(t,s) =l=M*f_ON(t);
*end added

f_ubpHVACOFF1(t,s)$(ord(t)>1 and ss(s)).. pHVAC(t,s) =l= M*f_ON(t);
f_ubpHVACOFF2(t,s)$(ord(t)>1  and ss(s)).. -pHVAC(t,s) =l= M*f_ON(t);

************************   End of HVAC is OFF  *************************************

************************   HVAC is ON  *************************************
f_ancON1(t)$(ord(t)>1)..  f_c(t)-1 =l= M*(1-f_ON(t));
f_ancON2(t)$(ord(t)>1)..  -f_c(t)+1 =l= M*(1-f_ON(t));
f_ancON3(t)$(ord(t)>1).. f_c(t) =l= M*f_ON(t);
f_ancON4(t)$(ord(t)>1).. -f_c(t) =l= M*f_ON(t);

*added on 11-17-14
f_extraCon1(t,ss)$(ord(t)>1)..  rmTempSP(t)-calRmTemp_noCool(t,ss) =l= M*(1-f_c(t));
f_extraCon2(t,ss)$(ord(t)>1)..  calRmTemp_noCool(t,ss)+epsilon-rmTempSP(t) =l= M*f_c(t);

*end added on 11-17-14


**added on 02-04-15
f_calPHVACSP1(t,ss)$(ord(t)>1)..  calPHVAC_CoolSP(t,ss)-(rmTempSP(t)-coRmTemp('cooling')*rmTemp(t-1,ss)-coOutTemp('cooling')*tempOut(t,ss)-coSolarInsolation('cooling')*solarIns(t,ss)-coInternalSource('cooling')*interSource(t,ss))/coPowerToTemp('Cooling') =l= 0;
f_calPHVACSP2(t,ss)$(ord(t)>1)..  -calPHVAC_CoolSP(t,ss)+(rmTempSP(t)-coRmTemp('cooling')*rmTemp(t-1,ss)-coOutTemp('cooling')*tempOut(t,ss)-coSolarInsolation('cooling')*solarIns(t,ss)-coInternalSource('cooling')*interSource(t,ss))/coPowerToTemp('Cooling') =l= 0;
*Cooling Constraint when ON(t) and c(t) are both equal to 1
f_thermEqONCool1(t,ss)$(ord(t)>1).. rmTemp(t,ss)-coRmTemp('cooling')*rmTemp(t-1,ss)-coPowerToTemp('Cooling')*pHVAC(t,ss)-coOutTemp('cooling')*tempOut(t,ss)-coSolarInsolation('cooling')*solarIns(t,ss)-coInternalSource('cooling')*interSource(t,ss) =l=0;
f_thermEqONCool2(t,ss)$(ord(t)>1).. -rmTemp(t,ss)+coRmTemp('cooling')*rmTemp(t-1,ss)+coPowerToTemp('Cooling')*pHVAC(t,ss)+coOutTemp('cooling')*tempOut(t,ss)+coSolarInsolation('cooling')*solarIns(t,ss)+coInternalSource('cooling')*interSource(t,ss) =l=0;
**end added


f_ubpHVACONCool(t,ss).. pHVAC(t,ss)=l=ratedHVACPower('Cooling');
f_lbpHVACONCool(t,ss).. 0=l=pHVAC(t,ss);

*Cooling constraint regarding ancillary binary variable
f_ancbin1(t,ss)$(ord(t)>1)..  calRmTemp_noCool(t,ss)-rmTempSP(t) =l= M*(1-f_b1(t));
f_ancbin2(t,ss)$(ord(t)>1)..  pHVAC(t,ss) =l= M*(1-f_b1(t));
f_ancbin3(t,ss)$(ord(t)>1)..  -pHVAC(t,ss) =l= M*(1-f_b1(t));
f_ancbin4(t,ss)$(ord(t)>1)..  rmTemp(t,ss)-calRmTemp_noCool(t,ss) =l= M*(1-f_b1(t));
f_ancbin5(t,ss)$(ord(t)>1)..  calRmTemp_noCool(t,ss)-rmTemp(t,ss) =l= M*(1-f_b1(t));
f_ancbin6(t,ss)$(ord(t)>1)..  rmTempSP(t)+epsilon-calRmTemp_noCool(t,ss) =l= M*(f_b1(t));
f_ancbin7(t,ss)$(ord(t)>1)..  ratedHVACPower('Cooling')-calPHVAC_CoolSP(t,ss) =l=M*(f_b1(t)+1-f_b2(t));
f_ancbin8(t,ss)$(ord(t)>1)..  pHVAC(t,ss)-ratedHVACPower('Cooling') =l= M*(f_b1(t)+1-f_b2(t));
f_ancbin9(t,ss)$(ord(t)>1)..  ratedHVACPower('Cooling')-pHVAC(t,ss) =l= M*(f_b1(t)+1-f_b2(t));
f_ancbin10(t,ss)$(ord(t)>1).. rmTemp(t,ss)-calRmTemp_ratedCool(t,ss) =l= M*(f_b1(t)+1-f_b2(t));
f_ancbin11(t,ss)$(ord(t)>1).. calRmTemp_ratedCool(t,ss)-rmTemp(t,ss) =l= M*(f_b1(t)+1-f_b2(t));
f_ancbin12(t,ss)$(ord(t)>1).. calPHVAC_CoolSP(t,ss)+epsilon-ratedHVACPower('Cooling') =l= M*(f_b1(t)+f_b2(t));
f_ancbin13(t,ss)$(ord(t)>1).. pHVAC(t,ss)-calPHVAC_CoolSP(t,ss) =l= M*(f_b1(t)+f_b2(t));
f_ancbin14(t,ss)$(ord(t)>1).. calPHVAC_CoolSP(t,ss)-pHVAC(t,ss) =l= M*(f_b1(t)+f_b2(t));
f_ancbin15(t,ss)$(ord(t)>1).. rmTemp(t,ss)-rmTempSP(t) =l= M*(f_b1(t)+f_b2(t));
f_ancbin16(t,ss)$(ord(t)>1).. rmTempSP(t)-rmTemp(t,ss) =l= M*(f_b1(t)+f_b2(t));

*********************************   Heating   ***********************************************************************
f_calPHVACHeatSP1(t,s)$(ord(t)>1 and ss(s))..  calpHVAC_HeatSP(t,s)-(rmTempSP(t)-coRmTemp('heating')*rmTemp(t-1,s)-coOutTemp('heating')*tempOut(t,s))/coPowerToTemp('heating') =l= M*(1-f_h(t));
f_calPHVACHeatSP2(t,s)$(ord(t)>1 and ss(s))..  -calpHVAC_HeatSP(t,s)+(rmTempSP(t)-coRmTemp('heating')*rmTemp(t-1,s)-coOutTemp('heating')*tempOut(t,s))/coPowerToTemp('heating') =l= M*(1-f_h(t));

*the following is to consider CHP revised on 05-20-2014
f_thermEqONHeat1(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-coRmTemp('heating')*rmTemp(t-1,s)-coPowerToTemp('heating')*pHVAC(t,s)-coOutTemp('heating')*tempOut(t,s)
$IFI "%CHP_INC%"=="YES"        -sum(nCHP,CHPHeat(nCHP,t,s)*porCHPHeatToHVAC(nCHP)*coCHPHeatToRmTemp(nCHP))
                               =l=M*(1-f_h(t));
f_thermEqONHeat2(t,s)$(ord(t)>1 and ss(s)).. -rmTemp(t,s)+coRmTemp('heating')*rmTemp(t-1,s)+coPowerToTemp('heating')*pHVAC(t,s)+coOutTemp('heating')*tempOut(t,s)
$IFI "%CHP_INC%"=="YES"        +sum(nCHP,CHPHeat(nCHP,t,s)*porCHPHeatToHVAC(nCHP)*coCHPHeatToRmTemp(nCHP))
                               =l=M*(1-f_h(t));

f_ubpHVACONHeat(t,s)$ss(s).. pHVAC(t,s)=l=ratedHVACPower('Heating')*f_h(t)+f_c(t)*M;
f_lbpHVACONHeat(t,s)$ss(s).. minHVACPower('Heating')*f_h(t)=l=pHVAC(t,s)+f_c(t)*M;

* heating constraint regarding ancillary binary variable
f_ancbin17(t,s)$(ord(t)>1 and ss(s))..  rmTempSP(t)-calRmTemp_noHeat(t,s) =l= M*(2-f_b3(t)-f_h(t));
f_ancbin18(t,s)$(ord(t)>1 and ss(s))..  pHVAC(t,s) =l= M*(2-f_b3(t)-f_h(t));
f_ancbin19(t,s)$(ord(t)>1 and ss(s))..  -pHVAC(t,s) =l= M*(2-f_b3(t)-f_h(t));
f_ancbin20(t,s)$(ord(t)>1 and ss(s))..  rmTemp(t,s)-calRmTemp_noHeat(t,s) =l= M*(2-f_b3(t)-f_h(t));
f_ancbin21(t,s)$(ord(t)>1 and ss(s))..  calRmTemp_noHeat(t,s)-rmTemp(t,s) =l= M*(2-f_b3(t)-f_h(t));
f_ancbin22(t,s)$(ord(t)>1 and ss(s))..  calRmTemp_noHeat(t,s)-rmTempSP(t) =l= M*(1-f_h(t)+f_b3(t));
f_ancbin23(t,s)$(ord(t)>1 and ss(s))..  ratedHVACPower('Heating')-calPHVAC_HeatSP(t,s) =l=M*(f_b3(t)+2-f_b4(t)-f_h(t));
f_ancbin24(t,s)$(ord(t)>1 and ss(s))..  pHVAC(t,s)-ratedHVACPower('Heating') =l= M*(f_b3(t)+2-f_b4(t)-f_h(t));
f_ancbin25(t,s)$(ord(t)>1 and ss(s))..  ratedHVACPower('Heating')-pHVAC(t,s) =l= M*(f_b3(t)+2-f_b4(t)-f_h(t));
f_ancbin26(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-calRmTemp_ratedHeat(t,s) =l= M*(f_b3(t)+2-f_b4(t)-f_h(t));
f_ancbin27(t,s)$(ord(t)>1 and ss(s)).. calRmTemp_ratedHeat(t,s)-rmTemp(t,s) =l= M*(f_b3(t)+2-f_b4(t)-f_h(t));
f_ancbin28(t,s)$(ord(t)>1 and ss(s)).. calPHVAC_HeatSP(t,s)-ratedHVACPower('Heating') =l= M*(f_b3(t)+f_b4(t)+1-f_h(t));
f_ancbin29(t,s)$(ord(t)>1 and ss(s)).. pHVAC(t,s)-calPHVAC_HeatSP(t,s) =l= M*(f_b3(t)+f_b4(t)+1-f_h(t));
f_ancbin30(t,s)$(ord(t)>1 and ss(s)).. calPHVAC_HeatSP(t,s)-pHVAC(t,s) =l= M*(f_b3(t)+f_b4(t)+1-f_h(t));
f_ancbin31(t,s)$(ord(t)>1 and ss(s)).. rmTemp(t,s)-rmTempSP(t) =l= M*(f_b3(t)+f_b4(t)+1-f_h(t));
f_ancbin32(t,s)$(ord(t)>1 and ss(s)).. rmTempSP(t)-rmTemp(t,s) =l= M*(f_b3(t)+f_b4(t)+1-f_h(t));

f_branch1(t,s)$((ord(t)>1  and ss(s))) .. f_h(t)=e=0;

************************   WH is OFF  *************************************
f_ubpWHOFF1(nWH,t,ss)$(ord(t)>1).. pWH(nWH,t,ss) =l= M*f_WHON(nWH,t);
f_ubpWHOFF2(nWH,t,ss)$(ord(t)>1).. -pWH(nWH,t,ss) =l= M*f_WHON(nWH,t);

*added on 06-30-14
f_lbWHSetPoint1(nWH,t,ss)$(ord(t)>1).. WHTempSP(nWH,t)-desiredTEMP(t,'DESIRED_WH_TEMP_LB')=l=M*f_WHON(nWH,t);
f_lbWHSetPoint2(nWH,t,ss)$(ord(t)>1).. -WHTempSP(nWH,t)+desiredTEMP(t,'DESIRED_WH_TEMP_LB')=l=M*f_WHON(nWH,t);



*********************************   WH Heating   ***********************************************************************
f_calPWHSP1(nWH,t,ss)$(ord(t)>1)..  calPWH_HeatSP(nWH,t,ss)-(WHTempSP(nWH,t)-coWHTemp(nWH)*WHTemp(nWH,t-1,ss)-coWHAmbTemp(nWH)*WHAmbTemp(nWH,t,ss)-coWaterUsage(nWH)*waterUsage(t,ss))/coWHPowerToTemp(nWH) =l= M*(1-f_WHON(nWH,t));
f_calPWHSP2(nWH,t,ss)$(ord(t)>1)..  -calPWH_HeatSP(nWH,t,ss)+(WHTempSP(nWH,t)-coWHTemp(nWH)*WHTemp(nWH,t-1,ss)-coWHAmbTemp(nWH)*WHAmbTemp(nWH,t,ss)-coWaterUsage(nWH)*waterUsage(t,ss))/coWHPowerToTemp(nWH) =l= M*(1-f_WHON(nWH,t));
f_ubpWHONHeat(nWH,t,ss).. pWH(nWH,t,ss)=l=ratedWHPower(nWH)*f_WHON(nWH,t);
f_lbpWHONHeat(nWH,t,ss).. pWH(nWH,t,ss)=g=minWHPower(nWH)*f_WHON(nWH,t);

*added on 03-06-2017
f_extraWHCon1(nWH,t,ss)$(ord(t)>1)..  WHTempSP(nWH,t)-calWHTemp_noHeat(nWH,t,ss) =g= -M*(1-f_WHON(nWH,t));
f_extraWHCon2(nWH,t,ss)$(ord(t)>1)..  calWHTemp_noHeat(nWH,t,ss)-epsilon-WHTempSP(nWH,t) =g= -M*f_WHON(nWH,t);


f_ancbin1WH(nWH,t,ss)$(ord(t)>1)..  WHTempSP(nWH,t)-calWHTemp_noHeat(nWH,t,ss) =l= M*(2-f_bbb1(nWH,t)-f_WHON(nWH,t));
f_ancbin2WH(nWH,t,ss)$(ord(t)>1)..  pWH(nWH,t,ss) =l= M*(2-f_bbb1(nWH,t)-f_WHON(nWH,t));
f_ancbin3WH(nWH,t,ss)$(ord(t)>1)..  -pWH(nWH,t,ss) =l= M*(2-f_bbb1(nWH,t)-f_WHON(nWH,t));
f_ancbin4WH(nWH,t,ss)$(ord(t)>1)..  WHTemp(nWH,t,ss)-calWHTemp_noHeat(nWH,t,ss) =l= M*(2-f_bbb1(nWH,t)-f_WHON(nWH,t));
f_ancbin5WH(nWH,t,ss)$(ord(t)>1)..  calWHTemp_noHeat(nWH,t,ss)-WHTemp(nWH,t,ss) =l= M*(2-f_bbb1(nWH,t)-f_WHON(nWH,t));
f_ancbin6WH(nWH,t,ss)$(ord(t)>1)..  calWHTemp_noHeat(nWH,t,ss)-WHTempSP(nWH,t) =l= M*(1+f_bbb1(nWH,t)-f_WHON(nWH,t));
f_ancbin7WH(nWH,t,ss)$(ord(t)>1)..  ratedWHPower(nWH)-calPWH_HeatSP(nWH,t,ss) =l=M*(f_bbb1(nWH,t)+2-f_bbb2(nWH,t)-f_WHON(nWH,t));
f_ancbin8WH(nWH,t,ss)$(ord(t)>1)..  pWH(nWH,t,ss)-ratedWHPower(nWH) =l= M*(f_bbb1(nWH,t)+2-f_bbb2(nWH,t)-f_WHON(nWH,t));
f_ancbin9WH(nWH,t,ss)$(ord(t)>1)..  ratedWHPower(nWH)-pWH(nWH,t,ss) =l= M*(f_bbb1(nWH,t)+2-f_bbb2(nWH,t)-f_WHON(nWH,t));
f_ancbin10WH(nWH,t,ss)$(ord(t)>1).. WHTemp(nWH,t,ss)-calWHTemp_ratedHeat(nWH,t,ss) =l= M*(f_bbb1(nWH,t)+2-f_bbb2(nWH,t)-f_WHON(nWH,t));
f_ancbin11WH(nWH,t,ss)$(ord(t)>1).. calWHTemp_ratedHeat(nWH,t,ss)-WHTemp(nWH,t,ss) =l= M*(f_bbb1(nWH,t)+2-f_bbb2(nWH,t)-f_WHON(nWH,t));
f_ancbin12WH(nWH,t,ss)$(ord(t)>1).. calPWH_HeatSP(nWH,t,ss)-ratedWHPower(nWH) =l= M*(f_bbb1(nWH,t)+f_bbb2(nWH,t)+1-f_WHON(nWH,t));
f_ancbin13WH(nWH,t,ss)$(ord(t)>1).. pWH(nWH,t,ss)-calPWH_HeatSP(nWH,t,ss) =l= M*(f_bbb1(nWH,t)+f_bbb2(nWH,t)+1-f_WHON(nWH,t));
f_ancbin14WH(nWH,t,ss)$(ord(t)>1).. calPWH_HeatSP(nWH,t,ss)-pWH(nWH,t,ss) =l= M*(f_bbb1(nWH,t)+f_bbb2(nWH,t)+1-f_WHON(nWH,t));
f_ancbin15WH(nWH,t,ss)$(ord(t)>1).. WHTemp(nWH,t,ss)-WHTempSP(nWH,t) =l= M*(f_bbb1(nWH,t)+f_bbb2(nWH,t)+1-f_WHON(nWH,t));
f_ancbin16WH(nWH,t,ss)$(ord(t)>1).. WHTempSP(nWH,t)-WHTemp(nWH,t,ss) =l= M*(f_bbb1(nWH,t)+f_bbb2(nWH,t)+1-f_WHON(nWH,t));
***************************************** End WH Constraints ***********************************************

****************************************** EV Constraints **************************************************

f_EVSOCdynamicEq1Charge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. EVSOC(nEV,t,ss)-EVSOC(nEV,t-1,ss)-EVEff(nEV)*EVCharRate(nEV,t,ss)*intervalLength/EVCapac(nEV) =l= M*(1-f_EVChargeState(nEV,t));
f_EVSOCdynamicEq2Charge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. -EVSOC(nEV,t,ss)+EVSOC(nEV,t-1,ss)+EVEff(nEV)*EVCharRate(nEV,t,ss)*intervalLength/EVCapac(nEV) =l= M*(1-f_EVChargeState(nEV,t));
f_EVSOCdynamicEq1Discharge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. EVSOC(nEV,t,ss)-EVSOC(nEV,t-1,ss)+EVDischarRate(nEV,t,ss)*intervalLength/EVCapac(nEV)/EVEff(nEV)=l= M*(1-f_EVDischargeState(nEV,t));
f_EVSOCdynamicEq2Discharge(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1).. -EVSOC(nEV,t,ss)+EVSOC(nEV,t-1,ss)-EVDischarRate(nEV,t,ss)*intervalLength/EVCapac(nEV)/EVEff(nEV)=l= M*(1-f_EVDischargeState(nEV,t));
f_EVSOCdynamicEq1Idle(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1)..  EVSOC(nEV,t,ss)-EVSOC(nEV,t-1,ss)=l= M*(f_EVChargeState(nEV,t)+f_EVDischargeState(nEV,t));
f_EVSOCdynamicEq2Idle(nEV,t,ss)$(ord(t)>=StartChargeTime(nEV)+2 and ord(t)<=StopChargeTime(nEV)+1)..  -EVSOC(nEV,t,ss)+EVSOC(nEV,t-1,ss)=l= M*(f_EVChargeState(nEV,t)+f_EVDischargeState(nEV,t));
f_EVubChargeCon(nEV,t,ss)$(ord(t)>1)..   EVCharRate(nEV,t,ss) =l= maxEVCharge(nEV)*f_EVChargeState(nEV,t);
f_EVlbChargeCon(nEV,t,ss)$(ord(t)>1)..   EVCharRate(nEV,t,ss) =g= minEVCharge(nEV)*f_EVChargeState(nEV,t);
f_EVubDischargeCon(nEV,t,ss)$(ord(t)>1)..   EVDischarRate(nEV,t,ss) =l= maxEVDischarge(nEV)*f_EVDischargeState(nEV,t);
f_EVlbDischargeCon(nEV,t,ss)$(ord(t)>1)..   EVDischarRate(nEV,t,ss) =g= minEVDischarge(nEV)*f_EVDischargeState(nEV,t);
f_EVStateCon(nEV,t,ss)$(ord(t)>1)..  f_EVChargeState(nEV,t)+f_EVDischargeState(nEV,t) =l= 1;


************************************************************************************************************
*********************************** Storage constraints ****************************************************
f_storSOCdynamicEq1Charge(nStorage,t,ss)$(ord(t)>1).. storSOC(nStorage,t,ss)-storSOC(nStorage,t-1,ss)-storEff(nStorage)*storCharRate(nStorage,t,ss)*intervalLength/storCapac(nStorage) =l= M*(1-f_storChargeState(nStorage,t));
f_storSOCdynamicEq2Charge(nStorage,t,ss)$(ord(t)>1).. -storSOC(nStorage,t,ss)+storSOC(nStorage,t-1,ss)+storEff(nStorage)*storCharRate(nStorage,t,ss)*intervalLength/storCapac(nStorage) =l= M*(1-f_storChargeState(nStorage,t));
f_storSOCdynamicEq1Discharge(nStorage,t,ss)$(ord(t)>1).. storSOC(nStorage,t,ss)-storSOC(nStorage,t-1,ss)+storDischarRate(nStorage,t,ss)*intervalLength/storCapac(nStorage)/storEff(nStorage)=l= M*(1-f_storDischargeState(nStorage,t));
f_storSOCdynamicEq2Discharge(nStorage,t,ss)$(ord(t)>1).. -storSOC(nStorage,t,ss)+storSOC(nStorage,t-1,ss)-storDischarRate(nStorage,t,ss)*intervalLength/storCapac(nStorage)/storEff(nStorage)=l= M*(1-f_storDischargeState(nStorage,t));
f_storSOCdynamicEq1Idle(nStorage,t,ss)$(ord(t)>1)..  storSOC(nStorage,t,ss)-storSOC(nStorage,t-1,ss)=l= M*(f_storChargeState(nStorage,t)+f_storDischargeState(nStorage,t));
f_storSOCdynamicEq2Idle(nStorage,t,ss)$(ord(t)>1)..  -storSOC(nStorage,t,ss)+storSOC(nStorage,t-1,ss)=l= M*(f_storChargeState(nStorage,t)+f_storDischargeState(nStorage,t));
f_storubChargeCon(nStorage,t,ss)$(ord(t)>1)..   storCharRate(nStorage,t,ss) =l= maxstorCharge(nStorage)*f_storChargeState(nStorage,t);
f_storlbChargeCon(nStorage,t,ss)$(ord(t)>1)..   storCharRate(nStorage,t,ss) =g= minStorCharge(nStorage)*f_storChargeState(nStorage,t);
f_storubDischargeCon(nStorage,t,ss)$(ord(t)>1)..   storDischarRate(nStorage,t,ss) =l= maxStorDischarge(nStorage)*f_storDischargeState(nStorage,t);
f_storlbDischargeCon(nStorage,t,ss)$(ord(t)>1)..   storDisCharRate(nStorage,t,ss) =g= minStorDischarge(nStorage)*f_storDischargeState(nStorage,t);
f_storStateCon(nStorage,t,ss)$(ord(t)>1)..  f_storChargeState(nStorage,t)+f_storDischargeState(nStorage,t) =l= 1;

*********************************** End Storage Constraints ************************************************


************************** added on 12-10-2014
positive variable posDiff(t);
positive variable negDiff(t);
binary variable ifrated(t),ifzero(t);
variable sumObjDisp;
equations
SumobjdispDef
ABSDIFF
SPTOUB1
SPTOUB2
SPTOUB3
SPTOUB4
SPTOUB5
SPTOLB1
SPTOLB2
SPTOLB3
SPTOLB4
SPTOLB5;


ABSDIFF(t)$(ord(t)>1).. rmTempSP(t)-rmTempUB(t)=e=posDiff(t)-negDiff(t);

SPTOUB1(t)$(ord(t)>1).. rmTempSP(t)-rmTempUB(t)=l=(1-ifzero(t))*M;
SPTOUB2(t)$(ord(t)>1).. rmTempUB(t)-rmTempSP(t)=l=(1-ifzero(t))*M;
SPTOUB3(t,s)$(ord(t)>1 and ss(s)).. epsilon-pHVAC(t,s)=l=ifzero(t)*M;
SPTOUB4(t,s)$(ord(t)>1 and ss(s)).. pHVAC(t,s)=l=(1-ifzero(t))*M;
SPTOUB5(t)$(ord(t)>1).. ifzero(t)+f_ON(t)=e=1;
SPTOLB1(t,s)$(ord(t)>1 and ss(s)).. pHVAC(t,s)-ratedHVACPower('Cooling')=l=(1-ifrated(t))*M;
SPTOLB2(t,s)$(ord(t)>1 and ss(s)).. ratedHVACPower('Cooling')-pHVAC(t,s)=l=(1-ifrated(t))*M;
SPTOLB5(t,s)$(ord(t)>1 and ss(s)).. pHVAC(t,s)+epsilon-ratedHVACPower('Cooling')=l=ifrated(t)*M;
SPTOLB3(t)$(ord(t)>1).. rmTempLB(t)-rmTempSP(t)=l=(1-ifrated(t))*M;
SPTOLB4(t)$(ord(t)>1).. rmTempSP(t)-rmTempLB(t)=l=(1-ifrated(t))*M;

SumObjdispDef..  sumObjDisp =e= sumObj+sum(t$(ord(t)=2),0.01*(posDiff(t)+negDiff(t)));
*********************** added on 12-10-2014

*MINIMIZE OVERALL MODEL DISCOMFORT TO GET OVERALL MODEL ENERGY COST UPPER BOUND
model SHEMS_GET4OBJUB /

SPTOUB1
SPTOUB2
SPTOUB3
SPTOUB4
SPTOLB1
SPTOLB2
SPTOLB3
SPTOLB4
SPTOLB5


objDefEnerCost
objDefDiscom
objDefElecConsump
objDefPeakLoad
elecLoadBalanceCon

$IFI "%HVAC_INC%"=="YES" inirmTempcon f_thermEqONCool1 f_thermEqONCool2  ubrmtemp lbrmtemp
$IFI "%HVAC_INC%"=="YES" f_ubpHVACONCool f_lbpHVACONCool f_ubpHVACOFF1 f_ubpHVACOFF2 calRmTempNoCooling calRmTempRatedCooling f_calPHVACSP1 f_calPHVACSP2
*$IFI "%HVAC_INC%"=="YES" f_ancbin1 f_ancbin2 f_ancbin3 f_ancbin4 f_ancbin5 f_ancbin6 f_ancbin7 f_ancbin8 f_ancbin9 f_ancbin10 f_ancbin11 f_ancbin12 f_ancbin13 f_ancbin14 f_ancbin15 f_ancbin16
$IFI "%SECOND_THIRD_RUN_TEMPINBOUND%"=="YES" ubrmTemp1 lbrmTemp1
$IFI "%SPINBOUND%"=="YES" lbrmSetTemp ubrmSetTemp
$IFI "%ONLYCOOLING%"=="YES" f_branch1




$IFI "%WH_INC%"=="YES" iniWHTempcon thermEqWH ubWHtemp lbWHtemp ubWHSetTemp lbWHSetTemp f_ubpWHONHeat f_ubpWHOFF1 f_ubpWHOFF2 calWHTempNoHeating f_extraWHCon1 f_extraWHCon2
$IFI "%WH_INC%"=="YES" calWHTempRatedHeating f_calPWHSP1 f_calPWHSP2 f_ancbin1WH ancbin2WH f_ancbin3WH f_ancbin4WH f_ancbin5WH f_ancbin6WH f_ancbin7WH f_ancbin8WH f_ancbin9WH f_ancbin10WH
*$IFI "%WH_INC%"=="YES" f_ancbin11WH f_ancbin12WH f_ancbin13WH f_ancbin14WH f_ancbin15WH f_ancbin16WH f_lbWHSetPoint1 f_lbWHSetPoint2 AmbTempCal f_lbpWHONHeat
$IFI "%TEMPINBOUND%"=="YES" ubWHtemp1 lbWHtemp1

$IFI "%EV_INC%"=="YES" f_EVSOCdynamicEq1Charge f_EVSOCdynamicEq2Charge f_EVSOCdynamicEq1Discharge f_EVSOCdynamicEq2Discharge f_EVSOCdynamicEq1Idle f_EVSOCdynamicEq2Idle
$IFI "%EV_INC%"=="YES" EVOfflineEq1 EVOfflineEq2 EViniSOCEq EVendSOCEq f_EVubChargeCon f_EVlbChargeCon f_EVubDischargeCon f_EVlbDischargeCon f_EVStateCon EVubSOC EVlbSOC

$IFI "%STOR_INC%"=="YES" f_storSOCdynamicEq1Charge f_storSOCdynamicEq2Charge f_storSOCdynamicEq1Discharge f_storSOCdynamicEq2Discharge f_storSOCdynamicEq1Idle storUbSOC storLbSOC
$IFI "%STOR_INC%"=="YES" f_storSOCdynamicEq2Idle storIniSOCEq storEndSOCEq f_storUbChargeCon f_storLbChargeCon f_storUbDischargeCon f_storLbDischargeCon storSOCCon f_storStateCon

$IFI "%FIXSPTEST%"=="YES" fixSetTemp
$IFI "%FIXSPTEST%"=="YES" fixWHSetTemp
$IFI "%FIXSPTEST%"=="YES" fixFRSetTemp

/;
SHEMS_GET4OBJUB.OptCR=0.01;
SHEMS_GET4OBJUB.ResLim=60;

* if not single objctive and energy cost is no-zero
*if(coObj('ENERGY_COST')>0 and ifSingleObjective=0,

*solve SHEMS_GET4OBJUB using mip minimizing discom;
*UbEnergyCost=energyCost.l;
*ubElecConsump=ElecConsump.l;
*ubPeakLoad=PeakLoad.l;
*);

*display 'Second Run Results (Minimizing overall model discomfort)';
*display objcounter,energyCost.l, discom.l, ubEnergyCost,ubElecConsump,ubCarbFoot,ubPeakLoad,ubDiscom,pHVAC.l,rmTempSP.l;

objDefSumObj..  sumObj =e= energyCost
                           +discom;
*                           +coObj('ELEC_CONSUMPTION')*elecConsump/(ubElecConsump+epsilon)
*                           +coObj('PEAK_LOAD')*peakLoad/(ubPeakLoad+epsilon);


EVEnergyCostDef.. EVEnergyCost =e= sum((nEV,t,ss)$(ord(t)>1),sceProbability(ss)*EPrice(t,ss)*(EVCharRate(nEV,t,ss)-EVDischarRate(nEV,t,ss))*intervalLength);
StorEnergyCostDef.. StorEnergyCost =e= sum((nStorage,t,ss)$(ord(t)>1),sceProbability(ss)*EPrice(t,ss)*(storCharRate(nStorage,t,ss)-storDischarRate(nStorage,t,ss))*intervalLength);
PVEnergyCostDef.. PVEnergyCost =e= 0
$IFI "%PV_INC%"=="YES"             +sum((t,ss)$(ord(t)>1),-sceProbability(ss)*dispSolarGen(t,ss)*EPrice(t,ss)*intervalLength)
;
WindEnergyCostDef.. WindEnergycost =e= 0
$IFI "%WIND_INC%"=="YES"               +sum((t,ss)$(ord(t)>1),-sceProbability(ss)*windGen(t,ss)*EPrice(t,ss)*intervalLength)
;
NCLEnergyCostDef..  NCLEnergycost =e=  0
$IFI "%NCL_INC%"=="YES"                +sum((t,ss)$(ord(t)>1),sceProbability(ss)*EPrice(t,ss)*nonControlLoad(t,ss)*intervalLength)
;


*final run
**************************
model SHEMS_overall /
SPTOUB1
SPTOUB2
SPTOUB3
SPTOUB4
SPTOLB1
SPTOLB2
SPTOLB3
SPTOLB4
SPTOLB5

objDefSumObj
objDefEnerCost
objDefDiscom
objDefElecConsump
objDefPeakLoad
elecLoadBalanceCon

$IFI "%HVAC_INC%"=="YES" inirmTempcon f_thermEqONCool1 f_thermEqONCool2  ubrmtemp lbrmtemp
$IFI "%HVAC_INC%"=="YES" f_ubpHVACONCool f_lbpHVACONCool f_ubpHVACOFF1 f_ubpHVACOFF2 calRmTempNoCooling calRmTempRatedCooling f_calPHVACSP1 f_calPHVACSP2
*$IFI "%HVAC_INC%"=="YES" f_ancbin1 f_ancbin2 f_ancbin3 f_ancbin4 f_ancbin5 f_ancbin6 f_ancbin7 f_ancbin8 f_ancbin9 f_ancbin10 f_ancbin11 f_ancbin12 f_ancbin13 f_ancbin14 f_ancbin15 f_ancbin16
$IFI "%SECOND_THIRD_RUN_TEMPINBOUND%"=="YES" ubrmTemp1 lbrmTemp1
$IFI "%SPINBOUND%"=="YES" lbrmSetTemp ubrmSetTemp
$IFI "%ONLYCOOLING%"=="YES" f_branch1



$IFI "%WH_INC%"=="YES" iniWHTempcon thermEqWH ubWHtemp lbWHtemp ubWHSetTemp lbWHSetTemp f_ubpWHONHeat f_ubpWHOFF1 f_ubpWHOFF2 calWHTempNoHeating f_extraWHCon1 f_extraWHCon2
$IFI "%WH_INC%"=="YES" calWHTempRatedHeating f_calPWHSP1 f_calPWHSP2 f_ancbin1WH ancbin2WH f_ancbin3WH f_ancbin4WH f_ancbin5WH f_ancbin6WH f_ancbin7WH f_ancbin8WH f_ancbin9WH f_ancbin10WH
*$IFI "%WH_INC%"=="YES" f_ancbin11WH f_ancbin12WH f_ancbin13WH f_ancbin14WH f_ancbin15WH f_ancbin16WH f_lbWHSetPoint1 f_lbWHSetPoint2 AmbTempCal f_lbpWHONHeat
$IFI "%TEMPINBOUND%"=="YES" ubWHtemp1 lbWHtemp1

$IFI "%EV_INC%"=="YES" f_EVSOCdynamicEq1Charge f_EVSOCdynamicEq2Charge f_EVSOCdynamicEq1Discharge f_EVSOCdynamicEq2Discharge f_EVSOCdynamicEq1Idle f_EVSOCdynamicEq2Idle
$IFI "%EV_INC%"=="YES" EVOfflineEq1 EVOfflineEq2 EViniSOCEq EVendSOCEq f_EVubChargeCon f_EVlbChargeCon f_EVubDischargeCon f_EVlbDischargeCon f_EVStateCon EVubSOC EVlbSOC

$IFI "%STOR_INC%"=="YES" f_storSOCdynamicEq1Charge f_storSOCdynamicEq2Charge f_storSOCdynamicEq1Discharge f_storSOCdynamicEq2Discharge f_storSOCdynamicEq1Idle storUbSOC storLbSOC
$IFI "%STOR_INC%"=="YES" f_storSOCdynamicEq2Idle storIniSOCEq storEndSOCEq f_storUbChargeCon f_storLbChargeCon f_storUbDischargeCon f_storLbDischargeCon storSOCCon f_storStateCon

$IFI "%DISPAT_SOLAR%"=="YES" dispSolarUB

$IFI "%EVPOWER_SMOOTH%"=="YES" EVCharABS
$IFI "%EVPOWER_SMOOTH%"=="YES" EVDischarABS
$IFI "%STOR_INC%"=="YES" storCharABS
$IFI "%STOR_INC%"=="YES" storDischarABS



****** included for battery degradation ******
$IFI "%EVBD%"=="YES" EVCostBD_Q_SOC_Con
$IFI "%EVBD%"=="YES" EVCostBD_P_T_Con
$IFI "%EVBD%"=="YES" EVCostBD_Q_T_Con
$IFI "%EVBD%"=="YES" EVCostBD_UP_Con1
$IFI "%EVBD%"=="YES" EVCostBD_UP_Con2
$IFI "%EVBD%"=="YES" debug_1
$IFI "%EVBD%"=="YES" debug_2
************** End ***************************

$IFI "%DW_INC%"=="YES" f_dwStateTransCon f_dwShutDnTimeCon1 dwShutDnTimeCon2 f_dwShutDnTimeCon3 f_dwStartUpTimeCon1 dwStartUpTimeCon2 f_dwStartUpTimeCon3 f_dwMinDnTime f_dwMinUpTime
$IFI "%DW_INC%"=="YES" dwIniStateCon dwIniDnTimeCon dwIniUpTimeCon f_dwUbPowerCon f_dwLbPowerCon dwReqEnergyCon

$IFI "%PP_INC%"=="YES" f_ppStateTransCon f_ppShutDnTimeCon1 ppShutDnTimeCon2 f_ppShutDnTimeCon3 f_ppStartUpTimeCon1 ppStartUpTimeCon2 f_ppStartUpTimeCon3 f_ppMinDnTime f_ppMinUpTime
$IFI "%PP_INC%"=="YES" ppIniStateCon ppIniDnTimeCon ppIniUpTimeCon f_ppUbPowerCon f_ppLbPowerCon ppReqEnergyCon

$IFI "%CWD_INC%"=="YES" f_cwdStateTransCon f_cwdShutDnTimeCon1 cwdShutDnTimeCon2 f_cwdShutDnTimeCon3 f_cwdStartUpTimeCon1 cwdStartUpTimeCon2 f_cwdStartUpTimeCon3 f_cwdMinDnTime
$IFI "%CWD_INC%"=="YES" f_cwdMinUpTime cwdIniStateCon cwdIniDnTimeCon cwdIniUpTimeCon f_cwdUbPowerCon f_cwdLbPowerCon cwdReqEnergyCon

$IFI "%LIGHTING_INC%"=="YES" f_ltUbPowerCon f_ltLbPowerCon ltReqCon

$IFI "%CHP_INC%"=="YES" f_chpMinRatio f_chpMaxRatio chpPowerEq chpHeatEq chpGasEq

$IFI "%FIXSPTEST%"=="YES" fixSetTemp
$IFI "%FIXSPTEST%"=="YES" fixWHSetTemp

*added on 07-09-14

HVACEnergyCostDef
WHEnergyCostDef
EVEnergyCostDef
StorEnergyCostDef
PVEnergyCostDef
WindEnergyCostDef
NCLEnergyCostDef
/;

SHEMS_overall.OptCR=0.0001;
SHEMS_overall.ResLim=300;



solve SHEMS_overall using mip minimizing sumObj;


$IFI "%HVAC_INC%"=="YES" if(f_ON.l('1')=1,
$IFI "%HVAC_INC%"=="YES"  coolingSP=rmTempSP.l('1');
$IFI "%HVAC_INC%"=="YES"  heatingSP=desiredTEMP('1','DESIRED_HEATING_TEMP');
******Li******
$IFI "%HVAC_INC%"=="YES" display coolingSP;
**********************************
$IFI "%HVAC_INC%"=="YES" else
$IFI "%HVAC_INC%"=="YES"  heatingSP=rmTempSP.l('1');
$IFI "%HVAC_INC%"=="YES"  coolingSP=rmTempSP.l('1');
******Li******
$IFI "%HVAC_INC%"=="YES" display coolingSP;
$IFI "%HVAC_INC%"=="YES" display heatingSP;
**********************************
$IFI "%HVAC_INC%"=="YES" );

Parameter WHSP;
$IFI "%WH_INC%"=="YES" WHSP=WHTempSP.l('WH_1','1');

$IFI "%WH_INC%"=="YES" display WHSP;

$IFI "%EV_INC%"=="YES" EVCharRateResult = EVCharRate.l('EV_1','1','BASE_CASE');

$IFI "%EV_INC%"=="YES" display EVCharRateResult;
$IFI "%EV_INC%"=="YES" display EVCharRate.l, EVSOC.l;

**************************
* end final run

execute_unload "Results.gdx" rmTemp.l,rmTempSP.l,pHVAC.l,
WHTemp.l,WHTempSP.l,pWH.l,WHON.l,t,s,ss,f_ON.l,f_c.l,WHSP,
nWH,nEV nStorage rmTempUB rmTempLB desiredRmTemp
WHTempUB WHTempLB desiredWHTemp EVCharRate EVDischarRate EVSOC storCharRate storDischarRate storSOC
sumObj energyCost elecConsump carbFoot peakLoad discom EPrice tempOut HVACEnergyCost  pGridSlack1.l
WHEnergyCost hotWaterUsage EVEnergyCost  StorEnergyCost PVEnergyCost  WindEnergyCost  NCLEnergyCost sceProbability elecPricef outTempf hotWaterUsagef nObj,coObj, objWeight, windGen,dispSolarGen,heatingSP,coolingSP,pGrid,WHPar,ubEnergyCost,ubDiscom;
