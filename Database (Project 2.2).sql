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
