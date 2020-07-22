-- Creating Data Base with my initials 
create database pvajja;

-- Connecting to Database
\c pvajja;


-- Question 1
drop view if exists V;
drop table if exists tree;
create table tree(p integer, c integer);
delete from tree;
INSERT INTO Tree VALUES (1,2), (1,3), (1,4), (2,5), (2,6), (3,7), (5,8), (7,9), (9,10);

drop table if exists visited;
create table visited (v int);

create or replace function distance(m int, n int)
returns int as
$$
declare dist int:= 0;
		x int:= m;
		y int:= n;
Begin
insert into visited values(m);
if exists(select * from tree t where t.p = m and t.c = n)
then return (dist+1);
else 
if exists(select * from tree t where t.p = n and t.c = m)
then return (dist+1);
end if;
end if;
if exists(select p from tree where c = m)
then x:= (select p from tree where c = m);
dist:= dist + 1;
end if;
if exists(select p from tree where c = n)
then y := (select p from tree where c= n);
dist:= dist + 1;
end if;
if x = y or y in (select * from visited)
then delete from visited;
return dist;
else dist := dist + (select * from distance(x,y));
end if;
return dist;
end;
$$ language plpgsql;


create or replace view V as 
select distinct(p) as vertex from tree
union 
select distinct(c) as vertex from tree;


SELECT v1.vertex AS v1, v2.vertex as v2, distance(v1.vertex, v2.vertex) as distance
FROM   V v1, V v2 WHERE  v1.vertex != v2.vertex ORDER BY 3,1,2;

drop view if exists V;
drop table if exists tree;
drop table if exists visited;
drop function distance;



-- Question 2
drop view if exists v;
drop table if exists Graph;
CREATE TABLE Graph(source int, target int);
DELETE FROM Graph;

INSERT INTO Graph VALUES 
(      1 ,      2),
(      1 ,      3),
(      1 ,      4),
(      3 ,      4),
(      2 ,      5),
(      3 ,      5),
(      5 ,      4),
(      3 ,      6),
(      4 ,      6);

table graph;

drop view if exists v;
create view v as
select source as vertex from graph
union 
select target as vertex from Graph;

drop table if exists visited;
create table visited(v int);

delete from visited;

create or replace function topsort(vertex int)
returns int[] as
$$
declare r record;
		arr int[];
begin
if exists(select * from Graph g where g.source = vertex)
then 
for r in select g.target from Graph g where g.source = vertex
loop
if r.target not in (select * from visited)
then
insert into visited values(r.target);
arr = array_cat(arr,topsort(r.target));
end if;
end loop;
end if;
arr = array_prepend(vertex, arr);
return arr;
end;
$$ language plpgsql;

create or replace function topologicalsort()
returns table(index int, vertex int) as
$$
declare r record;
		a int[];
		x int[];
		c int:= (select count(*) from v);
Begin
for r in select * from v
loop
if r.vertex not in (select * from visited)
then insert into visited values(r.vertex);
x := (select * from topsort(r.vertex));
a = array_cat(x,a);
end if;
end loop;
delete from visited;
drop table if exists sort;
create table sort(vertex int);
delete from sort;
insert into sort select * from unnest(a);
alter table sort add index serial;
return query (select s.index,s.vertex from sort s);
end;
$$ language plpgsql;

select * from topologicalsort();

drop table if exists graph;
drop table if exists visited;
drop table is exists sort;
drop function topologicalsort;
drop function topsort;




-- Question 3
CREATE TABLE IF NOT EXISTS partSubPart(pid INTEGER, sid INTEGER, quantity INTEGER);
DELETE FROM partSubPart;
INSERT INTO partSubPart VALUES(   1,   2,        4),
(   1,   3,        1),(   3,   4,        1),
(   3,   5,        2),(   3,   6,        3),
(   6,   7,        2),(   6,   8,        3);

table partSubPart;

CREATE TABLE IF NOT EXISTS basicPart(pid INTEGER, weight INTEGER);
DELETE FROM basicPart;
INSERT INTO basicPart VALUES(   2,      5),
(   4,     50),(   5,      3),
(   7,      6),(   8,     10);

table basicPart;

create or replace function AggregatedWeight(p int)
returns int as
$$
declare r record;
agg_sum int:=0;
Begin
if p in(select b.pid from basicPart b)
then return (select b.weight from basicPart b where b.pid = p);
else 
for r in (select ps.sid,ps.quantity from partSubPart ps where ps.pid = p)
loop
if r.sid in (select b.pid from basicPart b)
then
agg_sum := agg_sum + (select b.weight * r.quantity from basicPart b where b.pid = r.sid);
else
agg_sum := agg_sum + (r.quantity * AggregatedWeight(r.sid));
end if;
end loop;
end if;
return agg_sum;
end;
$$ language plpgsql;


select distinct pid, AggregatedWeight(pid) from   
(select pid from partSubPart 
 union 
 select pid from basicPart) q 
 order by 1;
 

Drop table partSubPart;
drop table basicPart;
DROP FUNCTION aggregatedweight(integer);



-- Question 4
drop table if exists document;
create table if not exists document (doc text,  words text[]);
delete from document;

insert into document values 
('d7', '{C,B,A}'),
('d1', '{A,B,C}'),
('d8', '{B,A}'),
('d4', '{B,B,A,D}'),
('d2', '{B,C,D}'),
('d6', '{A,D,G}'),
('d3', '{A,E}'),
('d5', '{E,F}');

table document;
-- find unique words in the document to create a power set
drop table if exists a;
create table if not exists A(x text);
delete from A;
insert into A select distinct unnest(words) word from document;
table A;

drop table if exists dict;
create table dict(a text[]);

delete from dict;
with recursive powerset as (
      select '{}'::text[] as S
      union
      select array(select * from UNNEST(S) union select x order by 1)
      from   powerset S, A x)
insert into dict select * from powerset;


create or replace function frequentSets(t int)
returns table(frequentSets text[]) as
$$
declare r record;
Begin
drop table if exists notfrequent;
drop table if exists frequent;
create table notfrequent(nf text[]);
create table frequent(f text[]);
for r in select * from dict
loop
if exists(select * from notfrequent where r.a <@ nf)
then insert into notfrequent values(r.a);
else
if t <= (select count(*) from document where r.a<@words)
then insert into frequent values(r.a);
else insert into notfrequent values(r.a);
end if;
end if;
end loop;
return query select f from frequent;
end;
$$ language plpgsql;

select * from frequentSets(1);

select * from frequentSets(2);

select * from frequentSets(3);

select * from frequentSets(4);

drop function frequentSets;
drop table notfrequent;
drop table frequent;
drop table 


-- Question 5
CREATE TABLE Points (PId INTEGER, X FLOAT, Y FLOAT);
INSERT INTO Points VALUES(   1 , 0 , 0),(   2 , 2 , 0),
(   3 , 4 , 0),(   4 , 6 , 0),(   5 , 0 , 2),
(   6 , 2 , 2),(   7 , 4 , 2),(   8 , 6 , 2),
(   9 , 0 , 4),(  10 , 2 , 4),(  11 , 4 , 4),
(  12 , 6 , 4),(  13 , 0 , 6),(  14 , 2 , 6),
(  15 , 4 , 6),(  16 , 6 , 6),(  17 , 1 , 1),
(  18 , 5 , 1),(  19 , 1 , 5),(  20 , 5 , 5);

select * from points limit 4;

create or replace function distance(x1 float,y1 float,x2 float,y2 float)
returns float as 
$$
select sqrt(pow((x2-x1),2) + pow((y2-y1),2))
$$ language sql;


drop table if exists kmean_point;
create table kmean_point(x float, y float, cen_x float, cen_y float, dist float);
drop table if exists min_points;
create table min_points(x float, y float, cen_x float, cen_y float);


create or replace function kmeans(k integer)
returns table(cid float, cen_x float, cen_y float) as
$$
declare len int:= (select count(*) from points);
r1 record;
r2 record;
new_x float:= 0;
new_y float:= 0;
begin
drop table if exists kmean;
create table if not exists kmean(cid float, cen_xk float, cen_yk float);
insert into kmean select len+p.pid,p.x,p.y from points p where random() < 0.5 limit k;
for i in 1..500
loop
insert into kmean_point (select p.x,p.y,k.cen_xk,k.cen_yk, distance(p.x,p.y,k.cen_xk,k.cen_yk)
						 from points p cross join kmean k);						 
for r1 in (select p.x,p.y from points p)
loop 
insert into min_points(select k.x,k.y,k.cen_x,k.cen_y from kmean_point k
where k.x = r1.x and k.y = r1.y and k.dist <= all(select k.dist from kmean_point k
where k.x = r1.x and k.y = r1.y));
end loop;
for r2 in (select k.cen_xk,k.cen_yk from kmean k)
loop
new_x := (select sum(m.x)/count(m.x) from min_points m where m.cen_x = r2.cen_xk and m.cen_y = r2.cen_yk);
new_y := (select sum(m.y)/count(m.y) from min_points m where m.cen_x = r2.cen_xk and m.cen_y = r2.cen_yk);
update kmean set cen_xk = new_x, cen_yk = new_y where cen_xk = r2.cen_xk and cen_yk = r2.cen_yk;
end loop;
delete from min_points;
delete from kmean_point;
end loop;
return query select k.cid,k.cen_xk,k.cen_yk from kmean k;
end;
$$ language plpgsql;

select * from kmeans(3);

drop function kmeans;
drop function distance;
drop table  kmean_point;
drop table min_points;

-- Connecting to Default database
\c postgres;

-- Drop table which is created
drop database pvajja;