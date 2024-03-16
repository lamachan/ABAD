USE DB_STAT
GO

CREATE TABLE dbo.test_ograniczenia
(
	id NCHAR(5) NOT NULL,
	ograniczenie BIT NOT NULL DEFAULT 0 -- DEFAULT nakłada ograniczenie
)
GO

INSERT INTO test_ograniczenia (id) VALUES (N'ala')
INSERT INTO test_ograniczenia (id, ograniczenie) VALUES (N'kot', 1)
SELECT * FROM test_ograniczenia
/*
id    ograniczenie
----- ------------
ala   0
kot   1

Tabela powstała, DEFAULT działa poprawnie.*/

ALTER TABLE test_ograniczenia DROP COLUMN ograniczenie
/*
Msg 5074, Level 16, State 1, Line 23
The object 'DF__test_ogra__ogran__35BCFE0A' is dependent on column 'ograniczenie'.
Msg 4922, Level 16, State 9, Line 23
ALTER TABLE DROP COLUMN ograniczenie failed because one or more objects access this column.

Nie można usunąć kolumny 'ograniczenie', ponieważ jest na nią nałożone ograniczenie 'DF__test_ogra__ogran__35BCFE0A'.*/

SELECT CONVERT(NVARCHAR(30), oc.name) AS constraint_name
FROM sys.objects o
	JOIN sys.objects oc
		ON o.object_id = oc.parent_object_id 
	JOIN sys.sysconstraints c
		ON c.constid = oc.object_id 
	JOIN sys.columns col
		ON col.object_id = o.object_id 
			AND col.column_id = c.colid
WHERE o.name = 'test_ograniczenia'
	AND col.name = 'ograniczenie'
/*
constraint_name
------------------------------
DF__test_ogra__ogran__35BCFE0A

Nazwa automatycznie przyznanego przez DEFAULT ograniczenia.*/

GO
ALTER PROCEDURE dbo.usun_kolumne (@dbname NVARCHAR(100), @tablename NVARCHAR(100), @colname NVARCHAR(100))
AS
	DECLARE @sql NVARCHAR(2000),
		@col_exists BIT,
		@constraint_name NVARCHAR(100)

	SET @sql = N'USE ' + @dbname + N'; '
		+ 'IF EXISTS (
				SELECT 1
				FROM sys.tables t
					JOIN sys.columns c ON t.object_id = c.object_id
				WHERE t.name = N''' + @tablename + N''' 
					AND c.name = N''' + @colname + N'''
			)
			BEGIN
				SET @col_exists = 1;
			END
			ELSE
			BEGIN
				SET @col_exists = 0;
			END'
	EXEC sp_executesql @sql, N'@col_exists BIT OUTPUT', @col_exists OUTPUT

	IF @col_exists = 0
	BEGIN
		DECLARE @error_msg NVARCHAR(100) = N'Kolumna ''' + @colname + N''' nie istnieje w tabeli ''' + @tablename + N''' w bazie ''' + @dbname + N'''!'
		RAISERROR(@error_msg, 16, 1)
		RETURN
	END

	CREATE TABLE #tc (constraint_name NVARCHAR(100))

	SET @sql = N'USE ' + @dbname + N'; '
		+ N'INSERT INTO #tc (constraint_name)'
		+ N'SELECT oc.name
			FROM sys.objects o
				JOIN sys.objects oc ON o.object_id = oc.parent_object_id 
				JOIN sys.sysconstraints c ON c.constid = oc.object_id 
				JOIN sys.columns col ON col.object_id = o.object_id AND col.column_id = c.colid
			WHERE o.name = N''' + @tablename + N'''
				AND col.name = N''' + @colname + N''''
	EXEC sp_sqlexec @sql

	DECLARE CC INSENSITIVE CURSOR FOR 
		SELECT c.constraint_name
		FROM #tc c
		ORDER BY 1
	OPEN CC
	FETCH NEXT FROM CC INTO @constraint_name
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = N'USE ' + @dbname + N'; '
			+ N'ALTER TABLE ' + @tablename + N' DROP CONSTRAINT ' + @constraint_name
		EXEC sp_sqlexec @sql

		FETCH NEXT FROM CC INTO @constraint_name
	END
	CLOSE CC
	DEALLOCATE CC

	SET @sql = N'USE ' + @dbname + N'; '
		+ N'ALTER TABLE ' + @tablename + N' DROP COLUMN ' + @colname
	EXEC sp_sqlexec @sql
GO

EXEC usun_kolumne N'DB_STAT', N'test_ograniczenia', N'ograniczenie'

SELECT * FROM test_ograniczenia
/*
id
-----
ala  
kot  

Kolumna z ograniczeniem 'ograniczenie' została pomyślnie usunięta.*/