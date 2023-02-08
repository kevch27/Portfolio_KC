SELECT *
FROM Portfolio_KC..CovidDeaths
Where continent is not null
ORDER BY 3,4


--SELECT *
--FROM Portfolio_KC..CovidVaccinations
--ORDER BY 3,4

--Select Data that we are going to be using
SELECT	location,
		date,
		total_cases,
		new_cases,
		total_deaths,
		population
FROM Portfolio_KC..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT	location,
		date,
		total_cases,
		total_deaths,
		(total_deaths/total_cases)*100 as DeathPercentage
FROM Portfolio_KC..CovidDeaths
WHERE continent is not null AND location = 'United States'

-- Looking at Total Cases vs Population
-- Shows what percentate of population got Covid
SELECT	location,
		date,
		population,
		total_cases,
		(total_cases/population)*100 as InfectionPercentage
FROM Portfolio_KC..CovidDeaths
WHERE continent is not null AND location = 'United States'
ORDER BY 1,2


-- Looking at Countries with highest infection rate compare to population
SELECT	location,
		population,
		MAX(total_cases) as HighestInfectionCount,
		MAX((total_cases/population))*100 as InfectionPercentage
FROM Portfolio_KC..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY InfectionPercentage desc

-- Showing countries with highest death count per population
-- Cast total_deaths as int
SELECT	location, 
		MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM	Portfolio_KC..CovidDeaths
Where	continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- BREAK DOWN BY CONTINENT

-- Showing continents with the highest death count per population
-- note to self: cast changes data type into desired/workable data type
SELECT	continent, 
		MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM	Portfolio_KC..CovidDeaths
Where	continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


-- GLOBAL NUMBERS by Date


SELECT	date,
		SUM(new_cases) as total_cases,
		SUM(CAST(new_deaths as int)) as total_deaths,
		SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Portfolio_KC..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Latest global number
SELECT	SUM(new_cases) as total_cases,
		SUM(CAST(new_deaths as int)) as total_deaths,
		SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Portfolio_KC..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

-- TO SELF: Using CovidVaccinations table

SELECT *
FROM Portfolio_KC..CovidVaccinations

-- Looking at total population vs vaccinations
-- TO SELF: Joining two tables (Step by Step)
SELECT *
FROM Portfolio_KC..CovidDeaths dea
JOIN Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date

SELECT	dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations
FROM Portfolio_KC..CovidDeaths dea
JOIN Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- Find ROLLING NUMBER of vaccination count without using the column total_vaccinations
-- TO SELF: using PARTITION BY
SELECT	dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinated
--		(rolling_vaccinated/population)*100
FROM Portfolio_KC..CovidDeaths dea
JOIN Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- METHOD 1: Using CTE

WITH	PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinated)
AS		(
SELECT	dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinated
--		(rolling_vaccinated/population)*100
FROM Portfolio_KC..CovidDeaths dea
JOIN Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (rolling_vaccinated/population)*100 as PercentageVaccinated
FROM PopvsVac


-- Method 2: Temp Table
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT	dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinated
--		(rolling_vaccinated/population)*100
FROM Portfolio_KC..CovidDeaths dea
JOIN Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3


SELECT *, (rolling_vaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Create a view to store data later for tableau visualization (go back and do more views for above when make sense)

Create View PercentPopulationVaccinated as
SELECT	dea.continent,
		dea.location,
		dea.date,
		dea.population,
		vac.new_vaccinations,
		SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_vaccinated
--		(rolling_vaccinated/population)*100
FROM Portfolio_KC..CovidDeaths dea
JOIN Portfolio_KC..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent is not null