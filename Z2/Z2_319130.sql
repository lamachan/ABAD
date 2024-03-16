/* Weronika Zbierowska
nr indeksu: 319130 */

/* Proszę stworzyć skrypt w którym:
1. Korzystając ze skryptu z Z1 proszę utworzyć minimum 5 baz. */
EXEC tworz_db N'BAZA1', N'user1'
EXEC tworz_db N'BAZA2', N'user2'
EXEC tworz_db N'BAZA3', N'user3'
EXEC tworz_db N'BAZA4', N'user4'
EXEC tworz_db N'BAZA5', N'user5'

SELECT CONVERT(NVARCHAR(10), l.dbname) AS dbname,
	l.create_date,
	CONVERT(NVARCHAR(10), l.err_msg) AS err_msg
FROM APBD23_ADM.dbo.CRDB_LOG l
WHERE CONVERT(NVARCHAR(10), l.create_date, 112) = '20231024'
/*
dbname     create_date             err_msg
---------- ----------------------- ----------
BAZA1      2023-10-24 10:08:17.027 NULL
BAZA2      2023-10-24 10:08:17.393 NULL
BAZA3      2023-10-24 10:08:17.740 NULL
BAZA4      2023-10-24 10:08:17.990 NULL
BAZA5      2023-10-24 10:08:18.257 NULL

(5 rows affected)

Fakt utworzenia 5 nowych baz został zarejestrowany w tabeli CRDB_LOG. */

/* 2. W 3-ech z nich proszę utworzyć tabele i dane z wykładu z BAZ (WOJ,MIASTA,OSOBY,ETATY)
i wypełnić wartościami. */
GO
CREATE PROCEDURE utworz_dane_BD(@dbname NVARCHAR(50))
AS
	DECLARE @sql AS NVARCHAR(4000)
	SET @sql = 'USE ' + @dbname + ';
		CREATE TABLE dbo.woj
		(
			kod_woj NCHAR(4) NOT NULL CONSTRAINT PK_WOJ PRIMARY KEY,
			nazwa NVARCHAR(50) NOT NULL
		);
		CREATE TABLE dbo.miasta
		(
			id_miasta INT NOT NULL IDENTITY CONSTRAINT PK_MIASTA PRIMARY KEY,
			kod_woj NCHAR(4) NOT NULL CONSTRAINT FK_MIASTA_WOJ FOREIGN KEY REFERENCES woj(kod_woj),
			nazwa NVARCHAR(50) NOT NULL
		);
		CREATE TABLE dbo.osoby
		(
			id_osoby INT NOT NULL IDENTITY CONSTRAINT PK_OSOBY PRIMARY KEY,
			id_miasta INT NOT NULL CONSTRAINT FK_OSOBY_MIASTA FOREIGN KEY REFERENCES miasta(id_miasta),
			imie NVARCHAR(50) NOT NULL,
			nazwisko NVARCHAR(50) NOT NULL
		);
		CREATE TABLE dbo.etaty
		(
			id_osoby INT NOT NULL CONSTRAINT FK_ETATY_OSOBY FOREIGN KEY REFERENCES osoby(id_osoby),
			stanowisko NVARCHAR(50) NOT NULL,
			pensja MONEY NOT NULL,
			od DATETIME NOT NULL,
			do DATETIME NULL,
			id_etatu INT NOT NULL IDENTITY CONSTRAINT PK_ETATY PRIMARY KEY
		);'
	EXEC sp_sqlExec @sql

	SET @sql = 'USE ' + @dbname + ';
		INSERT INTO woj(kod_woj, nazwa) VALUES (N''MAZ'', N''mazowieckie'');
		INSERT INTO woj(kod_woj, nazwa) VALUES (N''MLP'', N''małopolskie'');
		INSERT INTO woj(kod_woj, nazwa) VALUES (N''WLK'', N''wielkopolskie'');
		INSERT INTO woj(kod_woj, nazwa) VALUES (N''POD'', N''podlaskie'');
		INSERT INTO woj(kod_woj, nazwa) VALUES (N''POM'', N''pomorskie'');
		INSERT INTO woj(kod_woj, nazwa) VALUES (N''KUJ'', N''kujawsko-pomorskie'');
		INSERT INTO woj(kod_woj, nazwa) VALUES (N''PKR'', N''podkarpackie'');'
	EXEC sp_sqlExec @sql

	SET @sql = 'USE ' + @dbname + ';
		DECLARE @id_war INT, @id_rad INT, @id_kra INT,
				@id_poz INT, @id_tor INT, @id_byd INT,
				@id_gda INT, @id_kar INT, @id_mal INT;
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''MAZ'', N''Warszawa'');
		SET @id_war = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''MAZ'', N''Radom'');
		SET @id_rad = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''MLP'', N''Kraków'');
		SET @id_kra = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''WLK'', N''Poznań'');
		SET @id_poz = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''KUJ'', N''Toruń'');
		SET @id_tor = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''KUJ'', N''Bydgoszcz'');
		SET @id_byd = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''POM'', N''Gdańsk'');
		SET @id_gda = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''POM'', N''Kartuzy'');
		SET @id_kar = SCOPE_IDENTITY();
		INSERT INTO miasta(kod_woj, nazwa) VALUES (N''POM'', N''Malbork'');
		SET @id_mal = SCOPE_IDENTITY();

		DECLARE @id_kk INT, @id_jk INT, @id_tp INT, @id_dk INT,
			@id_wg INT, @id_br INT, @id_kw INT, @id_lk INT,
			@id_zl INT, @id_sm INT, @id_sf INT, @id_bz INT;
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_war, N''Krzesisława'', N''Kot'');
		SET @id_kk = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_rad, N''Jaromira'', N''Kluska'');
		SET @id_jk = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_poz, N''Tolisława'', N''Pączek'');
		SET @id_tp = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_tor, N''Dobrowieść'', N''Król'');
		SET @id_dk = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_byd, N''Włościsława'', N''Grzybek'');
		SET @id_wg = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_gda, N''Boguwola'', N''Raciczka'');
		SET @id_br = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_kar, N''Kazimira'', N''Wilk'');
		SET @id_kw = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_mal, N''Ludomiła'', N''Kwiat'');
		SET @id_lk = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_war, N''Żytomir'', N''Lampion'');
		SET @id_zl = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_war, N''Sulim'', N''Marko'');
		SET @id_sm = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_poz, N''Świętopełk'', N''Farty'');
		SET @id_sf = SCOPE_IDENTITY();
		INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_gda, N''Bogumił'', N''Złość'');
		SET @id_bz = SCOPE_IDENTITY();

		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_kk, N''stylista fryzur'', 3100, CONVERT(DATETIME, ''19960304'', 112), CONVERT(DATETIME, ''20041231'', 112));
		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_jk, N''ślusarz'', 3000, CONVERT(DATETIME, ''19990627'', 112), NULL);
		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_tp, N''ortodonta'', 15600, CONVERT(DATETIME, ''20160202'', 112), NULL);
		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_dk, N''przewodnik muzealny'', 4160, CONVERT(DATETIME, ''20101125'', 112), NULL);
		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_wg, N''sprzątacz'', 2300, CONVERT(DATETIME, ''19980415'', 112), NULL);
		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_br, N''opiekun delfinów'', 4620, CONVERT(DATETIME, ''20090608'', 112), NULL);
		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_kw, N''nauczyciel języka kaszubkiego'', 5800, CONVERT(DATETIME, ''20171205'', 112), NULL);
		INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
			VALUES (@id_lk, N''sprzedawca'', 2350, CONVERT(DATETIME, ''20200412'', 112), NULL);'
	EXEC sp_sqlExec @sql
GO

EXEC utworz_dane_BD N'BAZA1'
EXEC utworz_dane_BD N'BAZA2'
EXEC utworz_dane_BD N'BAZA3'

USE BAZA1
SELECT TOP 1 * FROM woj
SELECT TOP 1 * FROM miasta
SELECT TOP 1 * FROM osoby
SELECT TOP 1 * FROM etaty
/*
kod_woj nazwa
------- --------------------------------------------------
KUJ     kujawsko-pomorskie

(1 row affected)

id_miasta   kod_woj nazwa
----------- ------- --------------------------------------------------
1           MAZ     Warszawa

(1 row affected)

id_osoby    id_miasta   imie                                               nazwisko
----------- ----------- -------------------------------------------------- --------------------------------------------------
1           1           Krzesislawa                                        Kot

(1 row affected)

id_osoby    stanowisko                                         pensja                od                      do                      id_etatu
----------- -------------------------------------------------- --------------------- ----------------------- ----------------------- -----------
1           stylista fryzur                                    3100,00               1996-03-04 00:00:00.000 2004-12-31 00:00:00.000 1

(1 row affected)

Przykładowe rekordy z tabel utworzonych w bazie 'BAZA1' pokazują, że proces przeszedł pomyślnie.*/

/* 3. Proszę w jednej z baz dodać kilka rekordów więcej do ETATY i OSOBY (według uznania). */
USE BAZA3
DECLARE @id_kar INT
SELECT @id_kar = m.id_miasta FROM miasta m WHERE m.nazwa = 'Kartuzy'

DECLARE @id_mg INT, @id_mp INT, @id_bg INT, @id_gb INT
INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_kar, N'Mszczuj', N'Gruszka')
SET @id_mg = SCOPE_IDENTITY()
INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_kar, N'Mścisław', N'Petronel')
SET @id_mp = SCOPE_IDENTITY()
INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_kar, N'Budzimir', N'Gąska')
SET @id_bg = SCOPE_IDENTITY()
INSERT INTO osoby(id_miasta, imie, nazwisko) VALUES (@id_kar, N'Gniewosz', N'Belka')
SET @id_gb = SCOPE_IDENTITY()

INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
	VALUES (@id_mg, N'menadżer lokalu', 16700, CONVERT(DATETIME, '19860329', 112), NULL)
INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
	VALUES (@id_mp, N'recepcjonista', 4600, CONVERT(DATETIME, '20080618', 112), NULL)
INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
	VALUES (@id_bg, N'administrator baz danych', 21450, CONVERT(DATETIME, '20161230', 112), NULL)
INSERT INTO etaty(id_osoby, stanowisko, pensja, od, do)
	VALUES (@id_bg, N'recepcjonista', 5700, CONVERT(DATETIME, '20070419', 112), CONVERT(DATETIME, '20081026', 112))

SELECT * FROM osoby o WHERE o.id_miasta = @id_kar
SELECT * FROM etaty e WHERE e.id_osoby IN (@id_mg, @id_mp, @id_bg, @id_gb)
/*
id_osoby    id_miasta   imie                                               nazwisko
----------- ----------- -------------------------------------------------- --------------------------------------------------
...
13          8           Mszczuj                                            Gruszka
14          8           Mścisław                                           Petronel
15          8           Budzimir                                           Gąska
16          8           Gniewosz                                           Belka

(5 rows affected)

id_osoby    stanowisko                                         pensja                od                      do                      id_etatu
----------- -------------------------------------------------- --------------------- ----------------------- ----------------------- -----------
13          menadżer lokalu                                    16700,00              1986-03-29 00:00:00.000 NULL                    9
14          recepcjonista                                      4600,00               2008-06-18 00:00:00.000 NULL                    10
15          administrator baz danych                           21450,00              2016-12-30 00:00:00.000 NULL                    11
15          recepcjonista                                      5700,00               2007-04-19 00:00:00.000 2008-10-26 00:00:00.000 12

(4 rows affected)

W bazie 'BAZA3' utworzono po 4 dodatkowe rekordy w tabelach 'osoby' i 'etaty'.*/

/* 4. Zadaniem jest śledzenie liczby rekordów w tabelach w bazach:
4.1 Proszę utworzyć tabele APBD23_ADM.dbo.DB_CHECK i APBD23_ADM.dbo.DB_CHECK_ITEMS */
CREATE TABLE APBD23_ADM.dbo.DB_CHECK
(
	check_id INT NOT NULL IDENTITY CONSTRAINT PK_DB_CHECK PRIMARY KEY,
	dbname NVARCHAR(50) NOT NULL,
	check_time_stamp DATETIME NOT NULL DEFAULT GETDATE(),
	descript NVARCHAR(50) NOT NULL
)
GO

CREATE TABLE APBD23_ADM.dbo.DB_CHECK_ITEMS
(
	check_id INT NOT NULL CONSTRAINT FK_DB_CHECK_DB_CHECK_ITEMS FOREIGN KEY
		REFERENCES APBD23_ADM.dbo.DB_CHECK(check_id),
	table_name NVARCHAR(50) NOT NULL,
	check_time_stamp DATETIME NOT NULL DEFAULT GETDATE(),
	n_records INT NOT NULL
)
GO
/* Commands completed successfully. */

/* 4.2 Trzeba utworzyć procedurę, która dla podanej bazy wylistuje wszystkie tabele
wstawi rekord do tabeli APBD23_ADM.dbo.DB_CHECK i z tak uzyskanym identyfikatorem
wstawi dla kazdej tabeli aktualną liczbę rekordów do tabeli
APBD23_ADM.dbo.DB_CHECK_ITEMS */
GO
CREATE PROCEDURE db_check_tables(@dbname NVARCHAR(50))
AS
	DECLARE @sql NVARCHAR(2000), @i INT, @n_records INT
	
	CREATE TABLE #t (table_name NVARCHAR(100) NOT NULL)
	SET @sql = N'USE ' + @dbname
			+ '; INSERT INTO #t(table_name)'
			+ ' SELECT o.[name] FROM sys.objects o WHERE type = ''U'''
	EXEC sp_sqlExec @sql
	SELECT * FROM #t

	INSERT INTO APBD23_ADM.dbo.DB_CHECK(dbname, descript)
		VALUES (@dbname, N'Procedure db_check_tables')
	SET @i = SCOPE_IDENTITY()

	DECLARE @tablename NVARCHAR(100)

	DECLARE CT INSENSITIVE CURSOR FOR
		SELECT * FROM #t
	OPEN CT
	FETCH NEXT FROM CT INTO @tablename
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = N'USE ' + @dbname
            + '; SELECT @n_records = COUNT(*) FROM ' + @tablename
        EXEC sp_executesql @sql, N'@n_records INT OUTPUT', @n_records OUTPUT

		INSERT INTO APBD23_ADM.dbo.DB_CHECK_ITEMS(check_id, table_name, n_records)
			VALUES (@i, @tablename, @n_records)

		FETCH NEXT FROM CT INTO @tablename
	END
	CLOSE CT
	DEALLOCATE CT
GO

EXEC db_check_tables N'BAZA1'
/*
table_name
--------------------------------------------------
woj
miasta
osoby
etaty

W trakcie wykonywania procedury została wypisana lista tabel w bazie 'BAZA1'.*/

SELECT d.check_id,
	CONVERT(NVARCHAR(10), d.dbname) AS dbname,
	d.check_time_stamp,
	CONVERT(NVARCHAR(30), d.descript) AS descript
FROM APBD23_ADM.dbo.DB_CHECK d
/*
check_id    dbname     check_time_stamp        descript
----------- ---------- ----------------------- ------------------------------
1           BAZA1      2023-11-04 20:35:24.673 Procedure db_check_tables

W tabeli 'DB_CHECK' pojawił się rekord dokumentujący wywołanie procedury 'db_check_tables' na bazie 'BAZA1'.*/

SELECT t.check_id,
	CONVERT(NVARCHAR(10), t.table_name) AS table_name,
	t.check_time_stamp,
	t.n_records
FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
/*
check_id    table_name check_time_stamp        n_records
----------- ---------- ----------------------- -----------
1           woj        2023-11-04 20:35:24.690 7
1           miasta     2023-11-04 20:35:24.690 9
1           osoby      2023-11-04 20:35:24.690 12
1           etaty      2023-11-04 20:35:24.690 8

Do tabeli 'DB_CHECK_ITEMS' zostały wstawione nazwy wszystkich tabel z bazy 'BAZA1' wraz z poprawną liczbą rekordów w nich.
Wartość 'check_id' wskazuje na powiązanie tych rekordów z wywołaniem procedury opisanym w tabeli 'DB_CHECK'.*/

/* 4.3 Napisać procedurę, która dla wszystkich baz wywoła procedurę z punktu 4.2 */
GO
CREATE PROCEDURE all_dbs_check_tables
AS
	DECLARE @dbname NVARCHAR(50)

	DECLARE CD INSENSITIVE CURSOR FOR
		SELECT d.[name] FROM sys.databases d
	OPEN CD
	FETCH NEXT FROM CD INTO @dbname
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC db_check_tables @dbname
		FETCH NEXT FROM CD INTO @dbname
	END
	CLOSE CD
	DEALLOCATE CD
GO

EXEC all_dbs_check_tables

SELECT d.check_id,
	CONVERT(NVARCHAR(15), d.dbname) AS dbname,
	d.check_time_stamp,
	CONVERT(NVARCHAR(30), d.descript) AS descript
FROM APBD23_ADM.dbo.DB_CHECK d
/*
check_id    dbname          check_time_stamp        descript
----------- --------------- ----------------------- ------------------------------
1           BAZA1           2023-11-04 20:35:24.673 Procedure db_check_tables
2           master          2023-11-04 20:35:57.097 Procedure db_check_tables
3           tempdb          2023-11-04 20:35:57.097 Procedure db_check_tables
4           model           2023-11-04 20:35:57.110 Procedure db_check_tables
5           msdb            2023-11-04 20:35:57.133 Procedure db_check_tables
6           APBD23_ADM      2023-11-04 20:35:58.680 Procedure db_check_tables
7           APBD23_TEST     2023-11-04 20:35:58.980 Procedure db_check_tables
8           A               2023-11-04 20:35:59.043 Procedure db_check_tables
9           B               2023-11-04 20:35:59.167 Procedure db_check_tables
10          C               2023-11-04 20:35:59.247 Procedure db_check_tables
11          D               2023-11-04 20:35:59.370 Procedure db_check_tables
12          E               2023-11-04 20:35:59.450 Procedure db_check_tables
13          F               2023-11-04 20:35:59.560 Procedure db_check_tables
14          G               2023-11-04 20:35:59.640 Procedure db_check_tables
15          H               2023-11-04 20:35:59.763 Procedure db_check_tables
16          I               2023-11-04 20:35:59.843 Procedure db_check_tables
17          J               2023-11-04 20:35:59.970 Procedure db_check_tables
18          K               2023-11-04 20:36:00.063 Procedure db_check_tables
19          L               2023-11-04 20:36:00.190 Procedure db_check_tables
20          M               2023-11-04 20:36:00.267 Procedure db_check_tables
21          N               2023-11-04 20:36:00.410 Procedure db_check_tables
22          O               2023-11-04 20:36:00.487 Procedure db_check_tables
23          P               2023-11-04 20:36:00.627 Procedure db_check_tables
24          Q               2023-11-04 20:36:00.707 Procedure db_check_tables
25          BAZA1           2023-11-04 20:36:00.830 Procedure db_check_tables
26          BAZA2           2023-11-04 20:36:00.910 Procedure db_check_tables
27          BAZA3           2023-11-04 20:36:01.037 Procedure db_check_tables
28          BAZA4           2023-11-04 20:36:01.113 Procedure db_check_tables
29          BAZA5           2023-11-04 20:36:01.257 Procedure db_check_tables

(29 rows affected)

Procedura 'db_check_tables' została wywołana dla wszystkich baz na serwerze.*/

SELECT t.check_id,
	CONVERT(NVARCHAR(15), d.dbname) AS dbname,
	CONVERT(NVARCHAR(10), t.table_name) AS table_name,
	t.check_time_stamp,
	t.n_records
FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
	JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)
WHERE d.dbname IN (N'BAZA1', N'BAZA2', N'BAZA3', N'BAZA4', N'BAZA5')
/*
check_id    dbname          table_name check_time_stamp        n_records
----------- --------------- ---------- ----------------------- -----------
1           BAZA1           woj        2023-11-04 20:35:24.690 7
1           BAZA1           miasta     2023-11-04 20:35:24.690 9
1           BAZA1           osoby      2023-11-04 20:35:24.690 12
1           BAZA1           etaty      2023-11-04 20:35:24.690 8
25          BAZA1           woj        2023-11-04 20:36:00.830 7
25          BAZA1           miasta     2023-11-04 20:36:00.840 9
25          BAZA1           osoby      2023-11-04 20:36:00.840 12
25          BAZA1           etaty      2023-11-04 20:36:00.840 8
26          BAZA2           woj        2023-11-04 20:36:00.910 7
26          BAZA2           miasta     2023-11-04 20:36:00.910 9
26          BAZA2           osoby      2023-11-04 20:36:00.910 12
26          BAZA2           etaty      2023-11-04 20:36:00.910 8
27          BAZA3           woj        2023-11-04 20:36:01.040 7
27          BAZA3           miasta     2023-11-04 20:36:01.040 9
27          BAZA3           osoby      2023-11-04 20:36:01.040 16
27          BAZA3           etaty      2023-11-04 20:36:01.040 12

(16 rows affected)

Ograniczyłam się do pokazania tylko rekordów z tabeli 'DB_CHECK_ITEMS' dotyczących baz 'BAZAX'.
Liczby rekordów w poszczególnych tabelach się zgadzają - równe w bazach 'BAZA1' i BAZA2',
w bazie 'BAZA3' o po 4 więcej rekordów w tabelach 'osoby' i 'etaty',
brak zarejestrowanych tabel w bazach 'BAZA4' i 'BAZA5'.*/

/* 4.4 Napisać procedurę, która dla parametru nazwa bazy, 
nazwa tabeli wypisze historię 
liczby rekordów dla podanej tabeli w podanej bazie */
GO
CREATE PROCEDURE table_history(@dbname NVARCHAR(50), @tablename NVARCHAR(50))
AS
	DECLARE @sql NVARCHAR(2000)
	SET @sql = N'SELECT t.check_id,
			CONVERT(NVARCHAR(10), t.table_name) AS table_name,
			t.check_time_stamp,
			t.n_records
		FROM APBD23_ADM.dbo.DB_CHECK_ITEMS t
			JOIN APBD23_ADM.dbo.DB_CHECK d ON (t.check_id = d.check_id)'
		+ ' WHERE d.dbname = N''' + @dbname
			+ ''' AND t.table_name = N''' + @tablename + ''''
	EXEC sp_executesql @sql
GO

EXEC table_history N'BAZA1', N'woj'
/*
check_id    table_name check_time_stamp        n_records
----------- ---------- ----------------------- -----------
1           woj        2023-11-04 20:35:24.690 7
25          woj        2023-11-04 20:36:00.830 7

(2 rows affected)

Zostały wypisane wszystkie rekordy dotyczące tabeli 'woj' w bazie 'BAZA1'.
Liczba rekordów się nie zmieniła, ponieważ tabela nie była jeszcze modyfikowana.*/