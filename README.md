MySQL Data Cleaning & Analysis – Layoffs Dataset

Project Overview 
This project focuses on **cleaning, optimizing, and analyzing** the Layoffs Dataset using MySQL. The main objectives are:  
1. **Data Cleaning**: Removing duplicates, standardizing data, handling missing values, and optimizing columns to improve data accuracy.  
2. **Data Analysis**: Identifying trends in layoffs across industries, companies, and countries to gain meaningful insights.  

By transforming raw data into a structured format, this project allows for better decision-making based on clear, accurate insights.  

---

 **Dataset Used**  
The dataset contains information on company layoffs, including:  
- company → Company name  
- location → Where layoffs occurred  
- industry → Sector of the company  
- total_laid_off → Number of employees affected  
- percentage_laid_off → Percentage of workforce affected  
- date → Date of layoffs  
- stage → Company funding stage  
- country → Country of the company  
- funds_raised_millions → Total funding before layoffs  

---

**Data Cleaning & Optimization Process**  

1. Removing Duplicates 
Duplicate records were identified using the `ROW_NUMBER()` function:  
```sql
WITH duplicate_cte AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
        date, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;
```
To remove duplicates, a new cleaned table was created, ensuring only unique records were stored:  
```sql
CREATE TABLE layoffs_staging2 AS 
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
    date, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging2 WHERE row_num > 1;
```

2. Standardizing Data 
To ensure consistency, trimming spaces, fixing inconsistent names, and formatting dates were applied.  

Trimming extra spaces:  
```sql
UPDATE layoffs_staging2 SET company = TRIM(company);
```

Standardizing industry names:  
```sql
UPDATE layoffs_staging2 SET industry = 'Crypto' WHERE industry LIKE 'Crypto%';
```

Fixing inconsistent country names:  
```sql
UPDATE layoffs_staging2 SET country = 'United States' WHERE country LIKE 'United States%';
```

Converting date format:  
```sql
UPDATE layoffs_staging2 SET date = STR_TO_DATE(date, '%m/%d/%Y');
ALTER TABLE layoffs_staging2 MODIFY COLUMN date DATE;
```

3. Handling Missing Values 

Identifying missing values:  
```sql
SELECT * FROM layoffs_staging2 WHERE total_laid_off IS NULL;
```

Filling missing industry data using related records:  
```sql
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
```

Removing records with too many missing values:  
```sql
DELETE FROM layoffs_staging2 WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
```

4. Removing Unnecessary Columns  
Once duplicates were removed, the row_num column (which was only used for identifying duplicates) was dropped:  
```sql
ALTER TABLE layoffs_staging2 DROP COLUMN row_num;
```

---

Insights Gained from the Cleaned Dataset

1. Yearly Layoffs Trend 
- 2022 had the highest layoffs.  
- 2023 (first 3 months) almost matched 2022’s total layoffs.  
```sql
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 DESC;
```

2. Countries with the Most Layoff 
- United States  
- India  
- Netherlands  
```sql
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;
```

3. Companies with the Highest Funding Before Layoffs  
Netflix, Meta, and Uber had massive funding but still had layoffs.  
```sql
SELECT * FROM layoffs_staging2 ORDER BY funds_raised_millions DESC;
```

4. Industries with the Most Layoffs 
Retail and consumer industries were the most affected.  
```sql
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;
```

5. Monthly Layoff Trends (Rolling Sum Analysis) 
A rolling sum was calculated to track cumulative layoffs:  
```sql
WITH Rolling_Total AS (
    SELECT SUBSTRING(date,1,7) AS month, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(date,1,7) IS NOT NULL
    GROUP BY month
    ORDER BY 1 ASC
)
SELECT month, total_off, SUM(total_off) OVER (ORDER BY month) AS rolling_total
FROM Rolling_Total;
```

---

Technologies & Skills Used
- MySQL  
- Data Cleaning  
- Standardization  
- Handling Missing Data  
- Removing Duplicates  
- MySQL Workbench 
- GitHub  

---

### **How to Use This Project**  
1. Clone the repository:  
   ```bash
   git clone https://github.com/yourusername/layoffs-analysis.git
   ```
2. Open `layoffs_analysis.sql` in MySQL Workbench.  
3. Run queries step by step to explore and analyze the cleaned dataset.  

---

Next Steps (Future Improvements)
- Add visualizations using Power BI / Tableau  
