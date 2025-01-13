--- This Dataset is about Suicide in India of year 2002-2012 .

--Glimpse of Dataset
SELECT TOP (1000) [State]
      ,[Year]
      ,[Type_code]
      ,[Type]
      ,[Gender]
      ,[Age_group]
      ,[Total]
  FROM [Suicide_Database].[dbo].[Suicide];

--Check Top Statewise suicide count and ratio vs national total.

WITH cte AS (
    SELECT State, SUM(Total) AS Suicide_Count
    FROM Suicide
    GROUP BY State
)
SELECT State,
       Suicide_Count,
       CONCAT (CAST(ROUND(Suicide_Count * 100.0 / SUM(Suicide_Count) OVER(),2) AS decimal (10,2)) ,' %') AS Ratio_vs_national
FROM cte
Order by Suicide_Count desc;

--Top 5 state ,high suicide rate causes.
with top_states as (
     SELECT State,SUM(Total) as Total_Suicide_Count,
            ROW_NUMBER() OVER ( Order by SUM(Total) desc ) as rn
     FROM Suicide
     GROUP BY State)
SELECT ts.State,ts.Total_Suicide_Count,s.Type,SUM(Total) as Reason_for_Suicide
FROM top_states as ts
JOIN Suicide as s ON ts.State=s.State
where ts.rn BETWEEN 3 AND 5
GROUP BY ts.State,ts.Total_Suicide_Count,s.Type
Order by ts.Total_Suicide_Count desc,ts.State,Reason_for_Suicide desc;

--Year-over-Year Percentage Change in Suicides by State and Gender

SELECT State,Gender,Year,
	   SUM(Total) as Total_Suicide,
	   LAG(SUM(Total)) OVER (PARTITION BY State,Gender Order by Year) as Previous_Year_Count,
	   CAST (100.0 * (SUM(Total) - LAG(SUM(Total)) OVER (PARTITION BY State,Gender Order by Year)) /
	   NULLIF (LAG(SUM(Total)) OVER (PARTITION BY State,Gender Order by Year) ,0) AS decimal (10,2)) as Percentage_Change
FROM Suicide
GROUP BY State,Gender,Year
ORDER BY State,Gender,Year;

--Top Causes of Suicide by State for Each Year

with cte as (
	  SELECT State,Year,Type,SUM(Total) as Suicide_count,
			 ROW_NUMBER() OVER (PARTITION BY State,Year ORDER BY Sum(Total) DESC) as rnk
	  FROM Suicide
	  GROUP BY  State,Year,Type
)
SELECT State,
		MAX(CASE WHEN Year = 2001 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2001,
		MAX(CASE WHEN Year = 2002 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2002,
		MAX(CASE WHEN Year = 2003 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2003,
		MAX(CASE WHEN Year = 2004 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2004,
		MAX(CASE WHEN Year = 2005 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2005,
		MAX(CASE WHEN Year = 2006 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2006,
		MAX(CASE WHEN Year = 2007 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2007,
		MAX(CASE WHEN Year = 2008 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2008,
		MAX(CASE WHEN Year = 2009 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2009,
		MAX(CASE WHEN Year = 2010 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2010,
		MAX(CASE WHEN Year = 2011 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2011,
		MAX(CASE WHEN Year = 2012 then Concat(Type ,':' ,'( ',Suicide_count,' )') END) AS Year_2012
from cte
WHERE rnk=1
GROUP BY State;


-- Analyzing Suicides by Age Group: Contribution to Overall Suicides

SELECT Age_group,sum(Total) as Suicide_count,
	   SUM(Total) *100.0 / SUM(SUM(Total)) OVER () AS Contribution_percentage
FROM Suicide
GROUP BY Age_group
Order by Suicide_count desc;

--Detecting Anomalies: Years with Unusual Spikes in Suicides
SELECT Year,SUM(Total) AS Suicide_Count,
		AVG(SUM(Total)) OVER (ORDER BY Year ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS Avg_Sucidies,
		(SUM(Total) - AVG(SUM(Total)) OVER (ORDER BY Year ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)) AS Deviation
FROM Suicide
GROUP BY Year
ORDER BY Deviation desc;

--Identifying States with Consistently High Suicide Rates

with High_State as (SELECT State,Year,SUM(Total) as Suicide_Counts,
					   RANK() OVER (PARTITION BY Year ORDER bY SUM(Total) DESC) as rnk
			 FROM  Suicide
			 WHERE State NOT IN ('Total (All India)','Total (States)')
			 GROUP BY State,Year
			        ),
cte2 as (	SELECT State, Year AS Years_High_Suicide_Rate,Suicide_Counts
	        FROM High_State
	        WHERE rnk <=5
	        GROUP BY State,Year,Suicide_Counts)
select State,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2001 then Suicide_Counts END ),0) as Year_2001,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2002 then Suicide_Counts END ),0) AS Year_2002,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2003 then Suicide_Counts END ),0) AS Year_2003,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2004 then Suicide_Counts END ),0) AS Year_2004,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2005 then Suicide_Counts END ),0) AS Year_2005,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2006 then Suicide_Counts END ),0) AS Year_2006,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2007 then Suicide_Counts END ),0) AS Year_2007,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2008 then Suicide_Counts END ),0) AS Year_2008,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2009 then Suicide_Counts END ),0) AS Year_2009,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2010 then Suicide_Counts END ),0) AS Year_2010,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2011 then Suicide_Counts END ),0) AS Year_2011,
	  COALESCE(MAX( CASE WHEN Years_High_Suicide_Rate= 2012 then Suicide_Counts END ),0) AS Year_2012
FROM cte2
GROUP BY State;
--------------------------------------------------------

with High_State as (SELECT State,Year,SUM(Total) as Suicide_Counts,
					   RANK() OVER (PARTITION BY Year ORDER bY SUM(Total) DESC) as rnk
			 FROM  Suicide
			 WHERE State NOT IN ('Total (All India)','Total (States)')
			 GROUP BY State,Year
			        )
SELECT State, Year AS Years_High_Suicide_Rate,Suicide_Counts
FROM High_State
WHERE rnk <=5
GROUP BY State,Year,Suicide_Counts;

----Distribution of Suicides by Cause Across Different Gender-Age Groups

SELECT Gender,Age_group,Type,SUM(Total) as Suicide_Counts,
       NTILE(4) OVER (PARTITION BY Gender,Age_group ORDER BY SUM(Total) DESC) AS QUARTILE
FROM Suicide
GROUP BY Gender,Age_group,Type

--- TOP Cause of suicide in every age group & Gender.

with cte as (
SELECT Gender,Age_group,Type,SUM(Total) as Suicide_Counts,
       RANK() OVER (PARTITION BY Gender,Age_group ORDER BY SUM(Total) DESC) AS Rnk
FROM Suicide
GROUP BY Gender,Age_group,Type)
SELECT Gender,Age_group,Type,Suicide_Counts
FROM cte
where Rnk =1 ;

---Identifying Gender-Specific Causes with Significant Yearly Increase
SELECT Gender,Year,Type,SUM(Total) as Total_Suicides,
       LAG(SUM(Total)) OVER (PARTITION BY Gender,Type ORDER BY Year) as Previous_Year,
	   CASE WHEN LAG(SUM(Total)) OVER (PARTITION BY Gender,Type ORDER BY Year) IS NOT NULL
	   THEN 100 * (SUM(Total)- LAG(SUM(Total)) OVER (PARTITION BY Gender,Type ORDER BY Year)) /
	        NULLIF (LAG(SUM(Total)) OVER (PARTITION BY Gender,Type ORDER BY Year),0)
			ELSE NULL END AS Percent_Change
FROM Suicide
GROUP BY Gender,Year,Type




