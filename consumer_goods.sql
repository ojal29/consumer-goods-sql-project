/*request 1 */
select distinct market from dim_customer where customer="Atliq Exclusive" and region="APAC";


/* request 2 */
with unique_product_cte as (
select (select count(distinct product_code) 
from fact_sales_monthly where fiscal_year="2020") unique_product_2020, 
(select count(distinct product_code) from fact_sales_monthly where fiscal_year="2021") unique_product_2021 )
select unique_product_2020,unique_product_2021, ROUND((unique_product_2021-unique_product_2020)*100/unique_product_2020,1) 
as percentage_chg from unique_product_cte;


/* request 3 */
select segment, count(distinct product_code) as product_count from dim_product group by segment order by product_count desc;

/* request 4 */
with product_count_2020_cte as 
(select product.segment, count(distinct sales.product_code) product_count_2020 
from fact_sales_monthly sales join dim_product product on sales.product_code = product.product_code 
where sales.fiscal_year="2020" group by product.segment),
product_count_2021_cte as 
(select product.segment, count(distinct sales.product_code) product_count_2021
from fact_sales_monthly sales join dim_product product on sales.product_code = product.product_code 
where sales.fiscal_year="2021" group by product.segment)
select c_20.segment,c_20.product_count_2020,c_21.product_count_2021,(c_21.product_count_2021-c_20.product_count_2020) difference 
from product_count_2020_cte c_20 join product_count_2021_cte c_21 on c_20.segment=c_21.segment order by difference desc;


/* request 5*/
select p.product, p.product_code, round(m.manufacturing_cost,2) as manufacturing_cost 
from dim_product p join fact_manufacturing_cost m on p.product_code=m.product_code where 
m.manufacturing_cost=(select max(manufacturing_cost) from fact_manufacturing_cost m) or 
m.manufacturing_cost=(select min(manufacturing_cost) from fact_manufacturing_cost m) order by m.manufacturing_cost desc;


/* request 6*/
select i.customer_code, c.customer, ROUND(AVG(i.pre_invoice_discount_pct)*100,2) AS average_discount_percentage 
from dim_customer c,fact_pre_invoice_deductions i where c.customer_code=i.customer_code and c.market='India' and 
i.fiscal_year=2021 group by c.customer, i.customer_code order by average_discount_percentage desc limit 5;


/* request 7 */
select monthname(sales.date) month, YEAR(sales.date) as year, 
round(sum(gross.gross_price*sales.sold_quantity)/100000,2) as gross_sales_amount from fact_sales_monthly sales join 
fact_gross_price gross on sales.product_code=gross.product_code and sales.fiscal_year=gross.fiscal_year join 
 dim_customer c on sales.customer_code=c.customer_code where c.customer='Atliq Exclusive' group by monthname(sales.date),
 year(sales.date);
 
 
 /* request 8*/
 select case when date between '2019-09-01' and '2019-11-01' then 'Quarter 1'
			  when date between '2019-12-01' and '2020-02-01' then 'Quarter 2'
			  when date between '2020-03-01' and '2020-05-01' then 'Quarter 3'
			  when date between '2020-06-01' and '2020-08-01' then 'Quarter 4'
			  end as quarter, 
              sum(sold_quantity) as total_quantity_sold from fact_sales_monthly where fiscal_year=2020 
              group by quarter order by quarter;
              
              
/* request 9 */
with cte1 as 
(select customer.channel, round(sum(gross.gross_price*sales.sold_quantity)/1000000,2) as gross_sales_mln 
from dim_customer customer join fact_sales_monthly sales on customer.customer_code=sales.customer_code join fact_gross_price gross
on sales.product_code=gross.product_code where sales.fiscal_year=2021 group by customer.channel order by gross_sales_mln desc),
cte2 as (select sum(gross_sales_mln) as total_gross_sales from cte1)
select cte1.*, round((gross_sales_mln/total_gross_sales*100), 2) as percentage from cte1 join cte2;


/*request 10 */
with total_sold_2021 as ( 
select product.division, product.product_code,product.product, sum(sales.sold_quantity) as 
total_sold_quantity from dim_product product join fact_sales_monthly sales on product.product_code=sales.product_code 
where sales.fiscal_year=2021 group by product.division, product.product_code, product.product order by total_sold_quantity desc),
rank_cte as (select *, dense_rank() over(partition by division order by total_sold_quantity desc) as rank_order from total_sold_2021)
select * from rank_cte where rank_order<=3;
