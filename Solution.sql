 --\i 'D:/IUB/Advanced Database Concepts/Assignment/Assignment-8/ArpitShah_assignment8.sql'

Create database arpitshah_assignment8;

\c arpitshah_assignment8;

create or replace function setunion(A anyarray, B anyarray)
returns anyarray as
$$
	select ARRAY(select UNNEST(A)
				union
				select UNNEST(B))
$$ language sql;

--select UNNEST(setunion(ARRAY[1,2,3,4,5],ARRAY[4,5,6,7,8])),UNNEST(setunion(ARRAY[1,2,3,4,5],ARRAY[4,5,6,7,8]))
--select cardinality((setunion(ARRAY[1,2,3,4,5],ARRAY[4,5,6,7,8])))

create or replace function setintersection(A anyarray, B anyarray)
returns anyarray as
$$
	select ARRAY(select UNNEST(A)
				intersect
				select UNNEST(B))
$$ language sql;

--select setintersection(ARRAY[1,2,3,4,5],ARRAY[4,5,6,7,8])

create or replace function setdifference(A anyarray, B anyarray)
returns anyarray as
$$
	select ARRAY(select UNNEST(A)
				except
				select UNNEST(B))
$$ language sql;

--select setdifference(ARRAY[1,2,3,4,5],ARRAY[4,5,6,7,8])

\echo '----------------Question 1----------------'
create table A(x int);
delete from A;
insert into A values(1),(2),(3),(4);
--https://www.postgresql.org/message-id/20060924054759.GA71934%40winnie.fuhr.org
CREATE FUNCTION powerset(a anyarray) RETURNS SETOF anyarray AS $$
DECLARE
    retval  a%TYPE;
    alower  integer := array_lower(a, 1);
    aupper  integer := array_upper(a, 1);
    j       integer;
    k       integer;
BEGIN
    FOR i IN 0 .. (1 << (aupper - alower + 1)) - 1 LOOP
        retval := '{}';
        j := alower;
        k := i;
        WHILE k > 0 LOOP
            IF k & 1 = 1 THEN
                retval := array_append(retval, a[j]);
            END IF;
            j := j + 1;
            k := k >> 1;
        END LOOP;
        RETURN NEXT retval;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;

create or replace view powerSet as (select powerset((select array_agg(x) from A)));
--select * from powerSet;

--drop function if exists superSetsOfSet;
create or replace function superSetsOfSet(X int[])
returns table(y int[]) as
$$
	select powerset
	from powerSet
	where cardinality(setdifference(X,powerset)) = 0
$$ language sql;

select * from A;
select superSetsOfSet('{}');
select superSetsOfSet('{1}');
select superSetsOfSet('{1,3}');
select superSetsOfSet('{1,2,3}');
select superSetsOfSet('{1,2,3,4}');

\echo '----------------Question 2----------------'
--drop table if exists graph cascade;
--drop table if exists graph_weights cascade;

create table graph(source int, target int);
create table graph_weights(s int , t int , w int);

insert into graph values(1,2),(2,3),(3,4),(4,5);
--insert into graph values(1,2),(2,1);
--insert into graph values(1,2),(2,3),(3,1);
--insert into graph values(1,2),(2,3),(3,1),(0,1),(3,4),(4,5),(5,6);

--insert into graph_weights(select e.source,e.target,1 from graph e);
--select * from graph;
--select * from graph_weights;

create or replace function graph()
returns void as
$$
DECLARE i record;
BEGIN
	insert into graph_weights(select e.source,e.target,1 from graph e);
		FOR i in select * from graph_weights
		LOOP
			PERFORM rec_graph(i.s , i.t , i.w);
		END LOOP;
END
$$ language plpgsql;
									
create or replace function rec_graph(s1 int , t1 int , w1 int)
returns void as
$$
DECLARE j record;
		no_of_vertices int;
BEGIN
	select into no_of_vertices cardinality((setunion(array_agg(ew.s),array_agg(ew.t))))
	from graph_weights ew;
	FOR j in select * from graph_weights
	LOOP
		IF j.s = t1 and (w1 + j.w <= 2*no_of_vertices) and (select not exists(select * from graph_weights gw where gw.s = s1 and gw.t=j.t and ((w1 + j.w) = gw.w)))
		THEN insert into graph_weights values (s1 , j.t , w1 + j.w);
			 PERFORM rec_graph(s1 , j.t , w1 + j.w);
		END IF;
	END LOOP;									
END
$$ language plpgsql;

create or replace function connectedByEvenLengthPath()
returns table(s int, t int) as
$$
	select distinct ew.s,ew.t
	from graph_weights ew
	where ew.w%2 = 0
	union	
	select UNNEST(setunion(array_agg(source),array_agg(target))),UNNEST(setunion(array_agg(source),array_agg(target)))
	from graph
	order by s,t
			  
$$ language sql;

create or replace function connectedByOddLengthPath()
returns table(s int, t int) as
$$
	select distinct ew.s,ew.t
	from graph_weights ew
	where ew.w%2 = 1
	order by s,t
		  
$$ language sql;

--select * from graph_weights 																											 
select graph();
select * from graph;
\echo 'Even'
select * from connectedByEvenLengthPath();	
\echo 'Odd'
select * from connectedByOddLengthPath();	

delete from graph;
delete from graph_weights;
 
insert into graph values(1,2),(2,1);
select graph();
select * from graph;
\echo 'Even'
select * from connectedByEvenLengthPath();	
\echo 'Odd'
select * from connectedByOddLengthPath();		

delete from graph;
delete from graph_weights;
 
insert into graph values(1,2),(2,3),(3,1);
select graph();
select * from graph;
\echo 'Even'
select * from connectedByEvenLengthPath();	
\echo 'Odd'
select * from connectedByOddLengthPath();	

delete from graph;
delete from graph_weights;
 
insert into graph values(1,2),(2,3),(3,1),(0,1),(3,4),(4,5),(5,6);
select graph();
select * from graph;
\echo 'Even'
select * from connectedByEvenLengthPath();	
\echo 'Odd'
select * from connectedByOddLengthPath();	


\echo '----------------Question 3----------------'
drop table if exists graph cascade;

create table graph(source int, target int);
insert into graph values(1,2),(1,3),(2,3),(2,4),(3,7),(7,4),(4,5),(4,6),(7,6);

--drop table if exists inCount cascade;
create table inCount(vertice int, count int);

--drop table if exists stack cascade;
create table stack(vertice int);

WITH
	all_vertices AS
	(select UNNEST(setunion(array_agg(source),array_agg(target))) as vertices
	from graph),

	count_target AS
	(SELECT p.target, cardinality(array_agg(p.target)) as groups
	FROM graph p
	GROUP BY (p.target)),

	count_vertices AS
	(SELECT *
	from all_vertices
	except
	select target
	from count_target),

	count_all_vertices AS
	(SELECT *,0 as count
	from count_vertices
	union
	select *
	from count_target)

--We take count of all the edges that are incoming to the vertices.	
insert into inCount(select * from count_all_vertices order by  vertices);

create or replace function topologicalSort()
returns table(v int) as
$$
DECLARE i record;
		c int;
		v int;
BEGIN
	--We take the vertice that has the least number on incoming edges.
	create or replace view vertices_counts as
	(select *
	from incount i1
	where i1.count <= ALL(select i2.count
						 from incount i2));
	--select * from vertices_counts;
	FOR i in select * from incount
	LOOP
		select into c count(*) from vertices_counts;
		--If there is only one edge that has the least number of edges, then we start with that edge.
		IF c = 1
		--We add that vertice to our stack table which holds the vertice in a topologically sorted manner.
			THEN insert into stack select vertice from vertices_counts;
		--We select the edges from the vertice that is added.
		--We first reduce the count of all the edges from that vertice since we delete that vertice from the graph.		
				 select into v vertice from vertices_counts;
				 update incount set count = count - 1 where vertice in (select g.target
																		from graph g
																		where g.source = v);			 
				 delete from incount where vertice = v;
		--If there are more than one vertices for which there are equal number of incoming edges,
		--then we first take that vertice that is a source. Which means that there is an edge going out from that vertice
		--so it needs to occur first in our final list.
			ELSE IF (select count(*) > 0 from vertices_counts where vertice in (select source from graph))
				THEN insert into stack select vertice from vertices_counts where vertice in (select source from graph);
					 delete from incount where vertice = (select vertice from vertices_counts where vertice in (select source from graph));
		--If all the vertices that are left do not have any out going edges then we can directly add them to our final table.
			ELSE
				insert into stack select vertice from vertices_counts;
				delete from incount;
			END IF;
		END IF;
	END LOOP;
	return query	
	select * from stack;	  
END
$$ language plpgsql; 																									 

select * from graph;
select * from topologicalSort();

\echo '----------------Question 4----------------'
drop table if exists graph cascade;

create table graph(source int, target int);
insert into graph values(0,1),(0,2),(1,0),(1,2),(1,3),(2,0),(2,1),(2,3),(3,1),(3,2),(3,4),(4,3);
--insert into graph values(1,2),(1,3),(2,1),(2,4),(3,1),(3,4),(4,2),(4,3);
--insert into graph values(1,2),(1,3),(1,5),(2,1),(2,3),(2,5),(3,1),(3,2),(3,4),(3,5),(4,3),(4,5),(5,1),(5,2),(5,3),(5,4);

--This table is used to maintain the color that is assigned to each vertices.
create table stack_color(x int, c int);
--delete from stack_color;

create table colors(z int);
--delete from colors;

--This table is used to maintain a flag value which
create table color_flags(f bool);
--delete from color_flags;

--Let us assume there are 3 color such as Red,Green and Blue which are represented by 1,2 and 3 respectively
insert into colors values(1),(2),(3);

create or replace function threeColorable()
returns bool as
$$
DECLARE i record;
		flag boolean;
BEGIN
	flag := true;
	--We pass every tuple of the graph table to the function.
	for i in select * from graph
	LOOP
		perform color_fun(i.source,i.target);
	END LOOP;
	--If there is any value that is true then we update the value of flag to false which means that the graph is not threeColorable.
	IF (select exists(select * from color_flags cf where cf.f=true))
		THEN flag := false;
	END IF;
	return flag;
END
$$ language plpgsql;

create or replace function color_fun(s int, t int)
returns void as
$$
DECLARE j record;
		flag boolean;
		assign_color int;
BEGIN
	--Here we check the color of the neighboring vertices.
	--If there is not color left out of 3 colors, then we update the value of flag to true.
	--If we can assign some color to the current vertice then we do not update the value of flag.
	IF (select not exists(select UNNEST(setdifference((select array_agg(z) from colors) ,(select array_agg(sc.c) from stack_color sc where sc.x in (select g.target from graph g where g.source = s)))) order by 1 limit 1))
		THEN flag = (select not exists(select UNNEST(setdifference((select array_agg(z) from colors) ,(select array_agg(sc.c) from stack_color sc where sc.x in (select g.target from graph g where g.source = s)))) order by 1 limit 1));
			 insert into color_flags values(flag);
	END IF;
	--First we check if the vertice is already present in stack_color table or not.
	--If the vertice is not added, then we add that vertice to the table.
	--Before adding the vertice, we check the color of the neighboring vertices.
	--If there is any color that is not assigned to the neighbors, then we assign that color to the vertice that is to be added.
	IF (select not exists(select * from stack_color where x = s))
		THEN	select into assign_color UNNEST(setdifference((select array_agg(z) from colors) ,(select array_agg(sc.c) from stack_color sc where sc.x in (select g.target from graph g where g.source = s)))) order by 1 limit 1;
				insert into stack_color values(s,assign_color);
	END IF;
	--Here we take the source as the target from previous loop and target is such a value that is never visited.
	--We only visit the vertices that are not visited before so that it doesnt go into infinite loop.
	for j in select * from graph g where g.source = t and g.target not in (select sc.x from stack_color sc)
	LOOP
		perform color_fun(j.source,j.target);
	END LOOP;
END

$$ language plpgsql;

select threeColorable();

delete from graph;
delete from stack_color;
delete from color_flags;

insert into graph values(1,2),(1,3),(2,1),(2,4),(3,1),(3,4),(4,2),(4,3);
select threeColorable();


delete from graph;
delete from stack_color;
delete from color_flags;

insert into graph values(1,2),(1,3),(1,5),(2,1),(2,3),(2,5),(3,1),(3,2),(3,4),(3,5),(4,3),(4,5),(5,1),(5,2),(5,3),(5,4);
select threeColorable();


\echo '----------------Question 5----------------'
drop table if exists graph cascade;

create table graph(source int, target int);
insert into graph values(1,2),(1,3),(1,5),(2,1),(2,3),(2,5),(3,1),(3,2),(3,4),(3,5),(4,3),(4,5),(5,1),(5,2),(5,3),(5,4);
--insert into graph values(1,2),(2,3),(2,4),(3,2),(3,4),(4,3),(4,2);
--insert into graph values(1,2),(2,1),(2,3),(2,7),(3,2),(3,4),(3,5),(4,3),(5,3),(5,6),(5,7),(6,5),(7,2),(7,5);
--insert into graph values(1,2),(1,4),(1,7),(2,1),(2,3),(2,4),(3,2),(3,4),(3,5),(4,1),(4,2),(4,3),(5,3),(5,6),(6,5),(6,7),(7,1),(7,6);

--This table is used to keep track of the Hamiltonian cycles that are possible in the given graph.
create table ham_cycle(x int);
--delete from ham_cycle;

--This table is used to check if there is any Hamiltonian cycle possible in the graph or not.
--If there is any cycle that is present in the graph then we insert a value as true in the table.
create table flags(y bool);
--delete from flags;

--drop function Hamiltonian,fun
create or replace function Hamiltonian()
returns bool as
$$
DECLARE i record;
		flag boolean;
BEGIN
	flag := false;
	for i in select * from graph
	LOOP
		perform fun(i.source,i.target);
	END LOOP;
	--If any value in the table is true, ie- if there is any Hamiltonian cycle then our function will return true.
	IF (select exists(select * from flags f where f.y=true))
		THEN flag := true;
	END IF;
	return flag;
END
$$ language plpgsql;

create or replace function fun(s int, t int)
returns void as
$$
DECLARE j record;
		c int;
		no_of_vertices int;
		flag boolean;
BEGIN
	--We only insert the vertice into ham_cycle table if it has never been visited before.
	IF (select not exists(select * from ham_cycle where x = s))
		THEN	insert into ham_cycle values(s);
	END IF;
	--Used to find the number of vertices that have already been visited.
	select into c count(*) from ham_cycle;
	--Used to find the total number of vertices that are present in the graph.
	select into no_of_vertices cardinality((setunion(array_agg(ew.source),array_agg(ew.target))))
	from graph ew;
	
	--This condition means that if all the vertices in a cycle except the last one, has been added to the cycle,
	--then we check if there is a edge present from that last vertice and the first vertice.
	--If there is edge present from last to the first one, it means that there is a Hamiltonian cycle present.
	--If cycle is present then we update the value of flag to true.
	--We check this for other cycles as well.
	--If even a single cycle is present then our final function will return true.
	IF c = (no_of_vertices - 1)
		THEN flag = (select exists(select * from graph g where g.source = t and g.target = (select * from ham_cycle limit 1)));
			 insert into flags values(flag);
	END IF;
	--In this loop, all the vertices 
	for j in select * from graph g where g.source = t and g.target not in (select * from ham_cycle)
	LOOP
		perform fun(j.source,j.target);
	END LOOP;
END

$$ language plpgsql;

select Hamiltonian();

delete from graph;
delete from ham_cycle;
delete from flags;

insert into graph values(1,2),(2,3),(2,4),(3,2),(3,4),(4,3),(4,2);

select Hamiltonian();

delete from graph;
delete from ham_cycle;
delete from flags;

insert into graph values(1,2),(2,1),(2,3),(2,7),(3,2),(3,4),(3,5),(4,3),(5,3),(5,6),(5,7),(6,5),(7,2),(7,5);

select Hamiltonian();

delete from graph;
delete from ham_cycle;
delete from flags;

insert into graph values(1,2),(1,4),(1,7),(2,1),(2,3),(2,4),(3,2),(3,4),(3,5),(4,1),(4,2),(4,3),(5,3),(5,6),(6,5),(6,7),(7,1),(7,6);

select Hamiltonian();

\echo '----------------Question 6----------------'
--drop table if exists documents cascade;

CREATE TABLE documents(doc int primary key, words text[]);
INSERT INTO documents VALUES (1, '{"A","B","C"}'),(2, '{"B","C","D"}'),(3, '{"A","E"}'),(4, '{"B","B","A","D"}'),
					   (5, '{"E","F"}'),(6, '{"A","D","G"}'),(7, '{"C","B","A"}'),(8, '{"B","A"}');

--drop view if exists alphabets;
create or replace view alphabets as
	(select distinct UNNEST(words) as words from documents);
--select * from alphabets;

--drop view if exists alphabets_powerSet;
create or replace view alphabets_powerSet as (select powerset((select array_agg(words)from alphabets)));
--select * from alphabets_powerSet;

--drop table if exists count_sets cascade;
create table count_sets(sets text[], c int);
insert into count_sets(select asp.powerset,(select count(*) from documents d where asp.powerset <@ d.words)
					  from alphabets_powerSet asp);
--select * from count_sets;

--drop function if exists frequentSets;
create or replace function frequentSets(t int)
returns table(w text[]) as
$$
	select cs.sets
	from count_sets cs
	where c >= t	   
$$ language sql;					   

select frequentSets(1);
select frequentSets(2);
select frequentSets(3);
select frequentSets(4);
select frequentSets(5);


\echo '----------------Question 7----------------'
--drop table if exists dataset;
--drop table if exists clusters;
--drop table if exists final_clusters;
--drop table if exists centroids;
--drop function if exists kmeans(int,int);

create table dataset(pid integer primary key, x float, y float);
create table clusters(pid int, x float, y float, cid int, distance float);
create table final_clusters(pid int, x float, y float, cid int, distance float);
create table centroids(pid int, x float , y float);

insert into dataset values(1,1.0,1.0),(2,1.5,2.0),(3,3.0,4.0),(4,5.0,7.0),(5,3.5,5.0),(6,4.5,5.0),(7,3.5,4.5);
create or replace function kmeans(k integer, iterations integer)
returns table(x float, y float) as
$$
DECLARE dist float;
		itr int;
		i RECORD;
		j RECORD;
BEGIN
	insert into centroids (select * from dataset order by random() limit k);
--	select * from centroids
	FOR itr in 1..iterations
	LOOP
	delete from clusters;
		FOR i in select * from centroids
		LOOP
			FOR j in select * from dataset
			LOOP
				dist = sqrt((power(i.x - j.x , 2) + power(i.y - j.y , 2)));
				insert into clusters values	(j.pid , j.x , j.y , i.pid , dist);									 
			END LOOP;
		END LOOP;
		delete from final_clusters;
		insert into final_clusters (select c1.*
								   from clusters c1
								   inner join clusters c2 on c2.pid = c1.pid and c1.distance < c2.distance);
	--	select * from final_clusters

		update centroids set (x , y) = (select avg(fc.x) , avg(fc.y) from final_clusters fc where fc.cid = centroids.pid);
	END LOOP;
	return query
	select c.x,c.y from centroids c;									  
END
$$ language plpgsql;

select kmeans(2 , 50);

\echo '----------------Question 8----------------'
--drop table if exists partSubpart cascade;
--drop table if exists basicPart cascade;

create table partSubpart(pid integer, sid integer, quantity integer, primary key(pid,sid));
create table basicPart(pid integer primary key, weight integer);	

insert into partSubpart values(1,2,4),(1,3,1),(3,4,1),(3,5,2),(3,6,3),(6,7,2),(6,8,3);
insert into basicPart values(2,5),(4,50),(5,3),(7,6),(8,10);

--drop function if exists aggregatedWeight;

create or replace function aggregatedWeight(p integer)
returns integer as
$$
	DECLARE
		i RECORD;
		j RECORD;
		result integer;																		 
	BEGIN
	result :=0;
	IF (select exists (select * from basicPart bp where bp.pid = p))
	THEN result := (select bp.weight from basicPart bp where bp.pid = p);
	return result;
	END IF;
	FOR i in select * from partSubpart where pid = p
		LOOP
			IF (select not exists(select * from basicPart bp where bp.pid = i.sid))
			THEN result := aggregatedWeight(i.sid) * i.quantity + result;
			ELSE result := i.quantity * (select weight from basicPart bp where bp.pid = i.sid) + result;
			END IF;
		END LOOP;
	return result;
	END																													 
$$ language plpgsql;

select aggregatedWeight(1);
select aggregatedWeight(3);
select aggregatedWeight(2);

select q.pid, aggregatedweight(q.pid) 
from (select pid from partsubpart union select pid from basicpart) q
order by 1;																	 

\echo '----------------Question 9----------------'
drop table if exists graph cascade;								  
create table graph(source int, target int, weight int);

insert into graph values(0,1,2),(0,4,10),(1,0,2),(1,3,3),(1,4,7),(2,3,4),(2,4,6),(3,1,3),(3,2,4),(3,4,5),(4,0,10),(4,1,7),(4,2,6),(4,3,5);

drop function if exists graph,rec_graph;

create or replace function graph()
returns void as
$$
DECLARE i record;
BEGIN
		FOR i in select * from graph
		LOOP
			PERFORM rec_graph(i.source , i.target , i.weight);
		END LOOP;
END
$$ language plpgsql;

create or replace function rec_graph(s int , t int , w int)
returns void as
$$
DECLARE j record;
		no_of_vertices int;
BEGIN
	select into no_of_vertices cardinality((setunion(array_agg(ew.source),array_agg(ew.target))))
	from graph ew;
	FOR j in select * from graph
	LOOP
		IF j.source = t and (w + j.weight <= 2*no_of_vertices)  and (select not exists(select * from graph g where g.source = s and g.target =j.target and ((w + j.weight) = g.weight)))
		THEN insert into graph values (s , j.target , w + j.weight);
			 PERFORM rec_graph(s , j.target , w + j.weight);
		END IF;
	END LOOP;									
END
$$ language plpgsql;

select graph();

--drop view if exists final_Dijkstra;

create or replace view final_Dijkstra as
(	select source,target,min(weight) as weight
	from graph 
	group by source,target
 	union
	select UNNEST(setunion(array_agg(source),array_agg(target))) as source,UNNEST(setunion(array_agg(source),array_agg(target))) as target,0 as weight
	from graph
	order by source,target
);

create or replace function Dijkstra(vertice int)
returns table(target int, distance int) as 
$$
	select target,min(weight) as distanceToTarget
	from final_Dijkstra
	where source = vertice
	group by target

$$ language sql;

\echo 'Dijkstra(0)'
select * from Dijkstra(0);
\echo 'Dijkstra(1)'
select * from Dijkstra(1);
\echo 'Dijkstra(2)'
select * from Dijkstra(2);
\echo 'Dijkstra(3)'
select * from Dijkstra(3);
\echo 'Dijkstra(4)'
select * from Dijkstra(4);

\echo '----------------Question 10----------------'
\echo '---------10-a---------'
--drop table if exists R cascade;

create table R(a int, b int);
insert into R values(1,2),(1,3),(2,3),(2,4),(3,7),(7,4),(4,5),(4,6),(7,6);

WITH
--%mapper phase
	map_output AS
	(SELECT a,1 as one
	from R),
--%group phase
	group_output AS
	(SELECT p.a, array_agg(p.one)
	FROM map_output p
	GROUP BY (p.a)),
--%reducer phase
	reduce_output AS
	(SELECT r.a
	FROM group_output r)
--%output
SELECT ro.a
FROM reduce_output ro
order by ro.a;

\echo '---------10-b---------'
drop table if exists R cascade;
--drop table if exists S cascade;

create table R(a int);
create table S(a int);

insert into R values(1),(1),(2),(2),(3),(7),(4),(4),(7),(8),(9);
insert into S values(2),(3),(3),(4),(7),(4),(5),(5),(6),(6),(6);

WITH
--%mapper phase
	map_output AS
	(SELECT a,'r' as group
	from R
	union
	SELECT a,'s' as group
	from S),
--%group phase
	group_output AS
	(SELECT p.a, array_agg(p.group) as groups
	FROM map_output p
	GROUP BY (p.a)),
--%reducer phase
	reduce_output AS
	(SELECT r.a
	FROM group_output r
	where r.groups = '{r}')
--%output
SELECT ro.a
FROM reduce_output ro
order by ro.a;

\echo '---------10-c---------'
drop table if exists R;
drop table if exists S;

create table R(a int, b int);
create table S(b int, c int);

insert into R values(1,2),(2,3),(3,4),(4,5),(5,6);
insert into S values(2,4),(4,6),(6,8),(8,9);

WITH
--%mapper phase
	map_output AS
	(select r.b,array_append(ARRAY[to_char(r.a, '9')], 'r') as groups
	from r
	union
	select s.b,array_append(ARRAY[to_char(s.c, '9')], 's') as groups
	from s),
--%reducer phase
	reduce_output AS
	(SELECT mo1.b, mo1.groups[1] as a, mo2.groups[1] as c
	FROM map_output mo1, map_output mo2
	where mo1.b = mo2.b and '{r}' <@ mo1.groups and '{s}' <@ mo2.groups)
--%output
SELECT *
FROM reduce_output ro
order by ro.b;								  

\c postgres;

drop database arpitshah_assignment8;