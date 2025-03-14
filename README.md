🛠 MySQL Data Cleaning – Layoffs Dataset

📌 Project Overview
This project focuses on cleaning and optimizing the **Layoffs Dataset** using MySQL. The goal is to remove duplicates, standardize data, handle missing values, and remove unnecessary columns to ensure data accuracy and consistency.  

📂 Dataset Used 
The dataset contains information on company layoffs, including fields like **company name, location, industry, total laid-off employees, percentage laid off, date, stage, country, and funds raised.

🔹 Cleaning Process & SQL Queries

1️⃣ Removing Duplicates
Duplicates are removed by using `ROW_NUMBER()` to identify redundant records.  


WITH duplicate_cte AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
        `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


A new cleaned table is created to store unique records.

CREATE TABLE layoffs_staging2 AS 
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 
    `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_staging;

DELETE FROM layoffs_staging2
WHERE row_num > 1;


2️⃣ Standardizing Data
- Trim extra spaces
  
UPDATE layoffs_staging2
SET company = TRIM(company);


- Normalize Industry names (e.g., all variations of "Crypto" are standardized)  

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


- Fix inconsistent country names
  
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';


- Convert Date Format** (from text to proper `DATE` format)  

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


---

3️⃣ Handling Null & Blank Values 
- Identify missing values in `total_laid_off`  

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL;


- Replace empty strings with `NULL` in `industry`  

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';


- Fill missing `industry` values using data from matching companies  

UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2 
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


- Remove records where both `total_laid_off` and `percentage_laid_off` are missing  

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

---

4️⃣ Removing Unnecessary Columns
- The `row_num` column (used for removing duplicates) is no longer needed and is dropped.  

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


---

💡 Key Takeaways
- Created a (cloned table) to safely modify data without affecting raw records.  
- Used `ROW_NUMBER()` to **identify and remove duplicates**.  
- Standardized (company names, industries, country names, and dates) for consistency.  
- Filled in missing values and (removed unnecessary columns) to optimize the dataset.  

---

Technologies Used
- Database: MySQL  
- Techniques: Data Cleaning, Standardization, Handling Missing Data, Duplicates Removal  

