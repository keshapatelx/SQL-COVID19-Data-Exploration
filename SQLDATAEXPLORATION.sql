SELECT *
FROM CovidDeaths$

SELECT *
FROM CovidVaccinations$

--Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1, 2

--Looking at total_cases VS total_deaths
--Shows Likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths$
where location = 'India'
ORDER BY 1, 2

--Looking at total_cases VS population
--Shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentagePopulationInfected
FROM CovidDeaths$
where location = 'India'
ORDER BY 1, 2


--Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highestInfectioncount, MAX((total_cases/population)*100) as PercentagePopulationInfected
FROM CovidDeaths$
group by location, population
ORDER BY 4 desc

--Showing Countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) AS highestDeathcount
FROM CovidDeaths$
WHERE continent is not null
group by location
ORDER BY 2 desc

--Lets break things down to continent
--Showing continents with the highest death count per popuplation
SELECT continent, MAX(CAST(total_deaths AS int)) AS highestDeathcount
FROM CovidDeaths$
WHERE continent is not null
group by continent
ORDER BY 2 desc

--GLOBAL NUMBERS
SELECT date, SUM(new_cases) as totalCases, sum(CAST(new_deaths as int)) as totalDeaths, sum(CAST(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
FROM CovidDeaths$
where continent is not null
Group by date
ORDER BY 1, 2

--total cases and total deaths across the world altogether withoust group by anything
SELECT SUM(new_cases) as totalCases, sum(CAST(new_deaths as int)) as totalDeaths, sum(CAST(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
FROM CovidDeaths$
where continent is not null
--Group by date
ORDER BY 1, 2


--LOOKING AT TOTAL POPULATION VS VACCINATIONS
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,  
SUM(CAST(CV.new_vaccinations AS INT)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as rollingPeopleVaccinated
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent is not null
ORDER BY 2, 3


--USE CTE
--percentage of vaccinated people 
WITH PopvsVac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
as
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,  
SUM(CAST(CV.new_vaccinations AS INT)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as rollingPeopleVaccinated
--(rollingPeopleVaccinated/population)*100    we cant use the recent produced column so cte or temp table should prefer :)
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent is not null
--ORDER BY 2, 3
)
SELECT *, (rollingPeopleVaccinated/population)*100 as VaccinationPercent
FROM PopvsVac



--temp table
--same output as cte percentage of vaccinated people
--when u going to alter in temp table we are going to use DROP TABLE at the beginning to avoid the error
DROP TABLE IF EXISTS #PercentaPopulationVaccinated
CREATE TABLE #PercentaPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingPeopleVaccinated numeric
)
INSERT INTO #PercentaPopulationVaccinated
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,  
SUM(CAST(CV.new_vaccinations AS INT)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as rollingPeopleVaccinated
--(rollingPeopleVaccinated/population)*100    we cant use the recent produced column so cte or temp table should prefer :)
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location AND CD.date = CV.date
--WHERE CD.continent is not null
--ORDER BY 2, 3

SELECT *, (rollingPeopleVaccinated/population)*100 as VaccinationPercent
FROM #PercentaPopulationVaccinated


--Creating view to store data for later visualizations
CREATE VIEW PercentaPopulationVaccinated AS
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,  
SUM(CAST(CV.new_vaccinations AS INT)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) as rollingPeopleVaccinated
--(rollingPeopleVaccinated/population)*100    we cant use the recent produced column so cte or temp table should prefer :)
FROM CovidDeaths$ CD
JOIN CovidVaccinations$ CV
ON CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent is not null
--ORDER BY 2, 3
SELECT *
FROM PercentaPopulationVaccinated
