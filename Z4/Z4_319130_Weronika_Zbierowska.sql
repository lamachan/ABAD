/* Weronika Zbierowska
nr indeksu: 319130*/

/* OPIS WYMAGAŃ:
** Stworzymy narzędzia:
** 0) Tabele/procedury mają działać dla wszyskich baz na naszym serwerze.
** Narzędzia mają służyć do (wszystko procedurami SQL zapamiętanymi na bazie DB_STAT):
** WA) Zapamiętywania stanu bazy:
** - liczby rekordów
** - indeksów w tabeli
** - kluczy obcych
** WB) Ma być możliwość skasowania wszystkich kluczy obcych za pomocą procedury
**   w zadanej bazie !!!
**   Taka procedura ma najpierw zapamiętać w tabeli jakie są klucze,
**   a potem je skasować TYLKO JAK SIE UDA ZAPAMIETAC NAJPIERW KLUCZE.
** WC) Ma być możliwość odtworzenia kluczy obcych procedurą na wybranej bazie.
**	   Podajemy według jakiego stanu (ID stanu), jak NULL to 
**     procedura szuka ostatniego stanu dla tej bazy i odtwarza ten stan.
*/

/* OPIS SPOSOBU REALIZACJI:
** 1. Tworzę bazę DB_STAT, w której będą przechowywane wszystkie tabele i procedury z Z4.
** 2. Tworzę tabele:
**    a) DB_STAT - informacje o zebraniu statystyk (wszystkich lub tylko kluczy)
**    b) DB_RCOUNT - liczby rekordów w tabelach użytkownika
**    c) DB_INDEX - indeksy w tabelach użytkownika
**    d) DB_FK - klucze obce w tabelach
** 3. Tworzę procedury:
**    a) db_stats - zebranie wszystkich statystyk (liczba rekordów, indeksy, klucze obce)
**					z zadanej bazy @dbname
**    b) db_stats_all - zebranie wszystkich statystyk ze wszystkich baz niesystemowych na serwerze
**    c) db_delete_fk - zapis informacji o wszystkich kluczach obcych i usunięcie ich
**						w zadanej bazie @dbname
**    d) db_restore_fk - odtworzenie wszystkich kluczy obcych w zadanej bazie na podstawie zadanego
**						 @stat_id lub ostatniego znalezionego stanu kluczy (przy @stat_id = NULL)
*/

IF NOT EXISTS
(
	SELECT d.name 
	FROM sys.databases d 
	WHERE (d.database_id > 4) -- systemowe mają ID poniżej 5
		AND (d.[name] = N'DB_STAT')
)
BEGIN
	CREATE DATABASE DB_STAT
END
GO

USE DB_STAT
GO

IF NOT EXISTS 
(
	SELECT 1
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = N'DB_STAT')
		AND (OBJECTPROPERTY(o.[ID], N'IsUserTable') = 1)
)
BEGIN
	CREATE TABLE dbo.DB_STAT
	(
		stat_id INT NOT NULL IDENTITY CONSTRAINT PK_DB_STAT PRIMARY KEY,
		dbname	NVARCHAR(20) NOT NULL,
		comment	NVARCHAR(20) NOT NULL,
		date_stat DATETIME NOT NULL DEFAULT GETDATE(),
		username NVARCHAR(100) NOT NULL DEFAULT USER_NAME(),
		hostname NVARCHAR(100) NOT NULL DEFAULT HOST_NAME()
	)
END
GO

IF NOT EXISTS 
(
	SELECT 1 
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = N'DB_RCOUNT')
		AND (OBJECTPROPERTY(o.[ID], N'IsUserTable') = 1)
)
BEGIN
	CREATE TABLE dbo.DB_RCOUNT
	(
		stat_id INT NOT NULL CONSTRAINT FK_DB_STAT_RCOUNT FOREIGN KEY REFERENCES dbo.DB_STAT(stat_id),
		tablename NVARCHAR(100) NOT NULL,
		n_records INT NOT NULL DEFAULT 0
	)
END
GO

IF NOT EXISTS 
(
	SELECT 1 
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = N'DB_INDEX')
		AND (OBJECTPROPERTY(o.[ID], N'IsUserTable') = 1)
)
BEGIN
	CREATE TABLE dbo.DB_INDEX
	(
		stat_id INT NOT NULL CONSTRAINT FK_DB_STAT_INDEX FOREIGN KEY REFERENCES dbo.DB_STAT(stat_id),
		tablename NVARCHAR(100) NOT NULL,
		colname NVARCHAR(100) NOT NULL,
		indexname NVARCHAR(100) NOT NULL,
		index_type NVARCHAR(30) NOT NULL
	)
END
GO

IF NOT EXISTS 
(
	SELECT 1 
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = N'DB_FK')
		AND (OBJECTPROPERTY(o.[ID], N'IsUserTable') = 1)
)
BEGIN
	CREATE TABLE dbo.DB_FK
	(
		stat_id INT NOT NULL CONSTRAINT FK_DB_STAT_FK FOREIGN KEY REFERENCES dbo.DB_STAT(stat_id),
		fk_name NVARCHAR(100) NOT NULL,
		constrained_table NVARCHAR(100) NOT NULL,
		constrained_col NVARCHAR(100) NOT NULL,
		reference_table NVARCHAR(100) NOT NULL,
		reference_col NVARCHAR(100) NOT NULL
	)
END
GO

IF NOT EXISTS 
(
	SELECT 1 
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = 'db_stats')
		AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
)
BEGIN
	DECLARE @stmt NVARCHAR(100)
	SET @stmt = 'CREATE PROCEDURE dbo.db_stats AS '
	EXEC sp_sqlexec @stmt
END
GO

ALTER PROCEDURE dbo.db_stats (@dbname NVARCHAR(100), @comment NVARCHAR(20) = 'db_stats')
AS
	DECLARE @sql NVARCHAR(2000),		-- tu będzie polecenie SQL wstawiajace wynik do tabeli
			@id INT,					-- id nadane po wstawieniu rekordu do tabeli DB_STAT 
			@text_id NVARCHAR(20),		-- skonwertowane @id na tekst

			@tablename NVARCHAR(256)	-- nazwa kolejnej tabeli
	
	SET @dbname = LTRIM(RTRIM(@dbname))

	INSERT INTO DB_STAT.dbo.DB_STAT (dbname, comment) VALUES (@dbname, @comment)
	SET @id = SCOPE_IDENTITY()
	SET @text_id = RTRIM(LTRIM(STR(@id, 20, 0)))

	CREATE TABLE #TC (tablename NVARCHAR(100))

	SET @sql = N'USE [' + @dbname + N']; INSERT INTO #TC (tablename) '
			+ N' SELECT o.[name] FROM sysobjects o '
			+ N' WHERE (OBJECTPROPERTY(o.[ID], N''isUserTable'') = 1)'
	EXEC sp_sqlexec @sql

	--kursor po wszystkich tabelach użytkownika
	DECLARE CC INSENSITIVE CURSOR FOR 
		SELECT o.tablename
		FROM #TC o
		ORDER BY 1
	OPEN CC
	FETCH NEXT FROM CC INTO @tablename
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @tablename = LTRIM(RTRIM(@tablename))

		-- zarejestruj liczbę wierszy
		SET @sql = N'USE [' + @dbname + N']; '
					+ N'INSERT INTO DB_STAT.dbo.DB_RCOUNT (stat_id, tablename, n_records) SELECT '
					+ @text_id + ', N'''
					+ @tablename + N''', COUNT(*) FROM [' + @dbname + N']..' + @tablename
		EXEC sp_sqlexec @sql

		-- zarejestruj indeksy
		SET @sql = N'USE [' + @dbname + N']; '
				+ N' INSERT INTO DB_STAT.dbo.DB_INDEX (stat_id, tablename, colname, indexname, index_type) '
				+ N' SELECT ' + @text_id + N', N''' + @tablename + N''', c.name, i.name, i.type_desc '
				+ N' FROM sys.indexes i
					INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
					INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id '
				+ N' WHERE OBJECT_NAME(i.object_id) = N''' + @tablename + N''''
		EXEC sp_sqlexec @sql

		FETCH NEXT FROM CC INTO @tablename
	END
	CLOSE CC
	DEALLOCATE CC

	-- zarejestruj klucze obce
	SET @sql = N'USE [' + @dbname + N']; '
			+ N' INSERT INTO DB_STAT.dbo.DB_FK (stat_id, fk_name, constrained_table, constrained_col, reference_table, reference_col) '
			+ N' SELECT ' + @text_id + ', f.name, OBJECT_NAME(f.parent_object_id), COL_NAME(fc.parent_object_id, fc.parent_column_id), 
				OBJECT_NAME (f.referenced_object_id), COL_NAME(fc.referenced_object_id, fc.referenced_column_id) '
			+ N' FROM sys.foreign_keys AS f
				JOIN sys.foreign_key_columns AS fc ON f.[object_id] = fc.constraint_object_id '
			+ N' ORDER BY f.name'
	EXEC sp_sqlexec @sql
GO

EXEC DB_STAT.dbo.db_stats N'BAZA1'

SELECT s.stat_id,
	CONVERT(NVARCHAR(10), s.dbname) AS dbname,
	CONVERT(NVARCHAR(10), s.comment) AS comment,
	s.date_stat,
	CONVERT(NVARCHAR(10), s.username) AS username,
	CONVERT(NVARCHAR(10), s.hostname) AS hostname
FROM DB_STAT s
/*
stat_id     dbname     comment    date_stat               username   hostname
----------- ---------- ---------- ----------------------- ---------- ----------
1           BAZA1      db_stats   2023-12-06 12:24:44.507 dbo        WERA

Fakt zebrania statystyk został odnotowany w tabeli DB_STAT. */

SELECT r.stat_id,
	CONVERT(NVARCHAR(10), r.tablename) AS tablename,
	r.n_records
FROM DB_RCOUNT r
/*
stat_id     tablename  n_records
----------- ---------- -----------
1           etaty      8
1           miasta     9
1           osoby      12
1           woj        8

Policzono liczbę rekordów dla wszystkich tabel użytkownika. */

SELECT i.stat_id,
	CONVERT(NVARCHAR(10), i.tablename) AS tablename,
	CONVERT(NVARCHAR(10), i.colname) AS colname,
	CONVERT(NVARCHAR(10), i.indexname) AS indexname,
	CONVERT(NVARCHAR(10), i.index_type) AS index_type
FROM DB_INDEX i
/*
stat_id     tablename  colname    indexname  index_type
----------- ---------- ---------- ---------- ----------
1           etaty      id_etatu   PK_ETATY   CLUSTERED
1           miasta     id_miasta  PK_MIASTA  CLUSTERED
1           osoby      id_osoby   PK_OSOBY   CLUSTERED
1           woj        kod_woj    PK_WOJ     CLUSTERED

Zebrano informacje o wszystkich indeksach w tabelach użytkownika.
Tu widać tylko indeksy powstałe z kluczy głównych w tabelach. */

SELECT f.stat_id,
	CONVERT(NVARCHAR(15), f.fk_name) AS tablename,
	CONVERT(NVARCHAR(20), f.constrained_table) AS constrained_table,
	CONVERT(NVARCHAR(15), f.constrained_col) AS constrained_col,
	CONVERT(NVARCHAR(15), f.reference_table) AS reference_table,
	CONVERT(NVARCHAR(15), f.reference_col) AS reference_col
FROM DB_FK f
/*
stat_id     tablename       constrained_table    constrained_col reference_table reference_col
----------- --------------- -------------------- --------------- --------------- ---------------
1           FK_MIASTA_WOJ   miasta               kod_woj         woj             kod_woj
1           FK_OSOBY_MIASTA osoby                id_miasta       miasta          id_miasta
1           FK_ETATY_OSOBY  etaty                id_osoby        osoby           id_osoby

Zapisano wszystkie informacje o kluczach obcych w tabelach użytkownika,
które są potrzebne do późniejszego ich odtworzenia. */

IF NOT EXISTS 
(
	SELECT 1 
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = 'db_stats_all')
		AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
)
BEGIN
	DECLARE @stmt NVARCHAR(100)
	SET @stmt = 'CREATE PROCEDURE dbo.db_stats_all AS '
	EXEC sp_sqlexec @stmt
END
GO

ALTER PROCEDURE dbo.db_stats_all (@comment NVARCHAR(20) = N'db_stats_all')
AS
	DECLARE @dbname NVARCHAR(100)	-- nazwa kolejnej bazy

	--kursor po wszystkich bazach niesystemowych
	DECLARE CCA INSENSITIVE CURSOR FOR
		SELECT d.name 
		FROM sys.databases d
		WHERE d.database_id > 4 -- ponizej 5 są systemowe
	OPEN CCA
	FETCH NEXT FROM CCA INTO @dbname
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC DB_STAT.dbo.db_stats @dbname, @comment

		FETCH NEXT FROM CCA INTO @dbname
	END
	CLOSE CCA
	DEALLOCATE CCA
GO

EXEC DB_STAT.dbo.db_stats_all

SELECT s.stat_id,
	CONVERT(NVARCHAR(15), s.dbname) AS dbname,
	CONVERT(NVARCHAR(15), s.comment) AS comment,
	s.date_stat,
	CONVERT(NVARCHAR(10), s.username) AS username,
	CONVERT(NVARCHAR(10), s.hostname) AS hostname
FROM DB_STAT s
/*
stat_id     dbname          comment         date_stat               username   hostname
----------- --------------- --------------- ----------------------- ---------- ----------
1           BAZA1           db_stats        2023-12-06 12:24:44.507 dbo        WERA
2           APBD23_ADM      db_stats_all    2023-12-06 12:39:48.940 dbo        WERA
3           APBD23_TEST     db_stats_all    2023-12-06 12:39:49.727 dbo        WERA
4           A               db_stats_all    2023-12-06 12:39:49.820 dbo        WERA
5           B               db_stats_all    2023-12-06 12:39:49.920 dbo        WERA
6           C               db_stats_all    2023-12-06 12:39:50.017 dbo        WERA
7           D               db_stats_all    2023-12-06 12:39:50.113 dbo        WERA
8           E               db_stats_all    2023-12-06 12:39:50.213 dbo        WERA
9           F               db_stats_all    2023-12-06 12:39:50.313 dbo        WERA
10          G               db_stats_all    2023-12-06 12:39:50.427 dbo        WERA
11          H               db_stats_all    2023-12-06 12:39:50.560 dbo        WERA
12          I               db_stats_all    2023-12-06 12:39:50.680 dbo        WERA
13          J               db_stats_all    2023-12-06 12:39:50.780 dbo        WERA
14          K               db_stats_all    2023-12-06 12:39:50.880 dbo        WERA
15          L               db_stats_all    2023-12-06 12:39:50.977 dbo        WERA
16          M               db_stats_all    2023-12-06 12:39:51.073 dbo        WERA
17          N               db_stats_all    2023-12-06 12:39:51.167 dbo        WERA
18          O               db_stats_all    2023-12-06 12:39:51.257 dbo        WERA
19          P               db_stats_all    2023-12-06 12:39:51.347 dbo        WERA
20          Q               db_stats_all    2023-12-06 12:39:51.437 dbo        WERA
21          BAZA1           db_stats_all    2023-12-06 12:39:51.560 dbo        WERA
22          BAZA2           db_stats_all    2023-12-06 12:39:51.840 dbo        WERA
23          BAZA3           db_stats_all    2023-12-06 12:39:52.120 dbo        WERA
24          BAZA4           db_stats_all    2023-12-06 12:39:52.437 dbo        WERA
25          BAZA5           db_stats_all    2023-12-06 12:39:52.553 dbo        WERA
26          DB_STAT         db_stats_all    2023-12-06 12:39:52.677 dbo        WERA

(26 rows affected)

Zebrano statystyki dla wszystkich baz niesystemowych. */

SELECT r.stat_id,
	CONVERT(NVARCHAR(15), r.tablename) AS tablename,
	r.n_records
FROM DB_RCOUNT r
/*
stat_id     tablename       n_records
----------- --------------- -----------
1           etaty           8
1           miasta          9
1           osoby           12
1           woj             8
2           BK_LOG          58
2           CRDB_LOG        26
2           CRUSR_LOG       26
2           DB_CHECK        30
2           DB_CHECK_ITEMS  172
21          etaty           8
21          miasta          9
21          osoby           12
21          woj             8
22          etaty           8
22          miasta          9
22          osoby           12
22          woj             7
23          etaty           12
23          miasta          9
23          osoby           16
23          woj             7
26          DB_FK           13
26          DB_INDEX        20
26          DB_RCOUNT       23
26          DB_STAT         26

(25 rows affected)
*/

SELECT i.stat_id,
	CONVERT(NVARCHAR(10), i.tablename) AS tablename,
	CONVERT(NVARCHAR(10), i.colname) AS colname,
	CONVERT(NVARCHAR(15), i.indexname) AS indexname,
	CONVERT(NVARCHAR(10), i.index_type) AS index_type
FROM DB_INDEX i
/*
stat_id     tablename  colname    indexname       index_type
----------- ---------- ---------- --------------- ----------
1           etaty      id_etatu   PK_ETATY        CLUSTERED
1           miasta     id_miasta  PK_MIASTA       CLUSTERED
1           osoby      id_osoby   PK_OSOBY        CLUSTERED
1           woj        kod_woj    PK_WOJ          CLUSTERED
2           BK_LOG     id_bk      PK_BK_LOG       CLUSTERED
2           CRDB_LOG   id         PK_CRDB_LOG     CLUSTERED
2           CRUSR_LOG  id         PK_CRUSR_LOG    CLUSTERED
2           DB_CHECK   check_id   PK_DB_CHECK     CLUSTERED
21          etaty      id_etatu   PK_ETATY        CLUSTERED
21          miasta     id_miasta  PK_MIASTA       CLUSTERED
21          osoby      id_osoby   PK_OSOBY        CLUSTERED
21          woj        kod_woj    PK_WOJ          CLUSTERED
22          etaty      id_etatu   PK_ETATY        CLUSTERED
22          miasta     id_miasta  PK_MIASTA       CLUSTERED
22          osoby      id_osoby   PK_OSOBY        CLUSTERED
22          woj        kod_woj    PK_WOJ          CLUSTERED
23          etaty      id_etatu   PK_ETATY        CLUSTERED
23          miasta     id_miasta  PK_MIASTA       CLUSTERED
23          osoby      id_osoby   PK_OSOBY        CLUSTERED
23          woj        kod_woj    PK_WOJ          CLUSTERED
26          DB_STAT    stat_id    PK_DB_STAT      CLUSTERED

(21 rows affected)
*/

SELECT f.stat_id,
	CONVERT(NVARCHAR(30), f.fk_name) AS tablename,
	CONVERT(NVARCHAR(20), f.constrained_table) AS constrained_table,
	CONVERT(NVARCHAR(15), f.constrained_col) AS constrained_col,
	CONVERT(NVARCHAR(15), f.reference_table) AS reference_table,
	CONVERT(NVARCHAR(15), f.reference_col) AS reference_col
FROM DB_FK f
/*
stat_id     tablename                      constrained_table    constrained_col reference_table reference_col
----------- ------------------------------ -------------------- --------------- --------------- ---------------
1           FK_MIASTA_WOJ                  miasta               kod_woj         woj             kod_woj
1           FK_OSOBY_MIASTA                osoby                id_miasta       miasta          id_miasta
1           FK_ETATY_OSOBY                 etaty                id_osoby        osoby           id_osoby
2           FK_DB_CHECK_DB_CHECK_ITEMS     DB_CHECK_ITEMS       check_id        DB_CHECK        check_id
21          FK_MIASTA_WOJ                  miasta               kod_woj         woj             kod_woj
21          FK_OSOBY_MIASTA                osoby                id_miasta       miasta          id_miasta
21          FK_ETATY_OSOBY                 etaty                id_osoby        osoby           id_osoby
22          FK_MIASTA_WOJ                  miasta               kod_woj         woj             kod_woj
22          FK_OSOBY_MIASTA                osoby                id_miasta       miasta          id_miasta
22          FK_ETATY_OSOBY                 etaty                id_osoby        osoby           id_osoby
23          FK_MIASTA_WOJ                  miasta               kod_woj         woj             kod_woj
23          FK_OSOBY_MIASTA                osoby                id_miasta       miasta          id_miasta
23          FK_ETATY_OSOBY                 etaty                id_osoby        osoby           id_osoby
26          FK_DB_STAT_RCOUNT              DB_RCOUNT            stat_id         DB_STAT         stat_id
26          FK_DB_STAT_INDEX               DB_INDEX             stat_id         DB_STAT         stat_id
26          FK_DB_STAT_FK                  DB_FK                stat_id         DB_STAT         stat_id

(16 rows affected)
*/

IF NOT EXISTS 
(
	SELECT 1 
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = 'db_delete_fk')
		AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
)
BEGIN
	DECLARE @stmt NVARCHAR(100)
	SET @stmt = 'CREATE PROCEDURE dbo.db_delete_fk AS '
	EXEC sp_sqlexec @stmt
END
GO

ALTER PROCEDURE dbo.db_delete_fk (@dbname NVARCHAR(100), @comment NVARCHAR(20) = N'db_delete_fk')
AS
	DECLARE @sql NVARCHAR(2000),		-- tu będzie polecenie SQL wstawiajace wynik do tabeli
			@id INT,					-- id nadane po wstawieniu rekordu do tabeli DB_STAT 
			@text_id NVARCHAR(20),		-- skonwertowane @id na tekst

			@tablename NVARCHAR(256),	-- nazwa kolejnej tabeli
			@fkname NVARCHAR(100)		-- nazwa kolejnego klucza obcego
	
	SET @dbname = LTRIM(RTRIM(@dbname))

	INSERT INTO DB_STAT.dbo.DB_STAT (dbname, comment) VALUES (@dbname, @comment)
	SET @id = SCOPE_IDENTITY()
	SET @text_id = RTRIM(LTRIM(STR(@id, 20, 0)))

	CREATE TABLE #T_FK
	(
		stat_id INT,
		fk_name NVARCHAR(100),
		constrained_table NVARCHAR(100),
		constrained_col NVARCHAR(100),
		reference_table NVARCHAR(100),
		reference_col NVARCHAR(100)
	)

	SET @sql = N'USE [' + @dbname + N']; '
			+ N' INSERT INTO #T_FK (stat_id, fk_name, constrained_table, constrained_col, reference_table, reference_col) '
			+ N' SELECT ' + @text_id + ', f.name, OBJECT_NAME(f.parent_object_id), COL_NAME(fc.parent_object_id, fc.parent_column_id), 
				OBJECT_NAME (f.referenced_object_id), COL_NAME(fc.referenced_object_id, fc.referenced_column_id) '
			+ N' FROM sys.foreign_keys AS f
				JOIN sys.foreign_key_columns AS fc ON f.[object_id] = fc.constraint_object_id '
			+ N' ORDER BY f.name'
	EXEC sp_sqlexec @sql

	SET @sql = N' INSERT INTO DB_STAT.dbo.DB_FK (stat_id, fk_name, constrained_table, constrained_col, reference_table, reference_col) '
			+ N' SELECT * FROM #T_FK'
	EXEC sp_sqlexec @sql

	-- kursor po wszystkich kluczach obcych i nazwach tabel, w których są
	DECLARE CC INSENSITIVE CURSOR FOR 
		SELECT f.constrained_table,
			f.fk_name
		FROM #T_FK f
		ORDER BY 1
	OPEN CC
	FETCH NEXT FROM CC INTO @tablename, @fkname
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @tablename = LTRIM(RTRIM(@tablename))
		SET @fkname = LTRIM(RTRIM(@fkname))

		SET @sql = N'USE [' + @dbname + N']; '
			+ N' ALTER TABLE [' + @tablename + N'] DROP CONSTRAINT [' + @fkname + N']'
		EXEC sp_sqlexec @sql

		FETCH NEXT FROM CC INTO @tablename, @fkname
	END
	CLOSE CC
	DEALLOCATE CC
GO

EXEC DB_STAT.dbo.db_delete_fk N'BAZA1'

SELECT TOP 1
	s.stat_id,
	CONVERT(NVARCHAR(15), s.dbname) AS dbname,
	CONVERT(NVARCHAR(15), s.comment) AS comment,
	s.date_stat,
	CONVERT(NVARCHAR(10), s.username) AS username,
	CONVERT(NVARCHAR(10), s.hostname) AS hostname
FROM DB_STAT s
ORDER BY s.stat_id DESC
/*
stat_id     dbname          comment         date_stat               username   hostname
----------- --------------- --------------- ----------------------- ---------- ----------
27          BAZA1           db_delete_fk    2023-12-06 13:40:33.190 dbo        WERA

Fakt zebrania informacji o kluczach obcych został zapisany w tabeli DB_STAT. */

SELECT f.stat_id,
	CONVERT(NVARCHAR(15), f.fk_name) AS tablename,
	CONVERT(NVARCHAR(20), f.constrained_table) AS constrained_table,
	CONVERT(NVARCHAR(15), f.constrained_col) AS constrained_col,
	CONVERT(NVARCHAR(15), f.reference_table) AS reference_table,
	CONVERT(NVARCHAR(15), f.reference_col) AS reference_col
FROM DB_FK f
WHERE f.stat_id = 27
/*
stat_id     tablename       constrained_table    constrained_col reference_table reference_col
----------- --------------- -------------------- --------------- --------------- ---------------
27          FK_MIASTA_WOJ   miasta               kod_woj         woj             kod_woj
27          FK_OSOBY_MIASTA osoby                id_miasta       miasta          id_miasta
27          FK_ETATY_OSOBY  etaty                id_osoby        osoby           id_osoby

(3 rows affected)

Zapisano informacje o wszystkich kluczach obcych. */

USE BAZA1
SELECT f.name AS tablename,
	OBJECT_NAME(f.parent_object_id) AS constrained_table,
	COL_NAME(fc.parent_object_id, fc.parent_column_id) AS constrained_col, 
	OBJECT_NAME (f.referenced_object_id) AS reference_table,
	COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS reference_col
FROM sys.foreign_keys AS f
	JOIN sys.foreign_key_columns AS fc ON f.[object_id] = fc.constraint_object_id
ORDER BY f.name
/*
tablename   constrained_table   constrained_col   reference_table   reference_col
---------   -----------------   ---------------   ---------------   -------------

(0 rows affected)

W bazie 'BAZA1' nie ma obecnie żadnych kluczy obcych - zostały poprawnie usunięte. */

IF NOT EXISTS 
(
	SELECT 1 
	FROM sysobjects o (NOLOCK)
	WHERE (o.[name] = 'db_restore_fk')
		AND (OBJECTPROPERTY(o.[ID], 'IsProcedure') = 1)
)
BEGIN
	DECLARE @stmt NVARCHAR(100)
	SET @stmt = 'CREATE PROCEDURE dbo.db_restore_fk AS '
	EXEC sp_sqlexec @stmt
END
GO

ALTER PROCEDURE dbo.db_restore_fk (@dbname NVARCHAR(100), @stat_id INT = NULL)
AS
	DECLARE @sql NVARCHAR(2000),			-- tu będzie polecenie SQL wstawiajace wynik do tabeli
		@text_id NVARCHAR(20),				-- skonwertowane @stat_id na tekst

		@fk_name NVARCHAR(100),				-- nazwa kolejnego klucza obcego
		@constrained_table NVARCHAR(100),	-- nazwa kolejnej tabli, w której jest klucz obcy
		@constrained_col NVARCHAR(100),		-- nazwa kolejnej kolumny, która jest kluczem obcym
		@reference_table NVARCHAR(100),		-- nazwa kolejnej tabeli, na którą wskazuje klucz obcy
		@reference_col NVARCHAR(100)		-- nazwa kolejnej kolumny, na którą wskazuje klucz obcy

	-- znalezienie ostatniego 'stat_id' zawierającego informację o kluczach obcych w danej bazie
	IF @stat_id IS NULL
	BEGIN
		SELECT @stat_id = MAX(s.stat_id)
		FROM DB_STAT.dbo.DB_STAT s
		WHERE s.dbname = @dbname
			AND EXISTS
			(
				SELECT 1
				FROM DB_STAT.dbo.DB_FK f
				WHERE f.stat_id = s.stat_id
			)
	END
	SET @text_id = RTRIM(LTRIM(STR(@stat_id, 20, 0)))

	CREATE TABLE #T_FK
	(
		stat_id INT,
		fk_name NVARCHAR(100),
		constrained_table NVARCHAR(100),
		constrained_col NVARCHAR(100),
		reference_table NVARCHAR(100),
		reference_col NVARCHAR(100)
	)

	SET @sql = N' INSERT INTO #T_FK '
			+ N' SELECT * FROM DB_STAT.dbo.DB_FK f '
			+ N' WHERE f.stat_id = ' + @text_id
	EXEC sp_sqlexec @sql

	-- kursor po wszystkich kluczach obcych (i informacjach o nich)
	DECLARE CC INSENSITIVE CURSOR FOR 
		SELECT f.fk_name,
			f.constrained_table,
			f.constrained_col,
			f.reference_table,
			f.reference_col
		FROM #T_FK f
		ORDER BY 1
	OPEN CC
	FETCH NEXT FROM CC INTO @fk_name, @constrained_table, @constrained_col, @reference_table, @reference_col
	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		SET @sql = N'USE [' + @dbname + N']; '
			+ N' ALTER TABLE [' + @constrained_table + N'] ADD CONSTRAINT ['
			+ @fk_name + N'] FOREIGN KEY ([' + @constrained_col + N']) REFERENCES [' + @reference_table + N'] ([' + @reference_col + N'])'
		EXEC sp_sqlexec @sql

		FETCH NEXT FROM CC INTO @fk_name, @constrained_table, @constrained_col, @reference_table, @reference_col
	END
	CLOSE CC
	DEALLOCATE CC
GO

EXEC DB_STAT.dbo.db_restore_fk N'BAZA1'

USE BAZA1
SELECT CONVERT(NVARCHAR(15), f.name) AS tablename,
	CONVERT(NVARCHAR(15), OBJECT_NAME(f.parent_object_id)) AS constrained_table,
	CONVERT(NVARCHAR(15), COL_NAME(fc.parent_object_id, fc.parent_column_id)) AS constrained_col, 
	CONVERT(NVARCHAR(15), OBJECT_NAME (f.referenced_object_id)) AS reference_table,
	CONVERT(NVARCHAR(15), COL_NAME(fc.referenced_object_id, fc.referenced_column_id)) AS reference_col
FROM sys.foreign_keys AS f
	JOIN sys.foreign_key_columns AS fc ON f.[object_id] = fc.constraint_object_id
ORDER BY f.name
/*
tablename       constrained_table constrained_col reference_table reference_col
--------------- ----------------- --------------- --------------- ---------------
FK_ETATY_OSOBY  etaty             id_osoby        osoby           id_osoby
FK_MIASTA_WOJ   miasta            kod_woj         woj             kod_woj
FK_OSOBY_MIASTA osoby             id_miasta       miasta          id_miasta

(3 rows affected)

Klucze obce zostały poprawnie odtworzone. */