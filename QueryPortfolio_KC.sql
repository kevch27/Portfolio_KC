-- SQL Portfolio by Kevin Chen, 2/9/2023
-- Dataset Source: https://ourworldindata.org/covid-deaths
-- Section 1: Data Exploration [Ctrl-G Line 10]
-- Section 2: Generate Views to be used for Tableau Dashboard [Ctrl-G Line 176]
-- Section 3: Data Cleaning [Ctrl-G Line 217]




-- DATA EXPLORATION IN SQL

-- Verify table 'CovidDeaths' is imported correctly
SELECT	*
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is not null
ORDER BY location, date

-- Verify table 'CovidVaccinations' is imported correctly
SELECT	*
FROM	Portfolio_KC..CovidVaccinations
WHERE	continent is not null
ORDER BY location, date

-- Select Data to be used in Tableau Dashboard
SELECT	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is not null
ORDER BY location, date

-- Looking at total cases vs total deaths
-- Looking at mortality rate in United States if infected
SELECT	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is not null 
	AND location = 'United States'
ORDER BY location, date

-- Looking at total cases vs population
-- Looking at infection rate in United States
SELECT	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 AS InfectionPercentage
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is not null
	AND location = 'United States'
ORDER BY location, date

-- Looking at countries with highest infection rate compare to population
SELECT	location,
	population,
	MAX(total_cases) AS HighestInfectionCount,
	MAX((total_cases/population))*100 AS InfectionPercentage
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is not null
GROUP BY location, population
ORDER BY InfectionPercentage desc

-- Looking at countries with the highest death count per population
SELECT	location, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM	Portfolio_KC..CovidDeaths
Where	continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc

-- Looking at continents with the highest death count per population
SELECT	continent, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM	Portfolio_KC..CovidDeaths
Where	continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Looking at global numbers by date
SELECT	date,
	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is not null
GROUP BY date
ORDER BY date, total_cases

-- Looking at Latest global number
SELECT	SUM(new_cases) AS total_cases,
	SUM(CAST(new_deaths AS int)) AS total_deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM Portfolio_KC..CovidDeaths
WHERE continent is not null
ORDER BY total_cases, total_deaths

-- Verify both tables can be joined
SELECT	*
FROM	Portfolio_KC..CovidDeaths dea
JOIN	Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE	dea.continent is not null

-- Looking at total population vs vaccinations
SELECT	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations
FROM	Portfolio_KC..CovidDeaths dea
JOIN	Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE	dea.continent is not null
ORDER BY dea.location, dea.date

-- Find rolling number of vaccination count (without using the column total_vaccinations)
-- METHOD 1: Using CTE

WITH	PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinated)
AS		(
SELECT	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinated
FROM Portfolio_KC..CovidDeaths dea
JOIN Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (rolling_vaccinated/population)*100 AS PercentageVaccinated
FROM PopvsVac

-- Find rolling number of vaccination count (without using the column total_vaccinations)
-- Method 2: Temp Table
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent	nvarchar(255),
Location	nvarchar(255),
Date		datetime,
Population	numeric,
New_vaccinations numeric,
Rolling_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinated
FROM	Portfolio_KC..CovidDeaths dea
JOIN	Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE	dea.continent is not null

SELECT *, (rolling_vaccinated/population)*100 AS PercentageVaccinated
FROM #PercentPopulationVaccinated




-- GENERATE VIEWS TO BE USED FOR TABLEAU DASHBOARD

-- VIEW 1:
CREATE VIEW LatestGlobalNumber AS
SELECT	SUM(new_cases) AS total_cases,
	SUM(cast(new_deaths as int)) AS total_deaths,
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is not null 

-- VIEW 2:
CREATE VIEW TotalDeathCountPerContinent AS
SELECT	location,
	SUM(cast(new_deaths as int)) AS TotalDeathCount
FROM	Portfolio_KC..CovidDeaths
WHERE	continent is null 
	AND location not in ('World', 'European Union', 'International', 'High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP by location

-- VIEW 3:
CREATE VIEW PercentPopulationInfectedPerCountry AS
SELECT	Location,
	Population,
	MAX(total_cases) AS HighestInfectionCount,
	Max((total_cases/population))*100 AS PercentPopulationInfected
FROM	Portfolio_KC..CovidDeaths
Group by Location, Population

-- VIEW 4:
CREATE VIEW PercentPopulationInfected AS
SELECT	Location,
	Population,
	date,
	MAX(total_cases) AS HighestInfectionCount,
	Max((total_cases/population))*100 AS PercentPopulationInfected
FROM	Portfolio_KC..CovidDeaths
Group by Location, Population, date




-- DATA CLEANING IN SQL

-- Action: Remove rows where column 'continent' is NULL
-- Reason: Rows that are NULL in column 'continent' will have non-country data in column 'location'
-- Note: See Line 231-243 for non-country data that might cause discrepancy if left in column 'location'
DELETE FROM	Portfolio_KC..CovidDeaths_Clean
WHERE	continent is null
	AND location = 'Africa'
	AND location = 'Asia'
	AND location = 'Eruope'
	AND location = 'European Union'
	AND location = 'High income'
	AND location = 'International'
	AND location = 'Low income'
	AND location = 'Lower middle income'
	AND location = 'North America'
	AND location = 'Oceania'
	AND location = 'South America'
	AND location = 'Upper middle income'
	AND location = 'World'

-- Action: Replace NULL with 0
-- Reason: Prep for Tableau
-- Note: only for columns that will be used in Tableau Dashboard
SELECT	dea.population,
	dea.total_cases,
	dea.new_cases,
	dea.total_deaths,
	vac.new_vaccinations
FROM	Portfolio_KC..CovidDeaths_Clean dea
JOIN	Portfolio_KC..CovidVaccinations_Clean vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
ORDER BY dea.population

UPDATE	Portfolio_KC..CovidDeaths_Clean
SET	total_cases = 0
WHERE	total_cases IS NULL

UPDATE	Portfolio_KC..CovidDeaths_Clean
SET	new_cases = 0
WHERE	new_cases IS NULL

UPDATE	Portfolio_KC..CovidDeaths_Clean
SET	total_deaths = 0
WHERE	total_deaths IS NULL

UPDATE	Portfolio_KC..CovidVaccinations_Clean
SET	new_vaccinations = 0
WHERE	new_vaccinations IS NULL


-- Verified that date is already standardized
-- Verified that there are no duplicate entries
-- Verified that there are no unused columns
