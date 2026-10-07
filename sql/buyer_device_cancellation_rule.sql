-- Buyer and device level repeat-cancellation rule (generic template, placeholder parameters).
-- Flags buyer / device pairs whose cancellation rate and cancelled item count in a look-back
-- window both cross a threshold.
--
-- Placeholder parameters (set to your own values):
--   :lookback_days     look-back window in days
--   :min_cancel_rate   minimum cancellation rate, in percent
--   :min_cancel_items  minimum number of cancelled items

WITH items AS (
    SELECT buyer_id, order_id, order_item_id, item_status
    FROM   analytics_schema.order_table
    WHERE  order_date >= CURRENT_DATE - :lookback_days
),
device_orders AS (
    SELECT DISTINCT device_id, buyer_id, order_id
    FROM   analytics_schema.risk_event_table
    WHERE  event_date >= CURRENT_DATE - :lookback_days
      AND  device_id IS NOT NULL AND device_id <> ''
),
device_buyer_stats AS (
    SELECT d.device_id,
           i.buyer_id,
           COUNT(DISTINCT i.order_item_id) AS total_items,
           COUNT(DISTINCT CASE WHEN i.item_status = 'cancelled_by_customer'
                               THEN i.order_item_id END) AS cancelled_items
    FROM   items i
    JOIN   device_orders d
           ON i.order_id = d.order_id AND i.buyer_id = d.buyer_id
    GROUP  BY d.device_id, i.buyer_id
)
SELECT device_id,
       buyer_id,
       total_items,
       cancelled_items,
       100.0 * cancelled_items / NULLIF(total_items, 0) AS cancellation_rate_pct
FROM   device_buyer_stats
WHERE  100.0 * cancelled_items / NULLIF(total_items, 0) >= :min_cancel_rate
  AND  cancelled_items >= :min_cancel_items
ORDER  BY cancelled_items DESC;
