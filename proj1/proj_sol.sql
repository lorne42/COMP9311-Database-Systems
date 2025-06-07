-- Q1
create or replace view q1(subject_code) as
SELECT code AS subject_code
FROM Subjects
WHERE code LIKE 'HIST3%';

-- Q2 
create or replace view q2(course_id) as
select c.id from courses c, course_enrolments ce, students s
where c.id = ce.course 
and ce.student = s.id and s.stype = 'local'
group by c.id 
having  count(ce.student) >  400;


-- Q3
create or replace view q3_1(course, class, room_id, building) as
select c.id, cl.id, r.id, r.building from classes cl, courses c, rooms r, class_types ct
where cl.course = c.id and cl.room = r.id 
and cl.ctype = ct.id
and ct.name = 'Lecture';


create or replace view q3(course_id) as 
select distinct course from q3_1  
group by course 
having count(distinct class) = count(distinct building) and count(class) = 4;


-- Q4 
create or replace view q4_sem(semester_id) as 
select id from semesters 
where year = 2011 and term = 'X1';

create or replace view q4_1(student) as
select ce.student from course_enrolments ce, courses c, q4_sem
where ce.course = c.id 
and c.semester = q4_sem.semester_id
and ce.grade = 'FL'; 

create or replace view q4_2(student) as
select ce.student from course_enrolments ce, courses c, q4_sem
where ce.course = c.id and c.semester != q4_sem.semester_id
and ce.grade= 'FL';

create or replace view q4(unsw_id) as 
select p.unswid from q4_1 a, people p
where a.student = p.id and a.student not in (
    select * from q4_2
);

-- Q5 
create or replace view q5_1(orgunit, course, num_fails) as
select o.id, ce.course, count(distinct ce.student) from courses c, subjects s, semesters ss, course_enrolments ce, orgunits o, orgunit_types ot 
where c.subject =  s.id and c.semester = ss.id and ce.course = c.id
and s.offeredby = o.id  and o.utype = ot.id 
and ot.name = 'Faculty'
and ss.year = 2010
and ce.grade =  'FL'
group by o.id, ce.course;

create or replace view q5_2(orgunit, max_num_fails) as
select orgunit, max(num_fails) from q5_1 
group by orgunit;

create or replace view q5(course_code) as
select s.code from q5_1 a, q5_2 b, courses c, subjects s
where a.orgunit = b.orgunit and a.num_fails = b.max_num_fails
and a.course = c.id and c.subject = s.id;


-- Q6
create or replace view q6_1(course, avg_mark) as
select c.id, avg(ce.mark)::numeric from courses c, subjects s, course_enrolments ce
where c.subject = s.id  and ce.course = c.id 
and ce.mark is not null
group by c.id;


create or replace view q6_2(staff, subject_id, subject_code, course, avg_mark) as
select cs.staff, s.id,s.code,q6_1.course, q6_1.avg_mark from q6_1, course_staff cs, staff_roles sr, courses c, subjects s 
where q6_1.course = cs.course and cs.role = sr.id
and c.id = q6_1.course and c.subject = s.id
and sr.name = 'Course Lecturer';


create or replace view q6_3(subject_id, max_mark) as
select subject_id, max(avg_mark) from q6_2 
where subject_code ilike '%comp%'
group by subject_id;

create or replace view q6(course_code, lecturer_name) as 
select a.subject_code, p.name from q6_2 a, q6_3 b, people p
where a.subject_id =  b.subject_id and a.avg_mark = b.max_mark 
and a.staff = p.id ;


-- Q7 
create or replace view q7_1(student, semester, num_course) as
select ce.student,c.semester,count(ce.course) from course_enrolments ce, courses c
where ce.course  = c.id
group by ce.student, c.semester;

create or replace view q7_2(orgunit_id, orgunit_name, semester, num_students) as
select o.id, o.longname, pe.semester, count(q7_1.student) from program_enrolments pe, programs p, q7_1, orgunits o
where q7_1.student = pe.student and pe.program = p.id and p.offeredby = o.id 
and q7_1.num_course >= 4 and pe.semester = q7_1.semester
group by o.id, o.name, pe.semester;

create or replace view q7 (semester_id) as
select a.semester from q7_2 a, q7_2 b 
where a.orgunit_name = 'Faculty of Engineering' and  b.orgunit_name = 'School of Mechanical and Manufacturing Engineering'
and a.semester = b.semester  
and a.num_students > b.num_students;


-- Q8
create or replace view q8_1(student,  program, stream, semester) as 
select pe.student, pe.program,se.stream, pe.semester from program_enrolments pe, programs p, stream_enrolments se,streams s
where se.partof = pe.id
and pe.program = p.id  
and se.stream = s.id;


create or replace view q8_2(student,program, avg_mark) as 
select ce.student, pe.program, avg(ce.mark) from course_enrolments ce, program_enrolments pe, courses c
where ce.course = c.id and c.semester = pe.semester
and ce.student = pe.student and ce.mark is not null
group by ce.student, pe.program;


create or replace view q8(unsw_id) as 
select distinct p.unswid from q8_1 a, q8_1 b, program_degrees pd1, program_degrees pd2, q8_2 m1, q8_2 m2, people p 
where a.student = b.student  and a.program != b.program and a.stream = b.stream
and pd1.program = a.program and pd2.program = b.program 
and pd1.name ilike '%bachelor%' and pd2.name ilike '%master%'
and m1.student = a.student  and m2.student  = b.student
and m1.program = a.program and m2.program = b.program 
and p.id = a.student
and m1.avg_mark < m2.avg_mark;



-- q9 
create or replace view q9_1(class_id, room_id, semester_year, description) as
select cl.id, r.id, ss.year,f.description from classes cl, courses c, rooms r, class_types ct, room_facilities rf, facilities f, subjects s, semesters ss
where c.subject = s.id 
and cl.course = c.id
and r.id = cl.room 
and ct.id = cl.ctype 
and rf.room = r.id 
and f.id = rf.facility 
and c.semester = ss.id
and ct.unswid = 'LAB' 
and s.code ilike '%GEOS%'
;

create or replace view q9_2(class_id, room_id) as
select cl.id, cl.room from subjects s, courses c, classes cl, class_types ct, semesters ss
where c.subject = s.id 
and cl.course = c.id 
and cl.ctype = ct.id 
and s.code ilike 'GEOS%'
and ct.unswid = 'LAB'
and c.semester = ss.id
and ss.year = 2007;


create or replace view q9(lab_id, room_id) as
select * from q9_2 a 
where a.room_id not in (
    (select q9_1.room_id from q9_1 where description ilike '%Slide projector%')
    UNION
    (select b.room_id from q9_1 b where description ilike '%Laptop connection facilities%')
) ;


-- Q10 
create or replace view q10_1(course,staff) as
select distinct c.id,cs.staff from courses c, course_staff cs, staff_roles sr, affiliations a, staff_roles sr2, orgunits o  
where cs.course = c.id and cs.staff = a.staff and a.role = sr.id
and cs.role = sr2.id
and sr2.name ilike '%Course Convenor%'
and a.orgunit = o.id 
and sr.name ilike 'Research Fellow'
and o.longname = 'School of Chemical Engineering';


create or replace view q10_2(course, num_stud) as 
select ce.course, count(ce.mark) from course_enrolments ce, q10_1 q 
where ce.course = q.course 
and ce.mark is not null
group by ce.course; 

create or replace view q10_3(course, num_hd) as 
select ce.course, count(ce.mark) from course_enrolments ce, q10_1 q 
where ce.course = q.course 
and ce.mark >= 85
group by ce.course; 

create or replace view q10(course_id, hd_rate) as
select distinct a.course, round(b.num_hd::numeric/a.num_stud::numeric,4) from q10_2 a, q10_3 b, q10_1 c  
where a.course = b.course and a.course = c.course ;



-- q11 
create or replace view q11_1(student, program) as
select distinct pe.student, pe.program from program_enrolments pe, programs p, orgunits o
where pe.program = p.id 
and p.offeredby = o.id 
and o.longname = 'School of Computer Science and Engineering';

create or replace view q11_2(student, program, uoc) as 
select ce.student, q.program, sum(s.uoc) from course_enrolments ce,  courses c, subjects s, q11_1 q, program_enrolments pe
where ce.course = c.id and c.subject = s.id 
and ce.student = q.student 
and pe.student = ce.student
and pe.program = q.program and c.semester = pe.semester
and s.code not ilike '%comp4%' and s.code not ilike '%comp6%'
and s.code not ilike '%comp8%' and s.code not ilike '%comp9%'
and s.code ilike '%comp%'
and ce.mark >= 50
group by ce.student, q.program
having sum(s.uoc) > 60;

create or replace view q11_4(student, program, course, mark, uoc) as
select distinct pe.student, pe.program, ce.course, ce.mark,s.uoc from program_enrolments pe, stream_enrolments se, course_enrolments ce, courses c, subjects s, programs p, q11_1 q
where se.partof = pe.id and ce.student = pe.student and c.semester = pe.semester
and pe.program = p.id
and pe.program = q.program
and q.student = pe.student 
and c.subject = s.id and ce.course = c.id 
and (s.code ilike '%comp4%' or s.code ilike '%comp6%' or 
    s.code ilike '%comp8%' or s.code ilike '%comp9%')
and ce.mark >= 50;

create or replace view q11_5(student, program, avg_mark, uoc) as 
select student,  program, avg(mark), sum(uoc) from q11_4
group by student, program 
having sum(uoc) > 24 and avg(mark)  > 80;


create or replace view q11(unsw_id) as
select p.unswid from (
    select a.student, rank() over (
        order by b.avg_mark desc
    ) from q11_2 a, q11_5 b
    where a.student = b.student 
    and a.program= b.program 
) a, people p 
where p.id = a.student 
and rank <= 10;

-- q12
create or replace function Q12(course_id Integer, i Integer) 
returns setof text as $$
declare student_id Integer;
begin
	for student_id in (
		select ranks.student from (
			select ce.student, rank() over (order by ce.mark desc) as rk
			from Course_enrolments ce
			where ce.course=$1 and mark is not null
		) as ranks
		where ranks.rk=$2
	) 
	loop return next student_id;
	end loop;
	return;
end;
$$ LANGUAGE plpgsql;
