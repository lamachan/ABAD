/* 1. Proszę zrobić w bazie administracyjnej tabelę do przechowania uruchomień backupu.*/
CREATE TABLE APBD23_ADM.dbo.BK_LOG
(
	id_bk INT NOT NULL IDENTITY CONSTRAINT PK_BK_LOG PRIMARY KEY,
	name_bk NVARCHAR(100) NOT NULL,
	filename_bk NVARCHAR(200) NOT NULL,
	username NVARCHAR(100) NOT NULL DEFAULT USER_NAME(),
	hostname NVARCHAR(100) NOT NULL DEFAULT HOST_NAME(),
	date_bk DATETIME NOT NULL DEFAULT GETDATE()
)
/* Commands completed successfully.*/

/* 2. Napisac 2 procedury:
- bk_db - backup pojedynczej bazy
- bk_all_db - backup wszystkich baz
do pliku na wyznaczonym katalogu.*/
GO
CREATE PROCEDURE bk_db(@dbname NVARCHAR(50), @directory NVARCHAR(200))
AS
	IF NOT EXISTS (SELECT 1 FROM sysdatabases d WHERE d.name = @dbname)
	BEGIN
		DECLARE @error_msg NVARCHAR(100) = N'Baza danych ' + @dbname + ' nie istnieje!'
		RAISERROR(@error_msg, 16, 1)
		RETURN
	END

	IF RIGHT(@directory, 1) != N'\' 
	BEGIN
		SET @directory = @directory + N'\'
	END

	DECLARE @filename NVARCHAR(100)
	SET @filename = REPLACE(REPLACE(CONVERT(NCHAR(19), GETDATE(), 126), N':', N'_'),'-','_')

	DECLARE @filepath NVARCHAR(300)
	SET @filepath = @directory + RTRIM(@dbname) + N'_' + @filename + N'.bak'

	DECLARE @sql NVARCHAR(300)
	SET @sql = 'BACKUP DATABASE ' + @dbname + ' TO DISK = ''' + @filepath + ''''
	EXEC sp_sqlExec @sql

	SET @sql = N'INSERT INTO APBD23_ADM.dbo.BK_LOG (name_bk, filename_bk) VALUES (N''' + @dbname + ''', N''' + @filepath + ''')'
	EXEC sp_sqlExec @sql
GO

EXEC bk_db N'BAZA1', N'D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP'
/*
Processed 384 pages for database 'BAZA1', file 'BAZA1' on file 1.
Processed 2 pages for database 'BAZA1', file 'BAZA1_log' on file 1.
BACKUP DATABASE successfully processed 386 pages in 0.011 seconds (274.147 MB/sec).*/

SELECT CONVERT(NVARCHAR(5), l.id_bk) AS id_bk,
	CONVERT(NVARCHAR(10), l.name_bk) AS name_bk,
	CONVERT(NVARCHAR(90), l.filename_bk) AS filename_bk,
	CONVERT(NVARCHAR(10), l.username) AS username,
	CONVERT(NVARCHAR(10), l.hostname) AS hostname,
	l.date_bk
FROM APBD23_ADM.dbo.BK_LOG l
/*
id_bk name_bk    filename_bk                                                                                username   hostname   date_bk
----- ---------- ------------------------------------------------------------------------------------------ ---------- ---------- -----------------------
1     BAZA1      D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\BAZA1_2023_11_14T14_47_27.bak    dbo        WERA       2023-11-14 14:47:27.853
*/

GO
CREATE PROCEDURE bk_all_db(@directory NVARCHAR(200))
AS
	DECLARE @dbname NVARCHAR(50)

	DECLARE CD INSENSITIVE CURSOR FOR
		SELECT d.[name] FROM sys.databases d
	OPEN CD
	FETCH NEXT FROM CD INTO @dbname
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC bk_db @dbname, @directory
		FETCH NEXT FROM CD INTO @dbname
	END
	CLOSE CD
	DEALLOCATE CD
GO

EXEC bk_all_db N'D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP'

SELECT CONVERT(NVARCHAR(5), l.id_bk) AS id_bk,
	CONVERT(NVARCHAR(15), l.name_bk) AS name_bk,
	CONVERT(NVARCHAR(100), l.filename_bk) AS filename_bk,
	CONVERT(NVARCHAR(10), l.username) AS username,
	CONVERT(NVARCHAR(10), l.hostname) AS hostname,
	l.date_bk
FROM APBD23_ADM.dbo.BK_LOG l
WHERE l.id_bk != 1
/*
id_bk name_bk         filename_bk                                                                                          username   hostname   date_bk
----- --------------- ---------------------------------------------------------------------------------------------------- ---------- ---------- -----------------------
2     master          D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\master_2023_11_14T15_01_16.bak             dbo        WERA       2023-11-14 15:01:16.137
3     tempdb          D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\tempdb_2023_11_14T15_01_16.bak             dbo        WERA       2023-11-14 15:01:16.143
4     model           D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\model_2023_11_14T15_01_16.bak              dbo        WERA       2023-11-14 15:01:16.190
5     msdb            D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\msdb_2023_11_14T15_01_16.bak               dbo        WERA       2023-11-14 15:01:16.300
6     APBD23_ADM      D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\APBD23_ADM_2023_11_14T15_01_16.bak         dbo        WERA       2023-11-14 15:01:16.363
7     APBD23_TEST     D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\APBD23_TEST_2023_11_14T15_01_16.bak        dbo        WERA       2023-11-14 15:01:16.473
8     A               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\A_2023_11_14T15_01_16.bak                  dbo        WERA       2023-11-14 15:01:16.600
9     B               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\B_2023_11_14T15_01_16.bak                  dbo        WERA       2023-11-14 15:01:16.693
10    C               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\C_2023_11_14T15_01_16.bak                  dbo        WERA       2023-11-14 15:01:16.833
11    D               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\D_2023_11_14T15_01_16.bak                  dbo        WERA       2023-11-14 15:01:16.913
12    E               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\E_2023_11_14T15_01_16.bak                  dbo        WERA       2023-11-14 15:01:17.023
13    F               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\F_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.117
14    G               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\G_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.257
15    H               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\H_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.340
16    I               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\I_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.447
17    J               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\J_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.540
18    K               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\K_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.650
19    L               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\L_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.743
20    M               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\M_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.853
21    N               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\N_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:17.950
22    O               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\O_2023_11_14T15_01_17.bak                  dbo        WERA       2023-11-14 15:01:18.103
23    P               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\P_2023_11_14T15_01_18.bak                  dbo        WERA       2023-11-14 15:01:18.183
24    Q               D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\Q_2023_11_14T15_01_18.bak                  dbo        WERA       2023-11-14 15:01:18.310
25    BAZA1           D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\BAZA1_2023_11_14T15_01_18.bak              dbo        WERA       2023-11-14 15:01:18.403
26    BAZA2           D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\BAZA2_2023_11_14T15_01_18.bak              dbo        WERA       2023-11-14 15:01:18.513
27    BAZA3           D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\BAZA3_2023_11_14T15_01_18.bak              dbo        WERA       2023-11-14 15:01:18.607
28    BAZA4           D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\BAZA4_2023_11_14T15_01_18.bak              dbo        WERA       2023-11-14 15:01:18.733
29    BAZA5           D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP\BAZA5_2023_11_14T15_01_18.bak              dbo        WERA       2023-11-14 15:01:18.827

(28 rows affected)
*/

/* 3. Napisać procedurę, która:
	- korzystając z tabel z zadania Z2 i procedur do statystyk, które przechowują liczby rekordów
	- do backupu wybierze bazy gdzie pomiędzy dwoma statystykimi dla tej samej bazy w tej samej tabeli
	nastąpił przyrost powyzej 100 rekordów (lub zadany parametr @liczba)*/
GO
CREATE PROCEDURE bk_db_stats(@number INT = 100, @directory NVARCHAR(200))
AS
	DECLARE @dbname NVARCHAR(50), @tablename NVARCHAR(100),
		@max_id INT, @last_id INT,
		@max_id_n_records INT, @last_id_n_records INT,
		@found BIT = 0

	DECLARE CD INSENSITIVE CURSOR FOR
		SELECT d.dbname
		FROM APBD23_ADM.dbo.DB_CHECK d
		GROUP BY d.dbname
	OPEN CD
	FETCH NEXT FROM CD INTO @dbname
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @max_id = MAX(t.check_id)
		FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
			JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)
		WHERE d.dbname = @dbname

		SELECT @last_id = MAX(t.check_id)
		FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
			JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)
		WHERE d.dbname = @dbname
			AND t.check_id < @max_id

		DECLARE CT INSENSITIVE CURSOR FOR
			SELECT t.table_name
			FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
				JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)
			WHERE d.dbname = @dbname
			GROUP BY t.table_name
		OPEN CT
		FETCH NEXT FROM CT INTO @tablename
		WHILE @@FETCH_STATUS = 0 AND @found = 0 AND @last_id IS NOT NULL
		BEGIN
			SELECT @max_id_n_records = t.n_records
			FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
				JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)
			WHERE d.dbname = @dbname
				AND t.table_name = @tablename
				AND t.check_id = @max_id

			SELECT @last_id_n_records = t.n_records
			FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
				JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)
			WHERE d.dbname = @dbname
				AND t.table_name = @tablename
				AND t.check_id = @last_id

			IF @max_id_n_records - @last_id_n_records >= @number
			BEGIN
				SET @found = 1
			END

			FETCH NEXT FROM CT INTO @tablename
		END
		CLOSE CT
		DEALLOCATE CT

		IF @found = 1
		BEGIN
			EXEC bk_db @dbname, @directory
			SET @found = 0
		END

		FETCH NEXT FROM CD INTO @dbname
	END
	CLOSE CD
	DEALLOCATE CD
GO

/* Dodanie nowego rekordu w tabeli 'woj' w 'BAZA1', aby statystyki się zaktualizowały.*/
INSERT INTO BAZA1.dbo.woj(kod_woj, nazwa) VALUES (N'OPO', N'opolskie')
EXEC db_check_tables N'BAZA1'

SELECT t.check_id,
	CONVERT(NVARCHAR(15), t.table_name) AS table_name,
	t.n_records
FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
	JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)
WHERE d.dbname = N'BAZA1'
	AND t.table_name = N'woj'
/*
check_id    table_name      n_records
----------- --------------- -----------
1           woj             7
25          woj             7
30          woj             8

W tabeli widać różnicę 1 rekordu w tabeli 'woj' pomiędzy zebraniami statystyk,
więc procedura 'bk_db_stats' dla argumentu @number = 1
powinna wywołać backup bazy 'BAZA1'.*/

EXEC bk_db_stats 1, N'D:\DOKUMENTY\STUDIA\SEMESTR 5\ABAD\LABORATORIUM\Z3\BACKUP'
/* 
Processed 384 pages for database 'BAZA1', file 'BAZA1' on file 1.
Processed 2 pages for database 'BAZA1', file 'BAZA1_log' on file 1.
BACKUP DATABASE successfully processed 386 pages in 0.016 seconds (188.476 MB/sec).

Backup został wykonany.*/