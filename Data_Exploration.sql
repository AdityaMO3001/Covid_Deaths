/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT * from CovidDeaths.CovidDeaths
ORDER By 3,4;

Select *
from CovidDeaths.CovidDeaths
Where continent is not null 
order by 3,4;


-- Select Data that is to be used for the project

Select Location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths.CovidDeaths
Where continent is not null 
order by 1,2;



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths.coviddeaths
Where location like '%states%'
and continent is not null 
order by 1,2;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths.coviddeaths
Where location like '%states%'
order by 1,2;


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths.coviddeaths
-- Where location like '%India%'
Group by Location, Population
order by PercentPopulationInfected desc;


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as UNSIGNED)) as TotalDeathCount
From CovidDeaths.coviddeaths
-- Where location like '%states%' 
WHERE continent is not null 
Group by Location
order by TotalDeathCount desc;

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select Continent, MAX(cast(Total_deaths as UNSIGNED)) as TotalDeathCount
From CovidDeaths.coviddeaths
-- Where location like '%states%'
Where continent is not null 
Group by Continent
order by TotalDeathCount desc;

-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as UNSIGNED)) as total_deaths, SUM(cast(new_deaths as UNSIGNED))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths.coviddeaths
--  Where location like '%states%'
where continent is not null 
Group By date
order by 1,2;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT 
  deaths.continent, 
  deaths.location, 
  deaths.date, 
  deaths.population, 
  vaccinations.new_vaccinations,
  SUM(CAST(vaccinations.new_vaccinations AS UNSIGNED)) 
    OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths.CovidDeaths deaths
JOIN CovidDeaths.CovidVaccinations vaccinations
  ON deaths.location = vaccinations.location
  AND deaths.date = vaccinations.date
WHERE deaths.continent IS NOT NULL 
ORDER BY deaths.location, deaths.date;



-- Using CTE to perform Calculation on Partition By in previous query

WITH PopulationVsVaccination AS (
  SELECT 
    deaths.continent, 
    deaths.location, 
    deaths.date, 
    deaths.population, 
    vaccinations.new_vaccinations,
    SUM(CAST(vaccinations.new_vaccinations AS UNSIGNED)) 
      OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingPeopleVaccinated
  FROM CovidDeaths.CovidDeaths deaths
  JOIN CovidDeaths.CovidVaccinations vaccinations
    ON deaths.location = vaccinations.location
    AND deaths.date = vaccinations.date
  WHERE deaths.continent IS NOT NULL
)
SELECT *, 
       (RollingPeopleVaccinated / population) * 100 AS VaccinationRate
FROM PopulationVsVaccination
ORDER BY location, date;



-- Using Temp Table to perform Calculation on Partition By in previous query
-- Select the working database
USE CovidDeaths;

-- Now create the permanent table
DROP TABLE IF EXISTS PercentPopulationVaccinated;

CREATE TABLE PercentPopulationVaccinated (
  Continent VARCHAR(255),
  Location VARCHAR(255),
  Date DATETIME,
  Population NUMERIC,
  New_vaccinations NUMERIC,
  RollingPeopleVaccinated NUMERIC
);

INSERT INTO PercentPopulationVaccinated
SELECT 
  deaths.continent, 
  deaths.location, 
  deaths.date, 
  deaths.population, 
  vaccinations.new_vaccinations,
  SUM(CAST(vaccinations.new_vaccinations AS UNSIGNED)) 
    OVER (PARTITION BY deaths.location ORDER BY deaths.date) AS RollingPeopleVaccinated
FROM CovidDeaths.CovidDeaths deaths
JOIN CovidDeaths.CovidVaccinations vaccinations
  ON deaths.location = vaccinations.location
  AND deaths.date = vaccinations.date
WHERE deaths.continent IS NOT NULL;

SELECT *, 
       (RollingPeopleVaccinated / Population) * 100 AS VaccinationRate
FROM PercentPopulationVaccinated
ORDER BY location, date;



SHOW Databases;


-- Creating View to store data for later visualizations

Create View PercentOfPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS UNSIGNED)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From CovidDeaths.CovidDeaths dea
Join CovidDeaths.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
