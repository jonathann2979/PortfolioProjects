SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

-- Looking at the Total Cases to Total Deaths ratio
-- Illustrates the likelihood of dying if you contracted COVID in United States
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states'
ORDER BY 1,2;

-- Looking at the Total Cases to Population
-- Shows what percentage of the population got COVID within United States
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;

-- Looking at countries with Highest Infection Rate compared to Population
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY InfectedPercentage DESC;

-- Showing the countries with Highest Death Count per Population
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Grouping the Death Count by Continent
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Showing Continents with the highest death count per population
SELECT Continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC;

-- Global Deaths to New Cases per day
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Date
ORDER BY 1;

-- Total Deaths to Total Cases 
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL;

--Looking at Total Population vs Vaccinations
WITH PopvsVac (Continent, Location, Date, Population, VaccinationsPerDay, Total_Vaccinations)
AS
(
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations AS VaccinationsPerDay, SUM(cast (V.new_vaccinations AS bigint)) OVER (PARTITION BY D.location 
ORDER BY D.location, D.date) AS Total_Vaccinations
FROM PortfolioProject..CovidDeaths AS D
JOIN PortfolioProject..CovidVaccinations AS V
	ON D.location = V.location
	AND D.date = V.date 
WHERE D.Continent IS NOT NULL
)
SELECT *, (Total_Vaccinations/population)*100 AS VaccinatedPercentage
FROM PopvsVac;


--Creating a View Table to use for later
CREATE VIEW PercentPopulationVaccinated AS
WITH PopvsVac (Continent, Location, Date, Population, VaccinationsPerDay, Total_Vaccinations)
AS
(
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations AS VaccinationsPerDay, SUM(cast (V.new_vaccinations AS bigint)) OVER (PARTITION BY D.location 
ORDER BY D.location, D.date) AS Total_Vaccinations
FROM PortfolioProject..CovidDeaths AS D
JOIN PortfolioProject..CovidVaccinations AS V
	ON D.location = V.location
	AND D.date = V.date 
WHERE D.Continent IS NOT NULL
)
SELECT *, (Total_Vaccinations/population)*100 AS VaccinatedPercentage
FROM PopvsVac;



--Queries used to create the Tableau Dashboard
SELECT *
FROM PercentPopulationVaccinated;

CREATE VIEW DeathPercentage AS
SELECT SUM(new_cases) AS total_cases,SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NOT NULL;

CREATE VIEW TotalDeathCount AS
SELECT Location, SUM(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent IS NULL
	AND Location NOT IN ('World', 'European Union', 'International')
GROUP BY Location;


CREATE VIEW InfectedPercentage AS
SELECT Location, population, SUM(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY InfectedPercentage DESC;

SELECT Location, population, date, SUM(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY Location, population, date
ORDER BY InfectedPercentage DESC;



