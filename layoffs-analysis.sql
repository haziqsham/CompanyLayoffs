select *
from layoffs;

-- 1. Remove Duplicates
-- 2. Standardize data
-- 3. Null or blank values
-- 4. Remove any comlumns

-- 1. Remove Duplicates

with duplicate_cte as
(
select *, row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, 
'date', stage, country, funds_raised_millions ) as row_num
from layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

select *
from layoffs_staging
where company = 'Casper';



CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select *
from layoffs_staging2
where row_num > 1;

insert into layoffs_staging2
select *, row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, 
'date', stage, country, funds_raised_millions ) as row_num
from layoffs_staging;

delete
from layoffs_staging2
where row_num > 1;

select *
from layoffs_staging2;



-- 2. Standardize data

select company, TRIM(company)
from layoffs_staging2;

update layoffs_staging2
set company = TRIM(company);


select * 
from layoffs_staging2
where industry like 'Crypto%';

update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

select distinct country
from layoffs_staging2
order by 1;

update layoffs_staging2
set country = 'United States'
where country like 'United States%';

SELECT `date`, 
STR_TO_DATE(`date`, '%m/%d/%Y') AS formatted_date
FROM layoffs_staging2;

update layoffs_staging2
set `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

alter table layoffs_staging2
modify column `date` DATE;

-- 3. Null or blank values

select *
from layoffs_staging2
where total_laid_off is null;

select *
from layoffs_staging2
where industry is null or industry = '';

select *
from layoffs_staging2
where company = "Bally's Interactive";

update layoffs_staging2
set industry = null
where industry = '';

select t1.industry, t2.industry
from layoffs_staging2 as t1
join layoffs_staging2 as t2 
	on t1.company = t2.company
	and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
and t2.industry is not null;

update layoffs_staging2 as t1
join layoffs_staging2 as t2 
	on t1.company = t2.company
set t1.industry = t2.industry
where t1.industry is null
and t2.industry is not null;

select *
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null;

delete 
from layoffs_staging2
where total_laid_off is null 
and percentage_laid_off is null;

alter table layoffs_staging2
drop column row_num;

-- Explore Data

select *
from layoffs_staging2;

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

-- Starts from 2020(during Covid 19) ends at 2023.
select min(`date`), max(`date`)
from layoffs_staging2;

-- 2022 is the worst year but 2023 was only 3 months in and almost the same amount in 2022
select YEAR(`date`), sum(total_laid_off)
from layoffs_staging2
group by YEAR(`date`)
order by 1 desc;

-- US, India, Netherlands top 3 most layoffs
select country,sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

-- Netflix, Meta, Uber got funded the most
select *
from layoffs_staging2
where percentage_laid_off
order by funds_raised_millions desc;

-- Consumer, Retail industry laid off most employees
select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

-- Rolling sum(total laid off for each month including the months before)

select substring(`date`,1,7) as month, sum(total_laid_off)
from layoffs_staging2
where substring(`date`,1,7) is not null
group by `month`
order by 1 asc;

with Rolling_Total as
(
select substring(`date`,1,7) as month, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`,1,7) is not null
group by `month`
order by 1 asc
)
select `month`, total_off, 
sum(total_off) over(order by `month`) as rolling_total
from Rolling_Total;

-- Ranks the total laid off per year for each company(top 5)

select company, YEAR(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, YEAR(`date`)
order by 3 desc;

with Company_Year (company, years, total_laid_off)as
(
select company, YEAR(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, YEAR(`date`)
order by 3 desc
), Company_Year_Rank as
(
select *, dense_rank() over(partition by years order by total_laid_off desc) as ranking
from Company_Year
where years is not null
)
select * 
from Company_Year_Rank
where ranking <= 5;
