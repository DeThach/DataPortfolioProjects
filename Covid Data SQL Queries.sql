--SELECT * 
--FROM PortfolioProjects..CovidDeaths
--ORDER BY 3,4

--SELECT * 
--FROM PortfolioProjects..CovidVaccinations
--ORDER BY 3,4

--Select the data we're using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjects..CovidDeaths
ORDER BY 1, 2

--Looking at Total Cases vs Total Deaths
--Shows the death rate of each country if you get Covid
SELECT location, date, total_cases, total_deaths, ((total_deaths/total_cases) * 100) AS DeathRate
FROM PortfolioProjects..CovidDeaths
WHERE location LIKE '%states%'
ORDER BY total_cases DESC

--Looking at Total Cases vs the Population
--Shows the percentage of the population that got Covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS CovidRateInPopulation
FROM PortfolioProjects..CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY total_cases DESC
--OFFSET 0 ROW
--FETCH NEXT 1 ROW ONLY
--The two lines above will make the query return one row which is the top result

--Analyzing countries with the highest infection rate compared to population
SELECT location, MAX(total_cases) AS HighestInfectionCountPerCountry, population, MAX(((total_cases/population) * 100)) AS PopulationInfectionRate
FROM PortfolioProjects..CovidDeaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY PopulationInfectionRate DESC

--Analyzing countries with the highest death rate compared to population
--the WHERE clause gets rid of the grouping of continents
SELECT location, MAX(cast(total_deaths AS INT)) AS HighestDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY HighestDeathCount DESC

--Analyzing total deaths by continent
SELECT location, MAX(cast(total_deaths AS INT)) AS DeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY DeathCount DESC

--Global numbers for each day
SELECT date, SUM(new_cases) AS DailyCases, SUM(cast(new_deaths AS INT)) AS DailyDeaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathRate
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date 

--If you delete the date column in the SELECT statement and comment out the GROUP BY and ORDER BY statements in the query above, 
--then it will return the SUM of all new_cases and new_deaths
--The result shows there is a global death rate of 2.11%
SELECT SUM(new_cases) AS DailyCases, SUM(cast(new_deaths AS INT)) AS DailyDeaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathRate
FROM PortfolioProjects..CovidDeaths
WHERE continent IS NOT NULL


--Analyzing the global population vs vaccinations
--Line 2 continuously adds daily vaccinations and displays their rolling total

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND vac.new_vaccinations IS NOT NULL
ORDER BY dea.location, dea.date

--Using a CTE so we can use RollingVaccinations
WITH PopVsVacc (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinations) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
	AND vac.new_vaccinations IS NOT NULL
--ORDER BY dea.location, dea.date
)
SELECT *, (RollingVaccinations/Population * 100) AS PopulationVaccinated
FROM PopVsVacc


--Temp Table
--It's good practice to add the line below with the DROP TABLE so you don't have to delete the temp table when you run it multiple times
DROP TABLE IF EXISTS #PercentPopulationVacc 
CREATE TABLE #PercentPopulationVacc 
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population INT,
New_Vaccinations INT,
RollingVaccinations INT
)

INSERT INTO #PercentPopulationVacc
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
--ORDER BY dea.location, dea.date

SELECT *, (RollingVaccinations/Population) * 100 AS PercentVaccinated
FROM #PercentPopulationVacc
--End of Temp Table


--Creating a View to store data and will use later for visualization
CREATE VIEW PercentPopulationVacc AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccinations
FROM PortfolioProjects..CovidDeaths AS dea
JOIN PortfolioProjects..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND vac.new_vaccinations IS NOT NULL
--ORDER BY dea.location, dea.date