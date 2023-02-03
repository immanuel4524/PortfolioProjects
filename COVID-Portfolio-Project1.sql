SELECT *
FROM CovidPortfolioProject..['covid death data$']
WHERE continent IS NOT NULL
ORDER BY 3, 4


--Selecting the data that I will be using
SELECT location, date, total_cases, new_cases, total_deaths, population_density
FROM CovidPortfolioProject..['covid death data$'] 
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Total Cases VS Total Deaths in USA to show reported mortality rate as time passed 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases * 100) AS death_percentage
FROM CovidPortfolioProject..['covid death data$'] 
WHERE location like '%states%'
AND continent IS NOT NULL
ORDER BY death_percentage DESC

-- Looking at countries with the highest infection rate in respect to their population
-- Its clear here the some countries refused to accurately report their cases to the World Health Organization
-- The data also does not take into account reinfected people so the percentages are inflated 
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population * 100)) AS infection_percentage
FROM CovidPortfolioProject..['owid-covid-data$'] 
WHERE continent IS NOT NULL
GROUP BY location, population 
ORDER BY infection_percentage DESC

--Looking at the countries with the highest death count per population
--This query appears to give a much more reasonable and accurate result vs the infection rate query
SELECT location, population, MAX(total_deaths) AS reported_covid_deaths, MAX((total_deaths/population * 100)) AS death_percentage
FROM CovidPortfolioProject..['owid-covid-data$']
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY death_percentage DESC

--Looking at the continent with the highest death count percentage
SELECT continent, MAX(population) AS people, MAX(total_deaths) AS reported_covid_deaths, MAX((total_deaths/population * 100)) AS death_percentage
FROM CovidPortfolioProject..['owid-covid-data$']
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY death_percentage DESC

--Global numbers per dat
SELECT date, SUM(new_cases) AS global_new_cases, SUM(CAST(new_deaths AS int)) AS global_deaths, SUM(CAST(new_deaths AS int))/ SUM(new_cases) * 100 AS global_death_percentage
FROM CovidPortfolioProject..['owid-covid-data$']
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

--Joining the information from my COVID death table with my COVID vaccination table
--Looking at Total Population vs Total Vaccinations world wide by adding up the daily vaccinations by country
SELECT deaths.continent, deaths.location, deaths.date, vaxs.new_vaccinations, SUM(CONVERT(bigint, vaxs.new_vaccinations)) OVER (PARTITION BY deaths.location
ORDER BY deaths.location, deaths.date) AS rolling_vax_count
FROM CovidPortfolioProject..['owid-covid-data$'] deaths
JOIN CovidPortfolioProject..covidvaxs$ vaxs
	ON deaths.location = vaxs.location
	AND deaths.date = vaxs.date 
WHERE deaths.continent IS NOT NULL 
ORDER BY 2, 3

--Creating a CTE
WITH PopVsVax (continent, location, date, population, new_vaccinations, rolling_vax_count)
AS
(SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaxs.new_vaccinations, SUM(CONVERT(bigint, vaxs.new_vaccinations)) OVER (PARTITION BY deaths.location
ORDER BY deaths.location, deaths.date) AS rolling_vax_count
FROM CovidPortfolioProject..['owid-covid-data$'] deaths
JOIN CovidPortfolioProject..covidvaxs$ vaxs
	ON deaths.location = vaxs.location
	AND deaths.date = vaxs.date 
WHERE deaths.continent IS NOT NULL )
--ORDER BY 2, 3

--Getting Vaccination percentage
Select *, (rolling_vax_count/population) * 100 AS percentage_vaccinated
FROM PopVsVax

--TEMP Table
DROP TABLE IF EXISTS #PERCENTPOPULATIONVACCINATED
CREATE TABLE #PERCENTPOPULATIONVACCINATED
( continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vax_count numeric) 

INSERT INTO #PERCENTPOPULATIONVACCINATED
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaxs.new_vaccinations, SUM(CONVERT(bigint, vaxs.new_vaccinations)) OVER (PARTITION BY deaths.location
ORDER BY deaths.location, deaths.date) AS rolling_vax_count
FROM CovidPortfolioProject..['owid-covid-data$'] deaths
JOIN CovidPortfolioProject..covidvaxs$ vaxs
	ON deaths.location = vaxs.location
	AND deaths.date = vaxs.date 
WHERE deaths.continent IS NOT NULL 
--ORDER BY 2, 3

--Getting Vaccination percentage
Select *, (rolling_vax_count/population) * 100 AS percentage_vaccinated
FROM #PERCENTPOPULATIONVACCINATED


--CREATING VIEW TO STORE DATA FOR LATE VISUALIZATIONS
CREATE VIEW population_percent_vaxxed as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaxs.new_vaccinations, SUM(CONVERT(bigint, vaxs.new_vaccinations)) OVER (PARTITION BY deaths.location
ORDER BY deaths.location, deaths.date) AS rolling_vax_count
FROM CovidPortfolioProject..['owid-covid-data$'] deaths
JOIN CovidPortfolioProject..covidvaxs$ vaxs
	ON deaths.location = vaxs.location
	AND deaths.date = vaxs.date 
WHERE deaths.continent IS NOT NULL 
--ORDER BY 2, 3