USE MotionAnalysis;
GO

-- 已导入文件
SELECT id, file_name, file_size_bytes, imported_at
FROM dbo.SourceFiles
ORDER BY imported_at DESC;

-- 活动列表
SELECT
    a.id,
    a.activity_key,
    a.activity_type,
    a.start_time_utc,
    s.total_distance_m,
    s.total_timer_time_s,
    s.avg_heart_rate_bpm,
    s.max_heart_rate_bpm,
    s.avg_speed_mps
FROM dbo.Activities a
LEFT JOIN dbo.Sessions s ON s.activity_id = a.id
ORDER BY a.start_time_utc DESC;

-- 各运动类型统计
SELECT
    a.activity_type,
    COUNT(*) AS activity_count,
    SUM(s.total_distance_m) AS total_distance_m,
    SUM(s.total_timer_time_s) AS total_timer_time_s,
    AVG(CAST(s.avg_heart_rate_bpm AS FLOAT)) AS avg_heart_rate_bpm
FROM dbo.Activities a
LEFT JOIN dbo.Sessions s ON s.activity_id = a.id
GROUP BY a.activity_type
ORDER BY activity_count DESC;

-- 单次活动的轨迹点、心率、速度数据示例：把 @activity_id 改成目标活动 ID
DECLARE @activity_id INT = (SELECT TOP 1 id FROM dbo.Activities ORDER BY start_time_utc DESC);

SELECT sample_index, sample_time_utc, latitude, longitude, altitude_m, distance_m, speed_mps, heart_rate_bpm, cadence, power_w
FROM dbo.TrackPoints
WHERE activity_id = @activity_id
ORDER BY sample_index;

SELECT lap_index, start_time_utc, total_distance_m, total_timer_time_s, avg_speed_mps, avg_heart_rate_bpm, avg_power_w
FROM dbo.Laps
WHERE activity_id = @activity_id
ORDER BY lap_index;

-- 表数据量和空间占用，用于说明大数据量下的执行效率
SELECT
    t.name AS table_name,
    SUM(p.rows) AS row_count
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY row_count DESC;

-- 查看当前数据库中已建立的索引
SELECT
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc
FROM sys.indexes i
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND i.name IS NOT NULL
ORDER BY table_name, index_name;
