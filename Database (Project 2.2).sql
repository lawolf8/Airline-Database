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
SELECT MAX(finalprices) AS MaxTotalRevenue, MIN(finalprices) AS MinTotalRevenue
FROM (
    SELECT R.route_id, SUM(T.final_price) AS finalprices
    FROM Tickets T
    JOIN flights F ON T.flight_id = F.flight_id
    JOIN routes R ON F.route_id = R.route_id
    WHERE F.date BETWEEN '2017-01-01' AND '2017-12-31'
    GROUP BY R.route_id
) AS Query_3;