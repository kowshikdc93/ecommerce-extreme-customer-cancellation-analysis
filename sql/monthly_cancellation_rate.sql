-- Monthly cancellation rate (distinct items, generic template).
-- Item ids can collide across markets, so multi-market counts use a composite key.
SELECT TO_CHAR(order_date, 'yyyy-mm') AS month,
       100.0 * COUNT(DISTINCT CASE WHEN item_status = 'cancelled_by_customer'
                                   THEN market || '_' || order_item_id END)
             / NULLIF(COUNT(DISTINCT market || '_' || order_item_id), 0) AS cancellation_rate_pct
FROM   analytics_schema.order_table
GROUP  BY TO_CHAR(order_date, 'yyyy-mm')
ORDER  BY month;
