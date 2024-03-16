/* Weronika Zbierowska
nr indeksu: 319130 */

/* proszę stworzyć skrypt w którym
1. Utworzycie Państwo bazę APBD23_ADM jeżeli takowa nie istnieje
2. Utworzycie Państwo tabele w tej bazie CRDB_LOG i CRUSR_LOG
kto_chcial, nazwa_bazy / lub loginu, data wstawienia rekordu, czy_powiodło się, opis błedu
kolumny mogą miec inne nazwy ale aby miały te właśnie informacje */

DECLARE @adm_db NVARCHAR(50), @sql NVARCHAR(50)
SET @adm_db = N'APBD23_ADM'
IF NOT EXISTS (SELECT 1 FROM sysdatabases d WHERE d.name = @adm_db)
BEGIN
	SET @sql = N'CREATE DATABASE ' + @adm_db
	EXEC sp_sqlExec @sql
END
GO
/* Commands completed successfully. */

CREATE TABLE APBD23_ADM.dbo.CRDB_LOG
(
	id INT NOT NULL IDENTITY CONSTRAINT PK_CRDB_LOG PRIMARY KEY,
	dbname NVARCHAR(50) NOT NULL,
	create_date DATETIME NOT NULL DEFAULT GETDATE(),
	err_msg NVARCHAR(200) NULL	-- NULL = powodzenie
)

CREATE TABLE APBD23_ADM.dbo.CRUSR_LOG
(
	id INT NOT NULL IDENTITY CONSTRAINT PK_CRUSR_LOG PRIMARY KEY,
	dbname NVARCHAR(50) NOT NULL,
	username NVARCHAR(50) NOT NULL,
	create_date DATETIME NOT NULL DEFAULT GETDATE(),
	err_msg NVARCHAR(200) NULL	-- NULL = powodzenie
)
/* Commands completed successfully. */

/* stworzyć procedurę jak poniżej 
CREATE procedure tworz_db(@db_name nvarchar(50), @u_name nvarchar(50) )
i za jej pomocą stworzyć 
baze
uzytkownika
przypisac mu bycie wlascicielem bazy
zapisac rekord do LOG-ów (i czy się udało czy nie)
a) sprawdzamy czy baza istnieje i jak TAK to wstawiamy do log opis błedu BAZA JUZ ISTNIEJE
b) sprawdzamy czy user istnieje i jak tak to wstawiamy do log opis błedu
i przetestowac EXEC tworz_db @db_name = N'APBD23_TEST', @usr_name= N'APBD23_TEST'  
i sprawdzić czy uzytkownik i baza powstały oraz jest on właścicielem bazy */

GO
CREATE PROCEDURE tworz_db(@dbname NVARCHAR(50), @username NVARCHAR(50))
AS
	DECLARE @sql NVARCHAR(2000)

	IF NOT EXISTS (SELECT 1 FROM sysdatabases d WHERE d.name = @dbname)
	BEGIN
		/*baza nie istnieje*/
		SET @sql = N'CREATE DATABASE ' + @dbname
		EXEC sp_sqlExec @sql
		SET @sql = N'INSERT INTO APBD23_ADM.dbo.CRDB_LOG (dbname) VALUES (N''' + @dbname + ''')'
		EXEC sp_sqlExec @sql
	END
	ELSE
	BEGIN
		/*baza istnieje*/
		SET @sql = N'INSERT INTO APBD23_ADM.dbo.CRDB_LOG (dbname, err_msg) VALUES (N''' + @dbname + ''', N''baza juz istnieje'')'
		EXEC sp_sqlExec @sql
	END

	/*sprawdź, czy użytkownik już istnieje na serwerze*/
	DECLARE @sql_check AS NVARCHAR(200)
	CREATE TABLE #u_server (user_exists BIT NOT NULL)
	SET @sql_check = 'IF EXISTS (SELECT 1 FROM sys.server_principals u WHERE u.name=''' + @username
		+ ''') INSERT INTO #u_server VALUES(1)'
	EXEC sp_sqlExec @sql_check

	SET @sql = 'USE ' + @dbname
	IF NOT EXISTS (SELECT 1 FROM #u_server)
	BEGIN
		/*użytkownik nie istnieje na serwerze*/
		SET @sql = @sql + N';EXEC sp_addlogin @loginame=''' + @username
			+ ''',@passwd=''' + @username
			+ ''',@defdb=' + @dbname
			+ N';EXEC sp_adduser @loginame=''' + @username + ''''
			+ N';EXEC sp_addrolemember @rolename=''db_owner'''
			+ ',@membername=''' + @username + ''''
		EXEC sp_sqlExec @sql
		SET @sql = N'INSERT INTO APBD23_ADM.dbo.CRUSR_LOG (dbname, username) VALUES (N''' + @dbname
			+ ''', N''' + @username + ''')'
		EXEC sp_sqlExec @sql
	END
	ELSE
	BEGIN
		/*użytkownik istnieje na serwerze*/
		/*sprawdź, czy użytkownik istnieje już w bazie*/
		CREATE TABLE #u_db (user_exists BIT NOT NULL)
		SET @sql_check = 'USE ' + @dbname + ';IF EXISTS (SELECT 1 FROM sysusers u WHERE u.name=''' + @username
			+ ''') INSERT INTO #u_db VALUES(1)'
		EXEC sp_sqlExec @sql_check

		IF NOT EXISTS (SELECT 1 FROM #u_db)
		BEGIN
			/*użytkownik nie istnieje w bazie*/
			SET @sql = @sql + N';EXEC sp_adduser @loginame=''' + @username + ''''
				+ N';EXEC sp_addrolemember @rolename=''db_owner'''
				+ ',@membername=''' + @username + ''''
			EXEC sp_sqlExec @sql
			SET @sql = N'INSERT INTO APBD23_ADM.dbo.CRUSR_LOG (dbname, username, err_msg) VALUES (N''' + @dbname
				+ ''', N''' + @username + ''', N''uzytkownik juz istnieje na serwerze'')'
			EXEC sp_sqlExec @sql
		END
		ELSE
		BEGIN
			/*użytkownik istnieje w bazie*/
			SET @sql = N'INSERT INTO APBD23_ADM.dbo.CRUSR_LOG (dbname, username, err_msg) VALUES (N''' + @dbname
				+ ''', N''' + @username + ''', N''uzytkownik juz istnieje w bazie'')'
			EXEC sp_sqlExec @sql
		END
	END
GO
/* Commands completed successfully. */

EXEC tworz_db N'APBD23_TEST', N'APBD23_TEST_USER'

SELECT CONVERT(NVARCHAR(15), s.name) AS name,
	s.crdate
FROM sysdatabases s
WHERE s.name = 'APBD23_TEST'
/*
name            crdate
--------------- -----------------------
APBD23_TEST     2023-10-16 18:09:54.610

Baza danych została pomyślnie utworzona, bo widnieje w tabeli 'sysdatabases'.*/

USE APBD23_TEST
SELECT CONVERT(NVARCHAR(20), u.name) AS 'username',
	CONVERT(NVARCHAR(10), r.name) AS 'role'
FROM sys.database_role_members AS m
	INNER JOIN sys.database_principals AS r ON m.role_principal_id = r.principal_id
	INNER JOIN sys.database_principals AS u ON m.member_principal_id = u.principal_id
WHERE r.name = 'db_owner' AND u.name = 'APBD23_TEST_USER'
/*
username             role
-------------------- ----------
APBD23_TEST_USER     db_owner

Użytkownik został pomyślnie utworzony w bazie i ma przypisaną rolę 'db_owner',
co widnieje w tabelach 'sys.database_principals' i 'sys.database_role_members'.*/

SELECT l.id,
	CONVERT(NVARCHAR(15), l.dbname) AS dbname,
	l.create_date,
	CONVERT(NVARCHAR(10), l.err_msg) AS err_msg
FROM APBD23_ADM.dbo.CRDB_LOG l
/*
id          dbname          create_date             err_msg
----------- --------------- ----------------------- ----------
1           APBD23_TEST     2023-10-16 18:09:55.640 NULL

Fakt pomyślnego utworzenia bazy widnieje w tabeli 'CRDB_LOG'.*/

SELECT l.id,
	CONVERT(NVARCHAR(15), l.dbname) AS dbname,
	CONVERT(NVARCHAR(20), l.username) AS username,
	l.create_date,
	CONVERT(NVARCHAR(10), l.err_msg) AS err_msg
FROM APBD23_ADM.dbo.CRUSR_LOG l
/*
id          dbname          username             create_date             err_msg
----------- --------------- -------------------- ----------------------- ----------
1           APBD23_TEST     APBD23_TEST_USER     2023-10-16 18:09:55.983 NULL

Fakt pomyślnego utworzenia użytkownika widnieje w tabeli 'CRDBUSR_LOG'.*/

/* stworzyć tabele tymczasową 
CREATE TABLE #u (db_name nvarchar(50) not null, usr_name nvarchar(50) nut null)
i wstawić do niej 20 rekordów (np. za pomochą Excela jak pokazywałem na 1szych zajęciach
czyli generujemy 20 insertów za pomocą Excele
pewne bazy moga sie powtarzac aby udowodniec, ze procedura zapisze ten fakt do LOG-ów */

CREATE TABLE #u
(
	dbname NVARCHAR(50) NOT NULL,
	username NVARCHAR(50) NOT NULL
)

INSERT INTO #u (dbname, username) VALUES (N'A', N'a')
INSERT INTO #u (dbname, username) VALUES (N'B', N'b')
INSERT INTO #u (dbname, username) VALUES (N'C', N'c')
INSERT INTO #u (dbname, username) VALUES (N'D', N'd')
INSERT INTO #u (dbname, username) VALUES (N'E', N'e')
INSERT INTO #u (dbname, username) VALUES (N'F', N'f')
INSERT INTO #u (dbname, username) VALUES (N'G', N'g')
INSERT INTO #u (dbname, username) VALUES (N'H', N'h')
INSERT INTO #u (dbname, username) VALUES (N'I', N'i')
INSERT INTO #u (dbname, username) VALUES (N'J', N'j')
INSERT INTO #u (dbname, username) VALUES (N'K', N'k')
INSERT INTO #u (dbname, username) VALUES (N'L', N'l')
INSERT INTO #u (dbname, username) VALUES (N'M', N'm')
INSERT INTO #u (dbname, username) VALUES (N'N', N'n')
INSERT INTO #u (dbname, username) VALUES (N'O', N'o')
INSERT INTO #u (dbname, username) VALUES (N'P', N'p')
/* baza już istnieje, użytkownik jeszcze nie istnieje, ani na serwerze, ani w bazie */
INSERT INTO #u (dbname, username) VALUES (N'P', N'q')
/* baza już istnieje, użytkownik już istnieje na serwerze, ale nie w bazie */
INSERT INTO #u (dbname, username) VALUES (N'P', N'o')
/* baza już istnieje, użytkownik już istnieje w bazie */
INSERT INTO #u (dbname, username) VALUES (N'P', N'p')
/* baza jeszcze nie istnieje, użytkownik już istnieje na serwerze */
INSERT INTO #u (dbname, username) VALUES (N'Q', N'q')

SELECT CONVERT(NVARCHAR(10), u.dbname) AS dbname,
	CONVERT(NVARCHAR(10), u.username) AS username
FROM #u u
/*
dbname     username
---------- ----------
A          a
B          b
C          c
D          d
E          e
F          f
G          g
H          h
I          i
J          j
K          k
L          l
M          m
N          n
O          o
P          p
P          q
P          o
P          p
Q          q

(20 rows affected)

W tabeli #u istnieje kilka rekordów, które ilustrują różne przypadki powrtórzeń (opisane wyżej).*/

DECLARE @d NVARCHAR(50), @u NVARCHAR(50)
DECLARE CI INSENSITIVE CURSOR FOR SELECT u.dbname, u.username FROM #u u
OPEN CI
FETCH NEXT FROM CI INTO @d, @u
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC tworz_db @d, @u
	FETCH NEXT FROM CI INTO @d, @u
END
CLOSE CI
DEALLOCATE CI

SELECT l.id,
	CONVERT(NVARCHAR(15), l.dbname) AS dbname,
	l.create_date,
	CONVERT(NVARCHAR(20), l.err_msg) AS err_msg
FROM APBD23_ADM.dbo.CRDB_LOG l
/*
id          dbname          create_date             err_msg
----------- --------------- ----------------------- --------------------
1           APBD23_TEST     2023-10-16 18:09:55.640 NULL
2           A               2023-10-16 18:55:44.910 NULL
3           B               2023-10-16 18:55:45.477 NULL
4           C               2023-10-16 18:55:45.947 NULL
5           D               2023-10-16 18:55:46.483 NULL
6           E               2023-10-16 18:55:46.860 NULL
7           F               2023-10-16 18:55:47.220 NULL
8           G               2023-10-16 18:55:47.583 NULL
9           H               2023-10-16 18:55:47.930 NULL
10          I               2023-10-16 18:55:48.310 NULL
11          J               2023-10-16 18:55:48.640 NULL
12          K               2023-10-16 18:55:48.953 NULL
13          L               2023-10-16 18:55:49.303 NULL
14          M               2023-10-16 18:55:49.693 NULL
15          N               2023-10-16 18:55:50.023 NULL
16          O               2023-10-16 18:55:50.417 NULL
17          P               2023-10-16 18:55:50.797 NULL
18          P               2023-10-16 18:55:50.890 baza juz istnieje
19          P               2023-10-16 18:55:50.910 baza juz istnieje
20          P               2023-10-16 18:55:50.983 baza juz istnieje
21          Q               2023-10-16 18:55:51.300 NULL

(21 rows affected)

Rekordy o id=18,19,20 obrazują zapisany komunikat błędu przy próbie utworzenia bazy, która już istnieje.*/

SELECT l.id,
	CONVERT(NVARCHAR(15), l.dbname) AS dbname,
	CONVERT(NVARCHAR(20), l.username) AS username,
	l.create_date,
	CONVERT(NVARCHAR(40), l.err_msg) AS err_msg
FROM APBD23_ADM.dbo.CRUSR_LOG l
/*
id          dbname          username             create_date             err_msg
----------- --------------- -------------------- ----------------------- ----------------------------------------
1           APBD23_TEST     APBD23_TEST_USER     2023-10-16 18:09:55.983 NULL
2           A               a                    2023-10-16 18:55:45.003 NULL
3           B               b                    2023-10-16 18:55:45.570 NULL
4           C               c                    2023-10-16 18:55:46.057 NULL
5           D               d                    2023-10-16 18:55:46.577 NULL
6           E               e                    2023-10-16 18:55:46.953 NULL
7           F               f                    2023-10-16 18:55:47.317 NULL
8           G               g                    2023-10-16 18:55:47.660 NULL
9           H               h                    2023-10-16 18:55:48.023 NULL
10          I               i                    2023-10-16 18:55:48.403 NULL
11          J               j                    2023-10-16 18:55:48.717 NULL
12          K               k                    2023-10-16 18:55:49.050 NULL
13          L               l                    2023-10-16 18:55:49.403 NULL
14          M               m                    2023-10-16 18:55:49.787 NULL
15          N               n                    2023-10-16 18:55:50.120 NULL
16          O               o                    2023-10-16 18:55:50.510 NULL
17          P               p                    2023-10-16 18:55:50.873 NULL
18          P               q                    2023-10-16 18:55:50.903 NULL
19          P               o                    2023-10-16 18:55:50.983 uzytkownik juz istnieje na serwerze
20          P               p                    2023-10-16 18:55:51.047 uzytkownik juz istnieje w bazie
21          Q               q                    2023-10-16 18:55:51.363 uzytkownik juz istnieje na serwerze

(21 rows affected)

Komunikaty błędów poprawnie opisują testowane przypadki.*/

SELECT CONVERT(NVARCHAR(10), s.name) AS name,
	s.crdate
FROM sysdatabases s
WHERE LEN(s.name) = 1
/*
name       crdate
---------- -----------------------
A          2023-10-16 18:55:44.470
B          2023-10-16 18:55:44.993
C          2023-10-16 18:55:45.567
D          2023-10-16 18:55:46.057
E          2023-10-16 18:55:46.590
F          2023-10-16 18:55:46.963
G          2023-10-16 18:55:47.327
H          2023-10-16 18:55:47.667
I          2023-10-16 18:55:48.037
J          2023-10-16 18:55:48.413
K          2023-10-16 18:55:48.720
L          2023-10-16 18:55:49.060
M          2023-10-16 18:55:49.410
N          2023-10-16 18:55:49.780
O          2023-10-16 18:55:50.113
P          2023-10-16 18:55:50.513
Q          2023-10-16 18:55:51.050

(17 rows affected)

Wszystkie bazy zostały pomyślnie utworzone.*/

SELECT CONVERT(NVARCHAR(10), s.name) AS name,
	s.create_date,
	CONVERT(NVARCHAR(25), s.default_database_name) AS default_database_name
FROM sys.server_principals s
WHERE LEN(s.name) = 1

/*
name       create_date             default_database_name
---------- ----------------------- -------------------------
a          2023-10-16 18:55:44.913 A
b          2023-10-16 18:55:45.480 B
c          2023-10-16 18:55:45.970 C
d          2023-10-16 18:55:46.503 D
e          2023-10-16 18:55:46.880 E
f          2023-10-16 18:55:47.243 F
g          2023-10-16 18:55:47.603 G
h          2023-10-16 18:55:47.950 H
i          2023-10-16 18:55:48.330 I
j          2023-10-16 18:55:48.660 J
k          2023-10-16 18:55:48.973 K
l          2023-10-16 18:55:49.323 L
m          2023-10-16 18:55:49.697 M
n          2023-10-16 18:55:50.033 N
o          2023-10-16 18:55:50.430 O
p          2023-10-16 18:55:50.820 P
q          2023-10-16 18:55:50.897 P

(17 rows affected)

Wszystkim użytkownikom utworzono konta na serwerze (bez powrótrzeń nazw).
W kolumnie 'default_database_name' przypisana jest baza, w której użytkownik powstał jako pierwszy.*/

USE P
SELECT CONVERT(NVARCHAR(10), u.name) AS 'username',
	CONVERT(NVARCHAR(10), r.name) AS 'role'
FROM sys.database_role_members AS m
	INNER JOIN sys.database_principals AS r ON m.role_principal_id = r.principal_id
	INNER JOIN sys.database_principals AS u ON m.member_principal_id = u.principal_id
WHERE r.name = 'db_owner'
	AND LEN(u.name) = 1

/*
username   role
---------- ----------
p          db_owner
q          db_owner
o          db_owner

(3 rows affected)

Użytkownicy o roli 'db_owner' w bazie 'P' (w której było najwięcej sytuacji 'skrajnych') pokazują,
że procedura działa poprawnie.*/