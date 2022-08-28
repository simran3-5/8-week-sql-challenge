--1. What is the total amount each customer spent at the restaurant?
Select S.customer_id, Sum(M.price)
From Menu m
join Sales s
On m.product_id = s.product_id
group by S.customer_id

--2. How many days has each customer visited the restaurant?

select customer_id, count(DISTINCT(order_date)) FROM sales GROUP by customer_id 

--3.What was the first item from the menu purchased by each customer?
select customer_id,product_name from(select customer_id,order_date,s.product_id,me.product_name, RANK() over(PARTITION by customer_id  ORDER by order_date) as rnk from sales s
join menu me on s.product_id=me.product_id)aa where rnk=1 GROUP by customer_id, product_name

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT  count(s.product_id), me.product_name from sales s join menu me on s.product_id=me.product_id
 GROUP by s.product_id,product_name order by COUNT desc  limit 1


--5.Which item was the most popular for each customer?
select customer_id,product_name,cn from(select s.customer_id,me.product_name, COUNT(me.product_name)as cn, 
RANK()OVER(PARTITION by s.customer_id ORDER by COUNT(me.product_name) DESC )as rn from sales s JOIN menu me on s.product_id=me.product_id
GROUP by s.customer_id,me.product_name )aa where rn=1

--6. Which item was purchased first by the customer after they became a member?
with cte as (SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
                                          DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales AS s JOIN members AS m ON s.customer_id = m.customer_id WHERE s.order_date >= m.join_date)
    
SELECT s.customer_id, s.order_date, m2.product_name FROM cte  s
JOIN menu  m2 ON s.product_id = m2.product_id
WHERE rnk = 1;

--7.Which item was purchased just before the customer became a member?
with cte as (SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
                                          DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales AS s JOIN members AS m ON s.customer_id = m.customer_id WHERE s.order_date <= m.join_date)
    
SELECT s.customer_id, s.order_date, m2.product_name FROM cte  s
JOIN menu  m2 ON s.product_id = m2.product_id
WHERE rnk = 1;

--8. What is the total items and amount spent for each member before they became a member
with cte as (SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
                                          DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rnk
    FROM sales AS s JOIN members AS m ON s.customer_id = m.customer_id WHERE s.order_date < m.join_date)
    
SELECT s.customer_id,sum(m2.price) FROM cte  s
JOIN menu  m2 ON s.product_id = m2.product_id GROUP by customer_id order by customer_id

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
--- how many points would each customer have
with cte as (SELECT *, 
 CASE
  WHEN product_id = 1 THEN price * 20
  ELSE price * 10
  END AS points
 FROM menu)      
             
SELECT s.customer_id, SUM(p.points) AS total_points
FROM cte AS p
JOIN sales AS s
 ON p.product_id = s.product_id
GROUP BY s.customer_id ORDER by s.customer_id

--10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
--not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS 
(
   SELECT *, 
      DATEADD(DAY, 6, join_date) AS valid_date, 
      EOMONTH('2021-01-31') AS last_date
   FROM members 
)
Select S.Customer_id, 
       SUM(
	   Case 
	  When m.product_ID = 1 THEN m.price*20
	  When S.order_date between D.join_date and D.valid_date Then m.price*20
	  Else m.price*10
	  END 
	  ) as Points
From Dates D
join Sales S
On D.customer_id = S.customer_id
Join Menu M
On M.product_id = S.product_id
Where S.order_date < d.last_date
Group by S.customer_id
 

