--==================================================================================================================================--
--PROJECT:End-To-End Online Retail Data Analysis
--TOOL:MYSQL 8.0
--DATASET:UCIMachine Learning Online Retail Dataset(520,000+ Records)
--AUTHOR:Shourya Pratap Singh
--==================================================================================================================================--

--==================================================================================================================================--
--1. DATABASE & SCHEMA SETUP
-- -----------------------------------------------------------------------------------------------------------------------------------
create database online_retail_db;
use online_retail_db;

create table sales_data(
invoice_no varchar(20),
stock_code varchar(20),
description varchar(255),
quantity int,
invoice_data date,
invoice_time time,
unit_price decimal(10,2),
customer_id text,
country varchar(100)
);

--Load cleaned data using bulk import--

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Clean Online Retail.csv"
into table sales_data
character set latin1
fields terminated by ','
optionally enclosed by '"'
lines terminated by '\r\n'
ignore 1 lines;

-- ----------------------------------------------------------------------------------------------------------------------------------
--2. BUSINESS INSIGHTS & EXPLORATORY DATA ANALYSIS
-- ----------------------------------------------------------------------------------------------------------------------------------
--Q1.What are thr primary business KPIs?
select 
	ROUND(SUM(quantity*unit_price),2) AS total_revenue,
    count(distinct invoice_no) as total_orders,
    round(sum(quantity*unit_price)/count(distinct invoice_no),2) as avg_order_value
from sales_data;

--================================================================================================================================--
1.REVENUE AND ORDER COUNT PER COUNTRY
--================================================================================================================================--
--Q2.show the total revenue,total number of order and avg order value for each country.
     Filter out countries with fewer then 10 total orders to focus on active markets.
     
select country, ROUND(SUM(quantity*unit_price),2) AS total_revenue,
    count(distinct invoice_no) as total_orders,
    round(sum(quantity*unit_price)/count(distinct invoice_no),2) as avg_order_value
from sales_data
group by country
having total_orders>10
order by total_revenue desc;

--================================================================================================================================--
2.IDENTIFYING HIGH-VALUE ORDERS
--================================================================================================================================--
--Q3. Find all individual order where the total value exceeded 1000.

select invoice_no, customer_id,country, ROUND(SUM(quantity*unit_price),2) AS total_revenue
from sales_data
group by invoice_no,customer_id,country
having total_revenue>1000
order by total_revenue desc;

--================================================================================================================================--
3.MONTHLY SALES PERFORMANCE
--=================================================================================================================================--
--Q4.Calculate the total revenue and number of unique customer for each month to track sales trends over time.

select 
	ROUND(SUM(quantity*unit_price),2) AS total_revenue,
	count(distinct customer_id) as customer_id,
	date_format(invoice_data,'%m') as sales_months
    from sales_data
    group by sales_months;
    
--===============================================================================================================================--
4.TOP 10 CUSTOMER BY REVENUE
--===============================================================================================================================--
--Q5.find top 10 customers who have made more than 2 purchases,ordered by their total spending.

select count(distinct(invoice_no)) as total_purchases ,customer_id,ROUND(SUM(quantity*unit_price),2) AS total_spent
from sales_data
where customer_id is not null
	and customer_id !=''
    and customer_id!='null'
group by customer_id
having total_purchases>2
order by total_spent desc
limit 10;


--===========================================================================================================================--
5.MOST POPULAR PRODUCT CATEGORIES/KEYWORDS
--==========================================================================================================================--
--Q6.Find all the sales for the products that contian the word "BAG" or "HEART" in their description 
	to see how popular these products lines are.
    
    select
		case
			when description like '%BAG%' THEN 'BAGS'
            when description like '%HEART' THEN 'HEART'
			else 'OTHER'
        END as Product_category,
    round(sum(quantity*unit_price),2) as total_revenue,
    sum(quantity) as total_unit_sold,description
    from sales_data
    where description like '%BAG%' OR description like '%heart%'
group by product_category,description; 


--===============================================================================================================================--
6.BUSY VS QUIET DAYS OF THE WEEK
--================================================================================================================================--  
--Q7.which day of the week generate the highest amount of revenue and order volume?

select 
	dayname(invoice_data) as dayname,
	round(sum(quantity*unit_price),2) as total_revenue,
    count(distinct(invoice_no)) as total_orders
from sales_data
group by dayname
order by total_revenue;

--=============================================================================================================================--
7.PRODUCT WITH HIGH SALES VOLUME BUT LOW UNIT PRICE
--============================================================================================================================--
--Q8.find the products with a unit price under 20 that have generated more then 5000 unit in total sales.

select 
	stock_code,unit_price,description,sum(quantity) as total_quantity_sold
from sales_data
where unit_price<20
group by stock_code,description,unit_price
having total_quantity_sold>5000
order by total_quantity_sold desc;


--===========================================================================================================================--
8.INDENTIFYIND LARGE ORDERS
--===========================================================================================================================--
--Q9.Which orders contained more than 500 total iteam in a single tranction.

select 
	sum(quantity) as total_iteam,stock_code,invoice_no
from sales_data
group by stock_code,invoice_no
having total_iteam>500
order by total_iteam;

--=============================================================================================================================--
9.PRODUCT SOLD ACROSS MULTIPLE COUNTRIES
--=============================================================================================================================--
--Q10.find the products that have been sold in more then 15 different countries to identify globally popular iteam.

select 
	stock_code,description,count(distinct(country)) as countries
from sales_data
group by stock_code,description
having countries>15
order by countries desc;

--============================================================================================================================--
10.SALES PERFORMANCE BY TIME OF DAY
--=============================================================================================================================--
--Q11.How do sales compare between morning(before 12 pm),afternoon(12pm-4pm) and evening(after 4pm).

select 
	case 
    when hour(invoice_time)<12 then 'Morning'
    when hour(invoice_time) between 12 and 16 then 'afternoon'
    else 'evening'
    end as time_of_day,
    round(sum(quantity*unit_price),2) as total_revenue,
    count(distinct(invoice_no)) as total_orders
from sales_data
group by time_of_day
order by total_revenue desc;


--================================================================================================================================--
TOP SPENDING COUNTRY OTHER THEN THE UK
--=================================================================================================================================--
--Q12.the uk is usually dominates sales in this data,which non-uk countries generate the highest revenue?

select country,
	round(sum(quantity*unit_price),2) as total_revenue,
    count(distinct(invoice_no)) as total_orders
from sales_data
where country != 'United Kingdom'
group by country
order by total_revenue desc
limit 6;
