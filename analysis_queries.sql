CREATE TABLE BurnOutAnalysis (
    respondent_id INT IDENTITY PRIMARY KEY,
    work_arrangement VARCHAR(20),
	industry VARCHAR(100),
    gender VARCHAR(50),
    age_group VARCHAR(100),
    job_role VARCHAR(100),
    salary_range VARCHAR(50),
    weekly_hours VARCHAR(100),
    burnout_level VARCHAR(50),
    work_life_balance_score INT,
    mental_health_issues VARCHAR(500),
	physical_health_issues VARCHAR(500)
); 


insert into BurnOutAnalysis (work_arrangement, industry, gender, age_group, job_role, salary_range, weekly_hours, burnout_level, work_life_balance_score, mental_health_issues, physical_health_issues)
select Work_Arrangement, 
		Industry, 
		Gender,
		CASE 
			WHEN Age between 18 AND 28 then '18-28'
			WHEN Age between 29 AND 44 then '29-44' 
			WHEN Age between 45 AND 60 then '45-60' 
			WHEN Age >= 61 THEN '61+' 
		END,
		Job_Role, 
		Salary_Range, 
		CASE
		  WHEN Hours_Per_Week < 30 THEN '<30'
		  WHEN Hours_Per_Week BETWEEN 30 AND 39 THEN '30–39'
		  WHEN Hours_Per_Week BETWEEN 40 AND 49 THEN '40–49'
		  WHEN Hours_Per_Week >= 50 THEN '50+'
		END,
		Burnout_Level, 
		Work_Life_Balance_Score, 
		Mental_Health_Status, 
		Physical_Health_Issues
from MentalHealthResponses_original

--Remote working arrangement will be used frequently, hence creating a temp table for this

select * from BurnOutAnalysis
--1. How does work arrangement (remote, hybrid, on-site) influence perceived burnout level?
select 
	work_arrangement, 
	burnout_level, 
	count(*) as response_count, 
	CAST(
		ROUND(
		  100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY work_arrangement),
		  2
		) AS DECIMAL(5,2)
  ) AS percent_within_group
from BurnOutAnalysis
group by work_arrangement, burnout_level

--2. Among remote employees, how do salary range and weekly working hours relate to burnout levels?
select count(*) as response_count, salary_range, weekly_hours, burnout_level
from BurnOutAnalysis
where work_arrangement = 'Remote'
group by salary_range, weekly_hours, burnout_level

--3. Which mental health concerns are most strongly associated with high burnout levels?
select count(*) as response_count, p.work_arrangement, p.mental_health_issues 
from (
	select mental_health_issues, work_arrangement
	from BurnOutAnalysis 
	where burnout_level = 'High' and isnull(mental_health_issues,'') != '' and mental_health_issues !='None'
) p
group by mental_health_issues, work_arrangement

--4. Which physical health concerns are most strongly associated with high burnout levels in Remote vs Hybrid and Onsite setting?
select count(*) as response_count, p.work_arrangement, p.physical_issue 
from (
	select trim(value) as physical_issue, work_arrangement
	from BurnOutAnalysis 
	cross apply STRING_SPLIT(physical_health_issues, ';')
	where burnout_level = 'High' and isnull(trim(value),'') != '' and trim(value) !='None'
) p
group by physical_issue, work_arrangement


--5. Does work-life balance plays a role in burn-out levels?
select count(*) as response_count, avg(work_life_balance_score) as avg_wlb, burnout_level
from BurnOutAnalysis
group by burnout_level

--6. What job roles and industries are most at risk of burnout when working remotely?
select 
	job_role,
	industry,
	count(*) as high_burnout
from BurnOutAnalysis
where work_arrangement = 'Remote' and burnout_level = 'High'
group by job_role, industry


