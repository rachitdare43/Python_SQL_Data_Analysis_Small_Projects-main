-- Merging Tables 
SELECT *
  FROM Absenteeism_at_work a
  left join compensation c on a.ID=c.ID
  left join Reasons r on r.Number=a.Reason_for_absence;


---find the healthiest employess for the bonus
select * from Absenteeism_at_work
where Social_smoker=0 and Social_drinker=0
and Body_mass_index<25 and
Absenteeism_time_in_hours < (select AVG(Absenteeism_time_in_hours) from Absenteeism_at_work);

---find no of nonsmoker employees
select count(*) as Non_Smoker_employees from Absenteeism_at_work
where Social_smoker=0;

-- EMPLOYEE Who NEVER TAKEN LEAVE IN YEAR
select ID
from Absenteeism_at_work
WHERE Absenteeism_time_in_hours=0;

-- Employee Absenteeism Count by Month
WITH cte as (select Month_of_absence,count(*)  as Total_Absentees from Absenteeism_at_work
where Month_of_absence <> 0
group by Month_of_absence),
cte2 as (select Month_of_absence,count(*) as NO_OF_ABSENTEES
from Absenteeism_at_work
where Absenteeism_time_in_hours <> 0
group by Month_of_absence)
select cte.Month_of_absence,cte2.NO_OF_ABSENTEES,
CAST(ROUND((cte2.NO_OF_ABSENTEES*100.0/cte.Total_Absentees),0) AS INT) as Employee_Percent_are_late from cte
join cte2 on cte.Month_of_absence=cte2.Month_of_absence;

--TOP 5 Reasons for absenteeism

select TOP 5 Reason,count(*) as cnt
FROM Absenteeism_at_work a
join Reasons r on r.Number=a.Reason_for_absence
group by Reason
order by count(*) desc;


---Top 3 Employees monthly with max late hours or they are repeator?:

with cte as ( SELECT ID,Month_of_absence,Absenteeism_time_in_hours,
       ROW_NUMBER() OVER(PARTITION BY Month_of_absence order by Absenteeism_time_in_hours desc) as rnk
FROM Absenteeism_at_work
where Month_of_absence <> 0)
select ID,Month_of_absence ,sum(Absenteeism_time_in_hours) as Late_hours_monthly from cte
where rnk<=3
group by ID,Month_of_absence
order by Month_of_absence,sum(Absenteeism_time_in_hours) desc
;

-- TOP SEASON FOR ABSENT
--UPDATE SEASON 

ALTER TABLE Absenteeism_at_work
ADD Season VARCHAR(20);

Update Absenteeism_at_work
SET Season=
		 CASE WHEN Month_of_absence IN (12,1,2) THEN 'Winter'
	        WHEN Month_of_absence IN (3,4,5) THEN 'Spring'
			WHEN Month_of_absence IN (6,7,8) THEN 'Summer'
			WHEN Month_of_absence IN (9,10,11) THEN 'Fall'
			ELSE 'Unknown' 
			End;

--TOP 3 seasons with max late hrs
SELECT Season,count(*) as cnt
  FROM Absenteeism_at_work
where Absenteeism_time_in_hours != 0
group by Season
order by count(*) desc;

--Seasonal Absenteeism Trends with reason
select Season,Reason,TOTAL_ABSENT_HRS,Total_absentees_hr_seasonwise,percentage_contribution from (
SELECT Season,Reason,sum(Absenteeism_time_in_hours) as TOTAL_ABSENT_HRS,
  DENSE_RANK() OVER (PARTITION BY Season Order by sum(Absenteeism_time_in_hours) desc) as rnk,
  SUM (sum(Absenteeism_time_in_hours)) OVER (PARTITION BY Season) as Total_absentees_hr_seasonwise,
  CONCAT(CAST(ROUND(sum(Absenteeism_time_in_hours) *100.0/ SUM (sum(Absenteeism_time_in_hours)) OVER (PARTITION BY Season),0) AS numeric), '%') as percentage_contribution
  FROM Absenteeism_at_work a
  join Reasons r
  on r.Number=a.Reason_for_absence
group by Season,Reason
having sum(Absenteeism_time_in_hours) !=0) a
where rnk <=3 
;

---Employee Absenteeism Patterns by Day of the Week
-- first add one column for day of week

ALTER TABLE Absenteeism_at_work
ADD new_day_of_week VARCHAR(20);

Update Absenteeism_at_work
SET new_day_of_week= NULL;

Update Absenteeism_at_work
SET new_day_of_week=
	CASE 
	   WHEN Day_of_the_week=2 THEN 'Tuesday'
	   WHEN Day_of_the_week=3 THEN 'Wednesday'
	   WHEN Day_of_the_week=4 THEN 'Thrusday'
	   WHEN Day_of_the_week=5 THEN 'Friday'
	   WHEN Day_of_the_week=6 THEN 'Saturday'
	END ;

SELECT new_day_of_week,Count(*)AS absenteeism_count
FROM Absenteeism_at_work
GROUP BY new_day_of_week
ORDER BY absenteeism_count DESC

--- Any relation between Transportation Expense vs Absenteeism?
-- first categorize transportation into high,low,medium

ALTER TABLE Absenteeism_at_work
ADD Transport_expense_category VARCHAR(20);

Update Absenteeism_at_work
Set Transport_expense_category=
        Transportation_expense_category from (select ID,
		CASE 
		WHEN Transportation_expense < Percentile_cont(0.25) WITHIN GROUP (Order by Transportation_expense ) OVER () THEN 'Low'
		WHEN Transportation_expense >= Percentile_cont(0.25) WITHIN GROUP (Order by Transportation_expense ) OVER () AND
		     Transportation_expense < Percentile_cont(0.75) WITHIN GROUP (Order by Transportation_expense ) OVER () THEN 'Medium'
		WHEN Transportation_expense >= Percentile_cont(0.75) WITHIN GROUP (Order by Transportation_expense ) OVER () THEN 'High'
		END  AS Transportation_expense_category,
		Transportation_expense
from Absenteeism_at_work
)tbl1
where tbl1.ID=Absenteeism_at_work.ID;

select * from Absenteeism_at_work;

with cte as (SELECT  Transportation_expense
from Absenteeism_at_work)
select sum (Transportation_expense) over (partition by part) as quartitle
from cte


---Optimize QUery for Dashboard
SELECT a.ID,r.Reason,
       a.Month_of_absence,a.Body_mass_index,
	   CASE WHEN Body_mass_index < 18.5 THEN 'Underweight'
	        WHEN Body_mass_index between 18.5 and 25 THEN 'Healthy Weight'
			WHEN Body_mass_index between 25 and 30 THEN 'Overweight'
			WHEN Body_mass_index >18.5 THEN 'Obese'
			ELSE 'Unknown' End as BMI_Category,
       CASE WHEN Month_of_absence IN (12,1,2) THEN 'Winter'
	        WHEN Month_of_absence IN (3,4,5) THEN 'Spring'
			WHEN Month_of_absence IN (6,7,8) THEN 'Summer'
			WHEN Month_of_absence IN (9,10,11) THEN 'Fall'
			ELSE 'Unknown' End as Seasons_names,
	   Month_of_absence,
	   Day_of_the_week,
	   Transportation_expense,
	   Distance_from_Residence_to_Work,
	   Work_load_Average_day,
	   Pet,
	   Son,
	   Social_drinker,
	   Social_smoker,
	   Education,
	   Age,
	   Service_time,
	   Absenteeism_time_in_hours,
	   Reason
  FROM Absenteeism_at_work a
  left join compensation c on a.ID=c.ID
  left join Reasons r on r.Number=a.Reason_for_absence;




