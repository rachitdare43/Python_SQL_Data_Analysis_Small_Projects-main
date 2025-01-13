SELECT TOP (1000) [invoice_no]
      ,[customer_id]
      ,[gender]
      ,[age]
      ,[category]
      ,[quantity]
      ,[price]
      ,[payment_method]
      ,[invoice_date]
      ,[shopping_mall]
  FROM [Customer_segmentation].[dbo].[customer_shopping_data](nolock)


---Basic Data information and customer demographics.

select * from customer_shopping_data;

--Calculate Customer Life Value (CLV)

--firstly calculate customer revenue

WITH customer_revenue AS (
    SELECT 
        customer_id,
        ROUND(SUM(quantity * price), 2) AS total_revenue
    FROM 
        customer_shopping_data
    GROUP BY 
        customer_id
),
customer_tenure as (
				select 
					customer_id,
					DATEDIFF(month,MIN(invoice_date),GETDATE()) as tenure_months
		        from 
					customer_shopping_data
		        group by 
					customer_id
),
churn_rate as (select 
		CAST(ROUND(100.0 * COUNT(case when tenure_months < 24 THEN 1 END)/count(*),2) AS float) as monthly_churn_rate 
		--- means that the churn rate calculation will now consider customers with a tenure of less than 24 months as potential churners
	from customer_tenure)
select
cr.customer_id,
cr.total_revenue,
ct.tenure_months,
ROUND(cr.total_revenue/(1-POWER(1 + chr.monthly_churn_rate,-ct.tenure_months/12.0)),2) as customer_lifetime_value --- Total revenue divide by probability of remaining a customer
from 
customer_revenue cr 
join customer_tenure ct on cr.customer_id=ct.customer_id
CROSS JOIN churn_rate chr;

-- update spend column

ALTER TABLE customer_shopping_data
ADD sales float;

Update csd
SET sales=cs.sales
from customer_shopping_data csd
JOIN(
		select invoice_no,round(sum(quantity * price),2) as sales
		from customer_shopping_data
		group by invoice_no) cs
ON csd.invoice_no=cs.invoice_no;

--Identify Top Spending Customers by Category

select TOP 10 customer_id,category, sales
from customer_shopping_data
order by sales desc;

--count of mall

select customer_id,count(distinct shopping_mall) as cnt_mall
from customer_shopping_data
group by customer_id;

select TOP 25 * from customer_shopping_data
;

select category, ROUND(sum(sales),0) as sales,
       rank() over (partition by category order by sum(sales) desc) as rnk
	   from customer_shopping_data
	   group by category;

---CASE STATEMENT-- create age_group,gender,payment_method & sales 
with cte as (select gender,
				   CASE 
					   WHEN age BETWEEN 18 and 25 then '18-25'
					   WHEN age BETWEEN 26 and 35 then '26-35'
					   WHEN age BETWEEN 36 and 45 then '36-45'
					   ELSE '45+'
				   END as AGE_GROUP,
				   payment_method,
				   sum(sales) as total_sales
			from customer_shopping_data
group by gender,
		 CASE 
			WHEN age BETWEEN 18 and 25 then '18-25'
			WHEN age BETWEEN 26 and 35 then '26-35'
			WHEN age BETWEEN 36 and 45 then '36-45'
			ELSE '45+'
		    END,payment_method)
select gender,AGE_GROUP,payment_method,round(total_sales,0) as group_sales from cte
order by total_sales desc;

---Now Alter and update Age_group in table

Alter TABLE customer_shopping_data
ADD  Age_Group VARCHAR(20);

Update customer_shopping_data
SET Age_Group=CASE WHEN age < 25 THEN '<25'
				   WHEN age BETWEEN 25 AND 35 THEN '25-35'
				   WHEN age BETWEEN 36 AND 45 THEN '36-45'
				   ELSE '45 +'
				   END ;

---payment method contribution by age_group and gender
select Age_Group,gender,
	   payment_method,
	   round(sum(sales),0) as total_sales,
	   ROUND(100.0 * sum(sales)/sum(sum(sales)) OVER (PARTITION BY gender,Age_Group),2) as perc_contri_pay_method_age_grp
	   from customer_shopping_data
group by Age_Group,gender,payment_method;

---find shopping malls generated sales more than 20000000
select shopping_mall, round(sum(sales),2)
from customer_shopping_data
group by shopping_mall
having sum(sales) > 20000000
order by sum(sales) desc;

select * from customer_shopping_data;

---Find customers who have made purchases in the same shopping mall on different dates.
select c1.customer_id,c1.shopping_mall,c1.invoice_date as invoice_date_1,c2.invoice_date as invoice_date_2
from customer_shopping_data c1
join customer_shopping_data c2
on c1.customer_id=c2.customer_id
and c1.shopping_mall=c1.shopping_mall
and c1.invoice_date <c2.invoice_date
order by c1.customer_id,c1.invoice_date,c2.invoice_date;
--- No customer , it looks all customer only buyied once in this data.

select * from customer_shopping_data;

--Customer segmentation analysis
---FM (Recency, Frequency, Monetary) Segmentation

with rfm as (select 
				  customer_id,
				  DATEDIFF(DAY,max(invoice_date),GETDATE()) as recency,
				  COUNT(DISTINCT invoice_no) as frequency,
				  sum(sales) as monetary
				  from customer_shopping_data
				  group by customer_id)
select customer_id,
	   recency,
	   frequency,
	   monetary,
	   CASE 
	       WHEN recency <= 670 AND monetary > 4000 THEN 'Best_Customers'
		   WHEN recency <= 870 AND monetary > 600 THEN 'Loyal_Customers'
		   WHEN recency <= 1070 AND monetary > 200 THEN 'Potential_Customers'
		   ELSE 'Lost_Customers'
		   END AS RFM_Segments
from rfm
order by monetary desc,recency;

select * from customer_shopping_data

----Sales Analysis----

---Sales Trend Analysis (Monthly and Yearly)
select YEAR(invoice_date) as Yr,
month(invoice_date) as mnth,
round(sum(sales),2) as Total_sales,
COUNT(DISTINCT invoice_no) as transaction_count,
ROUND(sum(sales)/Count(distinct invoice_no),2) as avg_transaction_count
from customer_shopping_data
group by YEAR(invoice_date),month(invoice_date)
order by Yr,mnth;

---Category Performance Analysis

select 
	category,
	round(sum(sales),0) as total_sales,
	COUNT(DISTINCT invoice_no) as transaction_count,
	sum(quantity) as total_quantity,
	ROUND(sum(sales)/sum(quantity),0) as avg_unit_price,
	ROUND(sum(sales)/count(DISTINCT invoice_no),0) as avg_transaction_value
from customer_shopping_data
group by category
order by total_sales desc

---Shopping mall Performance Comparison

select 
	shopping_mall,
	ROUND(sum(sales),0) as total_sales,
	COUNT(DISTINCT customer_id) AS unique_customers,
	COUNT(DISTINCT invoice_no) AS transaction_count,
	sum(quantity) as total_quantity,
	ROUND(sum(sales)/COUNT(DISTINCT invoice_no),0) as avg_transaction_value
from customer_shopping_data
group by shopping_mall
order by total_sales desc;

---Payment method Analysis:
select
	payment_method,
	count(*) as usage_count,
	ROUND(sum(sales),0) as total_sales,
	ROUND(AVG(sales),0) as avg_transaction_values,
	ROUND(sum(sales) / (select sum(sales) from customer_shopping_data) * 100,2) as sales_percentage
from customer_shopping_data
group by payment_method
order by total_sales desc;

--Customer Cohort Analysis(based on first purchase month):

with first_purchase AS (
	select 
		customer_id,
		MIN(DATEPART(MONTH,invoice_date)) as cohort_month
	from customer_shopping_data
	group by customer_id
),
cohort_data AS (
	select
		fp.cohort_month,
		DATEPART(MONTH,csd.invoice_date) as purchase_month,
		COUNT(DISTINCT csd.customer_id) as customer_count,
		ROUND(sum(csd.sales),2) as total_sales
	from customer_shopping_data csd
	join first_purchase fp on csd.customer_id=fp.customer_id
	group by fp.cohort_month,DATEPART(MONTH,csd.invoice_date)
)
select 
    cohort_month,
	purchase_month,
	customer_count,
	total_sales,
	DATEDIFF(month,cohort_month,purchase_month) as months_since_first_purchase
from cohort_data
order by cohort_month,purchase_month


----Price Sensitivity Analysis

WITH price_ranges AS (
		SELECT 
			category,
			CASE 
				WHEN price < AVG(price) OVER (PARTITION BY category) * 0.5 THEN 'Low'
				WHEN price BETWEEN AVG(price) OVER (PARTITION BY category) * 0.5 AND AVG(price) OVER (PARTITION BY category) * 1.5 THEN 'Medium'
				ELSE 'High'
			END as price_range,
			SUM(quantity) as total_quantity,
			SUM(sales) as total_sales
		from customer_shopping_data
		group by category,price
)
select 
    category,
	price_range,
	total_quantity,
	total_sales,
	total_sales/total_quantity as avg_unit_price
from price_ranges
order by category,price_range;

-- Cross Category purchase analysis
with category_combinations as
    (
	select 
		a.category as Category1,
		b.category as Category2,
		COUNT(DISTINCT a.invoice_no) as co_occurence
		from customer_shopping_data a
		JOIN customer_shopping_data b ON a.invoice_no=b.invoice_no AND a.category < b.category
		GROUP BY a.category,b.category)
select Category1,
	   Category2,
	   co_occurence,
	   co_occurence / (select count(distinct invoice_no) from customer_shopping_data) as co_occurance_rate
from category_combinations
order by co_occurence desc;


select * from customer_shopping_data;



















































