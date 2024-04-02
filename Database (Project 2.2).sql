--Group 8: Luke Wolf, Kyle Petrone, Michael Brennan, Reese Sleater
--Query 1
SELECT COUNT(*) AS QueryCountCapacity
FROM (
    SELECT F.flight_id
    FROM flights F
    JOIN planes P ON F.plane_id = P.plane_id
    JOIN tickets T ON T.flight_id = F.flight_id
    GROUP BY F.flight_id, P.capacity
    HAVING (P.capacity * 0.5) < COUNT(T.ticket_id)
) AS Query_1;

--Query 2
SELECT COUNT(*) AS QueryCountCapacityFrom2017
FROM (
    SELECT F.flight_id
    FROM flights F
    JOIN planes P ON F.plane_id = P.plane_id
    JOIN tickets T ON T.flight_id = F.flight_id
    WHERE F.date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY F.flight_id, P.capacity
    HAVING (P.capacity * 0.25) > COUNT(T.ticket_id)
) AS Query_2;

--Query 3
SELECT R.route_id, MAX(finalprices) AS MaxTotalRevenue, MIN(finalprices) AS MinTotalRevenue
FROM (
    SELECT R.route_id, SUM(T.final_price) AS finalprices
    FROM Tickets T
    JOIN flights F ON T.flight_id = F.flight_id
    JOIN routes R ON F.route_id = R.route_id
    WHERE F.date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY R.route_id
) AS Query_3;

--Query 4


--Query 5 (Unsure what would be registered/non-registered)
SELECT
FROM(
    SELECT C.
) AS Query_5;

--Query 6
SELECT W.weekday AS DayOfWeek, R.route_id, COUNT(T.ticket_id) AS TicketsSold
FROM (
    SELECT *
    FROM Tickets T
    JOIN flights F ON T.flight_id = F.flight_id
    JOIN routes R ON F.route_id = R.route_id
    JOIN weekdays W ON R.weekday_id = W.weekday_id
    WHERE R.city_state_id_origin = (SELECT city_state_id FROM cities_states WHERE name = 'Tampa')
    AND R.city_state_id_destination = (SELECT city_state_id FROM cities_states WHERE name = 'Orlando')
    GROUP BY W.weekday, R.route_id
    ORDER BY W.weekday, TicketsSold DESC
) AS Query_6;

--Query 7


--(10) What are the three employees that have sold the most tickets in 2017?
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


-- (11) What was the most demanded cabin type for tickets sold in 2017?
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



--(12) What is the purchase location in which most tickets were sold in 2016?
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




--(Query 13)
 SELECT f.flight_id,
       p.capacity AS plane_capacity,
       COUNT(t.ticket_id) AS sold_tickets
FROM flights f
INNER JOIN planes p ON f.plane_id = p.plane_id
LEFT JOIN tickets t ON f.flight_id = t.flight_id
GROUP BY f.flight_id, p.capacity
HAVING COUNT(t.ticket_id) = p.capacity;

--14 What was the most used payment type for tickets sold in 2017?
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
--(17)
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

--(18) What are the six zip codes where most employees live in?
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

--(19) What three customers bought the most tickets in 2017?
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
SELECT R.route_ID, MAX(ticketcount) AS MostUsedRouteOnWeekends
FROM (
    SELECT COUNT(T.ticket_id) AS ticketcount
    FROM Tickets T
    JOIN flights F ON T.flight_id = F.flight_id
    JOIN routes R ON F.route_id = R.route_id
    JOIN weekdays W ON R.weekday_id=W.weekday_id
    WHERE W.weekday_ID IN (6,7) AND F.date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY R.route_id
) AS Query_20;
