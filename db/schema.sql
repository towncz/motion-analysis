IF DB_ID(N'MotionAnalysis') IS NULL
BEGIN
    CREATE DATABASE MotionAnalysis;
END
GO

USE MotionAnalysis;
GO

IF OBJECT_ID(N'dbo.FitMessages', N'U') IS NOT NULL DROP TABLE dbo.FitMessages;
IF OBJECT_ID(N'dbo.Metrics', N'U') IS NOT NULL DROP TABLE dbo.Metrics;
IF OBJECT_ID(N'dbo.Events', N'U') IS NOT NULL DROP TABLE dbo.Events;
IF OBJECT_ID(N'dbo.TrackPoints', N'U') IS NOT NULL DROP TABLE dbo.TrackPoints;
IF OBJECT_ID(N'dbo.Laps', N'U') IS NOT NULL DROP TABLE dbo.Laps;
IF OBJECT_ID(N'dbo.Sessions', N'U') IS NOT NULL DROP TABLE dbo.Sessions;
IF OBJECT_ID(N'dbo.Activities', N'U') IS NOT NULL DROP TABLE dbo.Activities;
IF OBJECT_ID(N'dbo.SourceFiles', N'U') IS NOT NULL DROP TABLE dbo.SourceFiles;
GO

CREATE TABLE dbo.SourceFiles (
    id INT IDENTITY(1,1) PRIMARY KEY,
    file_name NVARCHAR(260) NOT NULL,
    file_path NVARCHAR(1000) NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_hash CHAR(64) NOT NULL,
    imported_at DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_SourceFiles_file_hash UNIQUE (file_hash)
);
GO

CREATE TABLE dbo.Activities (
    id INT IDENTITY(1,1) PRIMARY KEY,
    source_file_id INT NOT NULL,
    activity_key NVARCHAR(120) NOT NULL,
    activity_type NVARCHAR(80) NULL,
    start_time_utc DATETIME2(3) NULL,
    local_start_time DATETIME2(3) NULL,
    device_manufacturer NVARCHAR(100) NULL,
    device_product NVARCHAR(100) NULL,
    raw_json NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Activities_SourceFiles FOREIGN KEY (source_file_id) REFERENCES dbo.SourceFiles(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Sessions (
    id INT IDENTITY(1,1) PRIMARY KEY,
    activity_id INT NOT NULL,
    start_time_utc DATETIME2(3) NULL,
    total_elapsed_time_s FLOAT NULL,
    total_timer_time_s FLOAT NULL,
    total_moving_time_s FLOAT NULL,
    total_distance_m FLOAT NULL,
    total_calories INT NULL,
    avg_speed_mps FLOAT NULL,
    max_speed_mps FLOAT NULL,
    avg_heart_rate_bpm INT NULL,
    max_heart_rate_bpm INT NULL,
    avg_cadence FLOAT NULL,
    max_cadence FLOAT NULL,
    avg_power_w INT NULL,
    max_power_w INT NULL,
    total_ascent_m INT NULL,
    total_descent_m INT NULL,
    raw_json NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Sessions_Activities FOREIGN KEY (activity_id) REFERENCES dbo.Activities(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Laps (
    id INT IDENTITY(1,1) PRIMARY KEY,
    activity_id INT NOT NULL,
    lap_index INT NOT NULL,
    start_time_utc DATETIME2(3) NULL,
    total_elapsed_time_s FLOAT NULL,
    total_timer_time_s FLOAT NULL,
    total_distance_m FLOAT NULL,
    avg_speed_mps FLOAT NULL,
    max_speed_mps FLOAT NULL,
    avg_heart_rate_bpm INT NULL,
    max_heart_rate_bpm INT NULL,
    avg_cadence FLOAT NULL,
    max_cadence FLOAT NULL,
    avg_power_w INT NULL,
    max_power_w INT NULL,
    raw_json NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Laps_Activities FOREIGN KEY (activity_id) REFERENCES dbo.Activities(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.TrackPoints (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    activity_id INT NOT NULL,
    sample_index INT NOT NULL,
    sample_time_utc DATETIME2(3) NULL,
    latitude FLOAT NULL,
    longitude FLOAT NULL,
    altitude_m FLOAT NULL,
    distance_m FLOAT NULL,
    speed_mps FLOAT NULL,
    heart_rate_bpm INT NULL,
    cadence FLOAT NULL,
    power_w INT NULL,
    accumulated_power_w INT NULL,
    vertical_oscillation_mm FLOAT NULL,
    stance_time_ms FLOAT NULL,
    raw_json NVARCHAR(MAX) NULL,
    CONSTRAINT FK_TrackPoints_Activities FOREIGN KEY (activity_id) REFERENCES dbo.Activities(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Events (
    id INT IDENTITY(1,1) PRIMARY KEY,
    activity_id INT NOT NULL,
    event_index INT NOT NULL,
    event_time_utc DATETIME2(3) NULL,
    event_type NVARCHAR(80) NULL,
    event NVARCHAR(80) NULL,
    event_group INT NULL,
    raw_json NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Events_Activities FOREIGN KEY (activity_id) REFERENCES dbo.Activities(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Metrics (
    id INT IDENTITY(1,1) PRIMARY KEY,
    activity_id INT NOT NULL,
    metric_type NVARCHAR(80) NOT NULL,
    metric_name NVARCHAR(120) NOT NULL,
    metric_value_float FLOAT NULL,
    metric_value_text NVARCHAR(400) NULL,
    unit NVARCHAR(40) NULL,
    raw_json NVARCHAR(MAX) NULL,
    CONSTRAINT FK_Metrics_Activities FOREIGN KEY (activity_id) REFERENCES dbo.Activities(id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.FitMessages (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    activity_id INT NOT NULL,
    message_index INT NOT NULL,
    global_message_num INT NOT NULL,
    message_name NVARCHAR(80) NOT NULL,
    local_message_num INT NULL,
    message_time_utc DATETIME2(3) NULL,
    raw_json NVARCHAR(MAX) NOT NULL,
    CONSTRAINT FK_FitMessages_Activities FOREIGN KEY (activity_id) REFERENCES dbo.Activities(id) ON DELETE CASCADE
);
GO

CREATE INDEX IX_Activities_type_start ON dbo.Activities(activity_type, start_time_utc);
CREATE INDEX IX_Sessions_activity ON dbo.Sessions(activity_id);
CREATE UNIQUE INDEX IX_Laps_activity_index ON dbo.Laps(activity_id, lap_index);
CREATE UNIQUE INDEX IX_TrackPoints_activity_index ON dbo.TrackPoints(activity_id, sample_index);
CREATE INDEX IX_TrackPoints_activity_time ON dbo.TrackPoints(activity_id, sample_time_utc);
CREATE INDEX IX_TrackPoints_activity_distance ON dbo.TrackPoints(activity_id, distance_m);
CREATE UNIQUE INDEX IX_Events_activity_index ON dbo.Events(activity_id, event_index);
CREATE INDEX IX_FitMessages_activity_message ON dbo.FitMessages(activity_id, message_name);
GO
