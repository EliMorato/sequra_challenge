# SQL Queries
Given the Part 3 has been successfully executed and we have a `public.launches` table available in Redshift, these queries can answer the questions proposed in the Part 4:

## Maximum number of times a core has been reused
```sql
SELECT core_id, count(1) cnt
FROM public.launches
WHERE core_id IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
```
Result:
| core_id                    | cnt      |
| -------------------------- | -------- |
| 5e9e28a7f3591817f23b2663   | 14       |


## Cores that have been reused in less than 50 days after the previous launch
```sql
WITH prev_launch_dates AS (
    SELECT core_id,
        date_utc AS launch_date,
        LAG(date_utc) OVER (PARTITION BY core_id ORDER BY date_utc) AS previous_launch_date
    FROM public.launches
    WHERE date_precision IN ('hour', 'day') AND core_id IS NOT NULL
    ORDER BY core_id, date_utc
)
SELECT core_id
FROM prev_launch_dates
WHERE DATEDIFF('days', previous_launch_date::timestamp, launch_date::timestamp) < 50
GROUP BY 1;
```
Result:
| core_id                    |
| -------------------------- |
| 5e9e28a6f35918c0803b265c   |
| 5e9e28a7f3591817f23b2663   |
| 5f57c53d0622a6330279009f   |
| 5e9e28a6f359183c413b265d   |
| 5ef670f10059c33cee4a826c   |
| 5f57c5440622a633027900a0   |
| 60b800111f83cc1e59f16438   |
| 61fae5947aa67176fe3e0e1e   |
| 627843db57b51b752c5c5a54   |

## Comments
I've decided to create a single table since it could answer all the questions asked in the Part 4.
If I were given more details regarding the usage of the data, I'd probably have denormalized SpaceX data creating a table for each concept.
For example:
- `cores` table with cores details, with core `id` as PK.
- `launches_cores` with a sequential `id` as PK, containing the `launch_id` related to `core_id` (both being FKs).
- `launches` table with only launches information with `id` as PK, with `launch_core_id` (FK) column instead of column `cores`.
