create database healthcare;
use healthcare;

select * from D_HCP;
select * from D_DRG;
select * From D_FDA;
select * from D_REP;
select * from D_REP_TGT;
select * from D_RX_PHM;
select * from D_HCO;
select * from D_HCP;
select * from D_PTNT;
select * from D_PROD;
select * from F_CLAIM;
select * from F_SLS;

## Question 1 - Find reps who have achieved their targets to incentivize 

WITH  DETAIL as
(
select rep_id,rep_name,
case 
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/01/22','%d/%m/%Y') and str_to_date('31/03/22','%d/%m/%Y')  then 'Q1'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/04/22','%d/%m/%Y') and str_to_date('30/06/22','%d/%m/%Y')   then 'Q2'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/07/22','%d/%m/%Y') and str_to_date('30/09/22','%d/%m/%Y')   then 'Q3'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/10/22','%d/%m/%Y') and str_to_date('31/12/22','%d/%m/%Y')  then 'Q4'
end as Quarter ,count(distinct detail_id) as DETAIL_COUNT from D_REP REP  
where detail_id!='' group by rep_id,rep_name, 
case 
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/01/22','%d/%m/%Y') and str_to_date('31/03/22','%d/%m/%Y')  then 'Q1'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/04/22','%d/%m/%Y') and str_to_date('30/06/22','%d/%m/%Y')   then 'Q2'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/07/22','%d/%m/%Y') and str_to_date('30/09/22','%d/%m/%Y')   then 'Q3'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/10/22','%d/%m/%Y') and str_to_date('31/12/22','%d/%m/%Y')  then 'Q4'
end
)
,CAL as
(
select rep_id,rep_name,
case 
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/01/22','%d/%m/%Y') and str_to_date('31/03/22','%d/%m/%Y')  then 'Q1'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/04/22','%d/%m/%Y') and str_to_date('30/06/22','%d/%m/%Y')   then 'Q2'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/07/22','%d/%m/%Y') and str_to_date('30/09/22','%d/%m/%Y')   then 'Q3'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/10/22','%d/%m/%Y') and str_to_date('31/12/22','%d/%m/%Y')  then 'Q4'
end as Quarter ,count(distinct call_id) as CALL_COUNT from D_REP REP  
where call_id!='' group by rep_id,rep_name, 
case 
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/01/22','%d/%m/%Y') and str_to_date('31/03/22','%d/%m/%Y')  then 'Q1'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/04/22','%d/%m/%Y') and str_to_date('30/06/22','%d/%m/%Y')   then 'Q2'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/07/22','%d/%m/%Y') and str_to_date('30/09/22','%d/%m/%Y')   then 'Q3'
when str_to_date(entry_date,'%d/%m/%Y') between str_to_date('01/10/22','%d/%m/%Y') and str_to_date('31/12/22','%d/%m/%Y')  then 'Q4'
end
)
,TGT as
(
select REP_ID,'Q1' as quarter,Q1_target_call as target_call,Q1_target_detail as target_detail from D_REP_TGT
UNION
select REP_ID,'Q2' as quarter,Q2_target_call as target_call,Q2_target_detail as target_detail from D_REP_TGT
UNION 
select REP_ID,'Q3' as quarter,Q3_target_call as target_call,Q3_target_detail as target_detail from D_REP_TGT
UNION
select REP_ID,'Q4' as quarter,Q4_target_call as target_call,Q4_target_detail as target_detail from D_REP_TGT
)
,TGT_FLAG as
( 
select distinct CAL.rep_id,CAL.rep_name, CAL.quarter,CAL.CALL_COUNT as calls_made,TGT.target_call,DETAIL.DETAIL_COUNT as details_made,TGT.target_detail 
, case when CAL.CALL_COUNT>=TGT.target_call then 'Yes' else 'No' end as Call_targets_achieved
, case when DETAIL.DETAIL_COUNT>=TGT.target_detail then 'Yes' else 'No' end as Details_targets_achieved
from CAL  left join DETAIL  on CAL.rep_id=DETAIL.rep_id and CAL.rep_name=DETAIL.rep_name 
and CAL.quarter=DETAIL.quarter left join TGT on CAL.rep_id=TGT.rep_id and TGT.quarter=CAL.quarter
)
select rep_id,rep_name,quarter,calls_made,target_call,details_made,target_detail from TGT_FLAG where Details_targets_achieved='Yes' and Call_targets_achieved='Yes'
;


## Question 2 - Top 2 HCPs with maximum prescription writing 

select PTNT.NPI,HCP.HCP_name,HCP.city,HCO.HCO_name,count(distinct PTNT.RX_ID) as prescriptions_count from D_PTNT PTNT left join D_HCP HCP on PTNT.NPI=HCP.NPI 
left join D_HCO HCO on HCP.affiliation_id=HCO.HCO_ID
group by PTNT.NPI,HCP.HCP_name,HCP.city,HCO.hco_name order by prescriptions_count desc limit 2;


## Question 3 - Top 3 Territories with maximum sales

select  REP.territory_id,REP.territory_name, sum(SLS.amount) as amount from F_SLS SLS left join D_PTNT PTNT on SLS.patient_id=ptnt.patient_id left join D_REP REP on REP.NPI=PTNT.NPI
group by REP.territory_id,REP.territory_name order by sum(SLS.amount) desc limit 3;


## Question 4 - Market share by products

WITH product_sum as 
(
select  REP.product_id,PROD.product_name,PROD.product_form, sum(SLS.amount) as amount from F_SLS SLS left join D_PTNT PTNT on SLS.patient_id=ptnt.patient_id 
left join D_REP REP on REP.NPI=PTNT.NPI
left join D_PROD PROD on REP.product_id=prod.product_id
group by REP.product_id,PROD.product_name,PROD.product_form order by sum(SLS.amount)
)
,total_sum as 
(
select sum(amount) as total from product_sum
)
select product_id,product_name,product_form,amount,(100*amount)/(select total from total_sum) as market_share from product_sum;

