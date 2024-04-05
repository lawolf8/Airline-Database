--Group 8: Luke Wolf, Kyle Petrone, Michael Brennan, Reece Sleater
--Query 1
SELECT COUNT(*) AS QueryCountCapacity
FROM (
    SELECT F.flight_id
    FROM flights F
    JOIN planes P ON F.plane_id = P.plane_id
    JOIN tickets T ON T.flight_id = F.flight_id
    GROUP BY F.flight_id, P.capacity
    HAVING (P.capacity * 0.5) < COUNT(T.ticket_id)
) AS SubQuery_1;

--Query 2
SELECT COUNT(*) AS QueryCountCapacityFrom2017
FROM (
    SELECT F.flight_id
    FROM flights F
    JOIN planes P ON F.plane_id = P.plane_id
    JOIN tickets T ON T.flight_id = F.flight_id
    WHERE YEAR(F.date) = 2017
    GROUP BY F.flight_id, P.capacity
    HAVING (P.capacity * 0.25) > COUNT(T.ticket_id)
) AS SubQuery_2;

--Query 3
WITH RouteRevenues AS (
    SELECT 
        R.route_id, 
        SUM(T.final_price) AS TotalRevenue
    FROM 
        Tickets T
        JOIN flights F ON T.flight_id = F.flight_id
        JOIN routes R ON F.route_id = R.route_id
    WHERE 
        year(F.date) = 2017
    GROUP BY 
        R.route_id
)
SELECT
    'Max Revenue Route' AS Revenue_Value_Description,
    route_id,
    TotalRevenue
FROM RouteRevenues
WHERE TotalRevenue = (SELECT MAX(TotalRevenue) FROM RouteRevenues)
UNION ALL
SELECT
    'Min Revenue Route' AS Revenue_Value_Description,
    route_id,
    TotalRevenue
FROM RouteRevenues
WHERE TotalRevenue = (SELECT MIN(TotalRevenue) FROM RouteRevenues);

--Query 4
--4.1
select count(*) 'Elderly Discount', sum(total_discount) AS total_discount
from
(select (final_price*( select percentage from discounts
where name='Elderly Discount')) AS total_discount
from tickets ti
where ti.customer_id in
(select customer_id from customers where
datediff(year,birth_date,purchase_date)>=65);

--4.2
SELECT COUNT(*) AS [Student Discount], 
       SUM(total_discount) AS total_discount
FROM (
    SELECT (ti.final_price * (
        SELECT percentage / 100.0 FROM discounts WHERE name='Student Discount'
    )) AS total_discount
    FROM tickets ti
    WHERE ti.customer_id IN (
        SELECT customer_id FROM customers 
        WHERE DATEDIFF(year, birth_date, getdate()) BETWEEN 16 AND 23
    )
) AS StudentDiscountSubquery;
	
--Query 5 (Unsure what would be registered/non-registered)
SELECT YEAR(T.purchase_date) As Year, MONTH(T.purchase_date) AS Month, SUM(CASE WHEN C.customer_id IS NOT NULL THEN 1 ELSE 0 END) * 1.0 / SUM(CASE WHEN C.customer_id IS NULL THEN 1 ELSE 0 END) AS RegisteredRatio
FROM Tickets T
LEFT JOIN Customers C ON T.customer_id=C.customer_id
WHERE YEAR (T.purchase_date) IN (2016, 2017)
GROUP BY YEAR(T.purchase_date), MONTH(T.purchase_date)
ORDER BY YEAR(T.purchase_date), MONTH(T.purchase_date);

--Query 6
SELECT 
    W.weekday AS DayOfWeek, 
    R.route_id, 
    COUNT(T.ticket_id) AS TicketsSold
FROM 
    Tickets T
JOIN 
    flights F ON T.flight_id = F.flight_id
JOIN 
    routes R ON F.route_id = R.route_id
JOIN 
    weekdays W ON R.weekday_id = W.weekday_id
WHERE 
    R.city_state_id_origin = (SELECT city_state_id FROM cities_states WHERE name = 'Tampa')
    AND 
    R.city_state_id_destination = (SELECT city_state_id FROM cities_states WHERE name = 'Orlando')
GROUP BY 
    W.weekday, R.route_id
ORDER BY 
    W.weekday, TicketsSold DESC;


--Query 7
WITH DOWHourlyTicketSales AS (
    SELECT
        DATEPART(dw, F.date) AS Weekday,
        DATEPART(hour, F.start_time_actual) AS DepartureHour,
        COUNT(T.ticket_id) AS TicketsSold,
        ROW_NUMBER() OVER (PARTITION BY DATEPART(dw, F.date) ORDER BY COUNT(T.ticket_id) DESC) AS Rank
    FROM
        Tickets T
        JOIN Flights F ON T.flight_id = F.flight_id
        JOIN Routes R ON F.route_id = R.route_id
        JOIN cities_states CS1 ON R.city_state_id_origin = CS1.city_state_id
        JOIN cities_states CS2 ON R.city_state_id_destination = CS2.city_state_id
    WHERE
        CS1.name = 'Orlando' AND CS2.name = 'Tampa'
        AND YEAR(F.date) = 2017
    GROUP BY
        DATEPART(dw, F.date),
        DATEPART(hour, F.start_time_actual)
)

SELECT 
    Weekday,
    DepartureHour,
    TicketsSold
FROM 
    HourlyTicketSales
WHERE 
    Rank = 1
ORDER BY 
    Weekday;

	
--Query 9
WITH monthly_sales AS (
  SELECT 
    MONTH(purchase_date) AS month,
    COUNT(*) AS tickets_sold
  FROM 
    tickets
  WHERE 
    YEAR(purchase_date) = 2017
  GROUP BY 
    MONTH(purchase_date)
)
SELECT *
FROM monthly_sales
WHERE tickets_sold IN (
  SELECT MIN(tickets_sold) FROM monthly_sales
  UNION ALL
  SELECT MAX(tickets_sold) FROM monthly_sales
);

--Query 10
SELECT TOP 3
    e.employee_id,
    e.first_name,
    e.last_name,
    COUNT(t.ticket_id) AS num_tickets_sold
FROM 
    employees e
INNER JOIN 
    tickets t ON e.employee_id = t.employee_id
WHERE 
    YEAR(t.purchase_date) = 2017
GROUP BY 
    e.employee_id, e.first_name, e.last_name
ORDER BY 
    COUNT(t.ticket_id) DESC;

--Query 11
SELECT TOP 1
    ct.name AS cabin_type,
    COUNT(t.ticket_id) AS num_tickets_sold
FROM 
    tickets t
INNER JOIN 
    cabin_types ct ON t.cabin_type_id = ct.cabin_type_id
WHERE 
    YEAR(t.purchase_date) = 2017
GROUP BY 
    ct.name
ORDER BY 
    COUNT(t.ticket_id) DESC;

--Query 12
SELECT TOP 1
    loc.name AS purchase_location,
    COUNT(t.ticket_id) AS num_tickets_sold
FROM 
    tickets t
INNER JOIN 
    locations loc ON t.purchase_location_id = loc.location_id
WHERE 
    YEAR(t.purchase_date) = 2016
GROUP BY 
    loc.name
ORDER BY 
    COUNT(t.ticket_id) DESC;

--Query 13
 SELECT f.flight_id,
       p.capacity AS plane_capacity,
       COUNT(t.ticket_id) AS sold_tickets
FROM flights f
INNER JOIN planes p ON f.plane_id = p.plane_id
LEFT JOIN tickets t ON f.flight_id = t.flight_id
GROUP BY f.flight_id, p.capacity
HAVING COUNT(t.ticket_id) = p.capacity;

--Query 14
SELECT TOP 1
    pt.name AS payment_type,
    COUNT(t.ticket_id) AS num_tickets_sold
FROM 
    tickets t
INNER JOIN 
    payment_types pt ON t.payment_type_id = pt.payment_type_id
WHERE 
    YEAR(t.purchase_date) = 2017
GROUP BY 
    pt.name
ORDER BY 
    COUNT(t.ticket_id) DESC;

--Query 15
SELECT TOP 1
	purchase_date AS date_with_most_revenue,
       SUM(final_price) AS total_revenue
FROM 
	tickets
WHERE 
	YEAR(purchase_date) = 2017
GROUP BY 
	purchase_date
ORDER BY 
	total_revenue DESC;

--Query 16
SELECT TOP 1
	DATEPART(HOUR,purchase_time) AS hour_of_day,
    COUNT(*) AS num_tickets_sold
FROM 
	tickets
WHERE 
	YEAR(purchase_date) = 2017
GROUP BY 
	DATEPART(HOUR,purchase_time)
ORDER BY 
	num_tickets_sold DESC;

--Query 17
SELECT TOP 3
    cs.name AS city,
    COUNT(c.customer_id) AS num_customers
FROM 
    customers c
INNER JOIN 
    cities_states cs ON c.city_state_id = cs.city_state_id
GROUP BY 
    cs.city_state_id, cs.name
ORDER BY 
    COUNT(c.customer_id) DESC;

--Query 18
SELECT TOP 6
    e.zipcode_id,
    z.name AS zipcode,
    COUNT(e.employee_id) AS num_employees
FROM 
    employees e
INNER JOIN 
    zipcodes z ON e.zipcode_id = z.zipcode_id
GROUP BY 
    e.zipcode_id, z.name
ORDER BY 
    COUNT(e.employee_id) DESC;

--Query 19
SELECT TOP 3
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(t.ticket_id) AS total_tickets_bought
FROM 
    customers c
INNER JOIN 
    tickets t ON c.customer_id = t.customer_id
INNER JOIN 
    flights f ON t.flight_id = f.flight_id
WHERE 
    YEAR(t.purchase_date) = 2017
GROUP BY 
    c.customer_id, c.first_name, c.last_name
ORDER BY 
    COUNT(t.ticket_id) DESC;

--Query 20
SELECT TOP 1
    Sub.Route_ID, 
    MAX(Sub.TicketCount) AS MostUsedRouteOnWeekends
FROM (
    SELECT 
        R.route_id,
        COUNT(T.ticket_id) AS TicketCount
    FROM 
        Tickets T
        JOIN flights F ON T.flight_id = F.flight_id
        JOIN routes R ON F.route_id = R.route_id
    WHERE 
        DATEPART(weekday, F.date) IN (7, 1)
        AND F.date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY 
        R.route_id
) AS Sub
GROUP BY 
    Sub.Route_ID
ORDER BY 
    MostUsedRouteOnWeekends DESC;
