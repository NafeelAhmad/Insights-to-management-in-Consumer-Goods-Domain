-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
--  business in the APAC region.

select distinct market from dim_customer where region = "APAC" 
and customer="Atliq Exclusive" order by market;

/* 2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

with unq_20 as (
select count(distinct(product_code)) unique_products_2020 from fact_sales_monthly
where fiscal_year=2020),
unq_21 as (
select count(distinct(product_code)) unique_products_2021 from fact_sales_monthly
where fiscal_year=2021) 

select unique_products_2020, unique_products_2021,
round(((unique_products_2021-unique_products_2020)/unique_products_2020)*100,2) percentage_chg
from unq_20 cross join unq_21 ;

/* 
3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count 
*/

select max(segment) Segment, count(distinct(product_code)) Product_count
from dim_product group by segment 
order by product_count desc;

/* 
4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference
*/

with cnt_20 as (
select segment, count(distinct(product_code)) product_count_2020 from 
fact_sales_monthly f join dim_product p using(product_code)
where fiscal_year=2020 group by segment) ,
cnt_21 as (
select segment, count(distinct(product_code)) product_count_2021 from 
fact_sales_monthly f join dim_product p using(product_code)
where fiscal_year=2021 group by segment) 

select cnt_20.segment, product_count_2020, product_count_2021, product_count_2021-product_count_2020
Difference 
from cnt_20 join cnt_21 using(segment) order by Difference desc ;

/*
5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost
*/

with high_mf as (
select distinct(product_code), product, manufacturing_cost 
from fact_manufacturing_cost join 
dim_product using(product_code) order by manufacturing_cost desc
limit 1) ,
low_mf as (
select distinct(product_code), product, manufacturing_cost 
from fact_manufacturing_cost join 
dim_product using(product_code) order by manufacturing_cost asc
limit 1)

select * from high_mf cross join low_mf ;

/*
6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage
*/

select customer_code, max(customer) customer, round(avg(pre_invoice_discount_pct),2)
average_discount_percentage from dim_customer 
join fact_pre_invoice_deductions 
using(customer_code) where fiscal_year=2021 and market="India" group by customer_code
order by average_discount_percentage desc limit 5;

/*
7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount
*/

select fiscal_month, f.fiscal_year,
round(sum(gross_price*sold_quantity)/1000000,2) 
Gross_sales_amount_mln from fact_sales_monthly f join fact_gross_price using(product_code) 
join dim_customer using(customer_code) where customer = "Atliq Exclusive" 
group by fiscal_month, fiscal_year order by fiscal_year asc;

/*
8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity
*/

select Quarter, sum(sold_quantity) total_sold_quantity 
from fact_sales_monthly where fiscal_year="2020" 
group by Quarter order by total_sold_quantity desc;

/*
9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage
*/

create temporary table w7
 ( select channel, 
 round(sum(p.gross_price*m.sold_quantity)/1000000,2) 
 gross_sales_mln from dim_customer c join fact_sales_monthly m 
 on c.customer_code=m.customer_code
join fact_gross_price p
 on m.product_code=p.product_code where m.fiscal_year="2021" group by channel
 );
 
select *, round(gross_sales_mln*100/sum(gross_sales_mln) over(),2) percentage from w7
order by gross_sales_mln desc;

/*
10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division, product_code, product, total_sold_quantity, rank_order
*/

WITH sales AS (
SELECT division,
	   M.product_code,product,
	   sum(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly AS M
LEFT JOIN  dim_product AS P
ON M.product_code = P.product_code
WHERE fiscal_year = 2021
GROUP BY M.product_code, division,product),
rank_ov AS(
SELECT product_code,
       total_sold_quantity,
	   DENSE_RANK () OVER(PARTITION BY division ORDER BY total_sold_quantity desc) AS Rank_order
FROM sales AS S)
SELECT division,
       S.product_code, 
       product ,
       S.total_sold_quantity, 
       Rank_order
FROM sales AS S
INNER JOIN rank_ov AS R
ON R.product_code = S.product_code
WHERE Rank_order BETWEEN 1 AND 3;

