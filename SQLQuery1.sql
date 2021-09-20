SELECT *
FROM portfolio..covid_death
--WHERE location LIKE '%India'
ORDER BY location

SELECT *
FROM portfolio..vaccination
ORDER BY location

-- We are using dataset
SELECT location, date, population, new_cases, new_deaths, total_cases, total_deaths
FROM portfolio..covid_death
ORDER BY location

-- Total cases vs Total Deaths
SELECT location, date, population,total_cases, total_deaths,(total_deaths/total_cases)*100 as Death_percentage
FROM portfolio..covid_death
ORDER BY location 

-- Total Cases in India
SELECT location, date, population,total_cases, total_deaths,(total_deaths/total_cases)*100 as Death_percentage
FROM portfolio..covid_death
WHERE location LIKE '%India%'
ORDER BY location 

-- Total cases vs population
SELECT location, date, population,total_cases, total_deaths,(total_cases/population)*100 as Case_percentage
FROM portfolio..covid_death
WHERE location LIKE '%India%'
ORDER BY location 

-- Total Deaths vs total population
Select location, date, population, total_cases, total_deaths, new_deaths, (new_deaths/population)*100 as new_death_percentage
FROM portfolio..covid_death
WHERE continent is not null
ORDER BY location

-- Country with highest infection rate
SELECT location,population,MAX(total_cases) as Max_cases, MAX(total_cases/population)*100 as population_infected
FROM portfolio..covid_death
WHERE continent is not null
GROUP BY location,population
ORDER BY population_infected DESC


-- Country with highest death rate
SELECT location,population,MAX(cast(total_deaths as int)) as Max_Death, MAX(total_deaths/population)*100 as Death_ratio
FROM portfolio..covid_death
WHERE continent is not null
GROUP BY location,population
ORDER BY Max_Death DESC


-- Continents Cases and Deaths
SELECT continent, SUM(CAST (new_cases as int)) as Total_cases , SUM(CAST (new_deaths as int))  as Total_deaths
FROM portfolio..covid_death
WHERE continent is not null
GROUP BY continent

-- Contintentd Highest deaths and population 
SELECT continent, SUM(DISTINCT(Population)) as Population, SUM(CAST (new_cases as int)) as Total_cases , SUM(CAST (new_deaths as int))  as Total_deaths
FROM portfolio..covid_death
WHERE continent is not null
GROUP BY continent
ORDER BY Total_deaths DESC

-- Total Cases per day
SELECT date,SUM(new_cases) as Total_cases_Per_Day
FROM portfolio..covid_death
GROUP BY date
--ORDER BY Total_cases_Per_Day DESC

-- Total Deaths per day
SELECT date,SUM(CAST (new_deaths as int)) as Total_Deaths_Per_Day
FROM portfolio..covid_death
GROUP BY date
--ORDER BY Total_Deaths_Per_Day DESC

--Death ratio per day
SELECT date,SUM(CAST (new_deaths as int)) as Total_Deaths_Per_Day, SUM(new_cases) as Total_cases_Per_Day 
,SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as Death_Ratio_per_cases
FROM portfolio..covid_death
WHERE continent is not null
GROUP BY date
--ORDER BY Death_Ratio_per_cases DESC

-- Joining tables Total Vaccination 
SELECT * --a.continent, a.location, a.date,a.population,b.total_vaccinations,b.people_fully_vaccinated
FROM portfolio..covid_death dea 
join portfolio..vaccination vac 
ON dea.location = vac.location and dea.date=vac.date
--WHERE a.continent is not null
ORDER BY dea.location

-- Total Vaccination  in a country
SELECT dea.continent, dea.location, dea.date,dea.population,vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) over (Partition by dea.location ORDER BY dea.location,dea.date) as people_vaccinating
--vac.total_vaccinations,vac.people_fully_vaccinated
FROM portfolio..covid_death dea 
join portfolio..vaccination vac 
ON dea.location = vac.location and dea.date=vac.date
WHERE dea.continent is not null
ORDER BY dea.location,dea.date

-- Create CTE table

With pop_vac(Continent,location,date,population,new_vaccinations,people_vaccinating)
as
(
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location,dea.date) as people_vaccinating
FROM portfolio..covid_death dea
JOIN portfolio..vaccination vac
ON dea.location=vac.location and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY dea.location
)

SELECT * , (people_vaccinating/population)*100 as vacc_per_pop
FROM pop_vac

--Temp Table
DROP TABLE if exists #PercentPopulationVaccination
CREATE TABLE #PercentPopulationVaccination
(
Continents nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccination numeric,
RollingPeopleVaccination numeric
)

INSERT INTO #PercentPopulationVaccination
SELECT dea.continent,dea.location, dea.date,dea.population,vac.new_vaccinations 
		,SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location,dea.Date) as RollingPeopleVaccination
FROM portfolio..covid_death dea JOIN portfolio..vaccination vac
	on dea.location = vac.location and dea.date = vac.date

SELECT * ,(RollingPeopleVaccination/population)*100
FROM #PercentPopulationVaccination

--create view
CREATE VIEW COVID as
SELECT dea.continent,dea.location, dea.date,dea.population,vac.new_vaccinations 
		,SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location,dea.Date) as RollingPeopleVaccination
FROM portfolio..covid_death dea JOIN portfolio..vaccination vac
	on dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null


SELECT *
FROM COVID
