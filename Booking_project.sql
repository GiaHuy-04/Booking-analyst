--RFM
WITH rvroom AS(
	SELECT CAST(b.customer_id  AS int)as customer_id
		, SUM(r.price_per_night * DATEDIFF(DAY,b.check_in,b.check_out)) as room_revenue
		, b.status as status
	FROM booking as b 
	JOIN rooms as r ON b.room_id = r.room_id
	GROUP BY b.customer_id
			, b.status)
, rvservice AS(
	SELECT c.customer_id
	, SUM(total_price) AS revenue_service
	, b.status as status
	FROM booking as b
	JOIN customer as c ON b.customer_id = c.customer_id
	LEFT JOIN service_usage as su ON b.booking_id = su.booking_id
	GROUP BY c.customer_id, b.status
	)
, revenue_customer AS(
	SELECT rr.customer_id 
		, CASE 
			WHEN rr.status='Confirmed' THEN rr.room_revenue
			ELSE 0 
			END AS room_revenue
		, CASE 
			WHEN rr.status='Confirmed' THEN  rs.revenue_service
			ELSE 0
			END AS service_revenue
	FROM rvroom AS rr
	JOIN rvservice AS rs ON rr.customer_id = rs.customer_id
	AND rr.status=rs.status 
	)
, final_revenue AS(  
	SELECT customer_id 
		 , SUM(room_revenue) as total_room_revenue
		, SUM(service_revenue) as total_serviec_revenue
		, SUM(room_revenue) + SUM(service_revenue) AS total_revenue
	FROM revenue_customer
	GROUP BY customer_id
)
, near_date_customer AS(
	SELECT c.customer_id
		, MAX(b.created_at) AS date_neared 
	FROM customer AS c
	JOIN booking as b ON c.customer_id = b.customer_id
	WHERE status='Confirmed' 
	GROUP BY c.customer_id )
,final_near_date_with_actual_date AS (
    SELECT c.customer_id,
           CAST(
               (CASE 
                   WHEN c.customer_id IN (select customer_id FROM near_date_customer) 
                       THEN nd.date_neared
                   ELSE '2010-01-01'
               END)
           AS date) AS actual_date_neared -- Đổi tên alias để rõ ràng
    FROM customer as c 
    LEFT JOIN near_date_customer as nd ON c.customer_id = nd.customer_id
)
,final_near_date AS(
    SELECT customer_id,
           actual_date_neared AS date_neared, -- Lấy giá trị đã tính từ CTE trên
           DATEDIFF(day, actual_date_neared, '2025-02-13') AS date_diff
    FROM final_near_date_with_actual_date
)
,final_total_booking AS (
	SELECT c.customer_id 
		, COUNT(distinct b.booking_id) AS booking_count
		, COUNT(DISTINCT (CASE WHEN b.status = 'Confirmed' THEN booking_id END)) AS confirmed_booking
		, CAST((1.0*COUNT(DISTINCT (CASE WHEN b.status = 'Confirmed' THEN booking_id END)))
		/COUNT(distinct b.booking_id) AS numeric(5,2)) AS confirm_rate
	FROM customer as c
	JOIN booking as b ON c.customer_id = b.customer_id
	GROUP BY c.customer_id)
, rfm_base_data	 AS(
SELECT CAST(fr.customer_id as int) as customer_id
	, fr.total_room_revenue AS total_room_revenue
	, fr.total_serviec_revenue AS total_service_revenue
	, fr.total_revenue as total_revenue
	, fn.date_neared as date_neared
	, fn.date_diff as date_diff
	, ft.booking_count as total_booking
	, ft.confirmed_booking as confirmed_booking 
	, ft.confirm_rate as confirm_rate
FROM final_revenue as fr 
JOIN final_near_date as fn ON fr.customer_id = fn.customer_id
JOIN final_total_booking as ft ON fr.customer_id = ft.customer_id

	)
,raw_rfm AS(
	SELECT *
		, CASE 
			WHEN date_diff < 58 THEN '1'
			WHEN date_diff < 146 THEN '2'
			WHEN date_diff < 267 THEN '3' 
			ELSE '4'
		END AS R
		, CASE 
			WHEN confirmed_booking >4 THEN '1'
			WHEN confirmed_booking >3 THEN '2'
			WHEN confirmed_booking > 2 THEN '3'
			ELSE '4'
		END AS F 
		, CASE 
			WHEN total_revenue > 10416 THEN '1'
			WHEN total_revenue > 7054 THEN '2'
			WHEN total_revenue > 4218 THEN '3'
			ELSE '4'
		END AS M
	FROM rfm_base_data	
	)
, score AS(
	SELECT * 
		, CONCAT(r,f,m) AS rfm_score
	FROM raw_rfm)
SELECT *
	, CASE 
		WHEN date_diff = 5522 THEN 'Inactive customer'
		-- Khách hàng chỉ mới đăng ký chứ chưa sử dụng dịch vụ--
		WHEN rfm_score = '111' THEN 'VIP customer'
		WHEN rfm_score LIKE '14%' THEN 'New customer'
		WHEN rfm_score LIKE '1%' THEN 'Potential customer'
		WHEN rfm_score LIKE '%1' THEN 'high monetary customers'
		ELSE 'Normal customer'
	END as segment
FROM score;
-- Sếp hạng phòng
WITH rankroom AS (
    SELECT
        DATETRUNC(month, b.check_in) AS month_of_check_in
        ,r.room_type
        ,SUM(r.price_per_night * DATEDIFF(day, b.check_in, b.check_out)) AS total_room_revenue_monthly
    FROM
        booking AS b
    JOIN
        rooms AS r ON b.room_id = r.room_id
    WHERE
        b.status = 'Confirmed'
    GROUP BY
        DATETRUNC(month, b.check_in),
        r.room_type
)
SELECT month_of_check_in
    , room_type
    , total_room_revenue_monthly,
    -- Xếp hạng loại phòng theo doanh thu trong từng tháng
    DENSE_RANK() OVER (PARTITION BY month_of_check_in ORDER BY total_room_revenue_monthly DESC) AS rank_by_revenue_monthly
FROM rankroom
ORDER BY month_of_check_in, rank_by_revenue_monthly;
-- Danh thu phòng và dịch vụ
WITH rvroom AS(
	SELECT b.customer_id
		, SUM(r.price_per_night * DATEDIFF(DAY,b.check_in,b.check_out)) as room_revenue
	FROM booking as b 
	JOIN rooms as r ON b.room_id = r.room_id
	WHERE b.status='Confirmed'
	GROUP BY b.customer_id)
, rvservice AS(
	SELECT c.customer_id
	, SUM(su.total_price) AS revenue_service
	FROM booking as b
	JOIN customer as c ON b.customer_id = c.customer_id
	LEFT JOIN service_usage as su ON b.booking_id = su.booking_id
	LEFT JOIN services_ AS s ON s.service_id = su.service_id
	WHERE b.status='Confirmed'
	GROUP BY c.customer_id
	)
SELECT SUM(room_revenue)
	, SUM(revenue_service)
FROM rvroom AS rr
JOIN rvservice AS rs ON rr.customer_id = rs.customer_id;

-- Doanh thu phòng theo từng khách hàng 

SELECT c.customer_id
	, SUM(r.price_per_night) AS revenue_of_room
FROM booking as b
JOIN rooms as r ON b.room_id = r.room_id
JOIN customer as c on b.customer_id = c.customer_id 
GROUP BY c.customer_id;

-- Tỉ lệ đặt phòng thành công

SELECT (
	(1.0*(SELECT COUNT(distinct booking_id) FROM booking WHERE status='Confirmed'))/(SELECT COUNT(*) FROM booking)
	)
SELECT COUNT(distinct booking_id) FROM booking WHERE status='Confirmed';
SELECT  SUM(su.quantity*s.price ) AS revenue_service
FROM booking as b
LEFT JOIN service_usage as su ON b.booking_id = su.booking_id
LEFT JOIN services_ AS s ON s.service_id = su.service_id
WHERE b.status='Confirmed';
-- Tỉ lệ lắp đầy phòng ( chỉ tính booking) 

WITH totalnights AS(
	SELECT DATEDIFF(DAY,'2023-02-12','2025-02-24') * COUNT(DISTINCT room_id) AS totalavailable
	FROM rooms
	)
, realnights AS(
	SELECT 
		SUM(DATEDIFF(DAY,check_in, check_out)) AS realnight
	FROM booking
	WHERE status='Confirmed'
)
SELECT (
	CAST(
		((SELECT realnight*1.0 FROM realnights)/(SELECT totalavailable*1.0 FROM totalnights))*100 AS DECIMAL(10,2)
		)
)
