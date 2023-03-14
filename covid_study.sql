-- Select data that we're going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
Order by 1, 2


-- Looking at Total Cases x Total Deaths - mortality

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases)*100 as mortality
FROM CovidDeaths$
Where location like '%states%'
Order by 1, 2

-- Looking at Total Cases x Population - % of population infected

SELECT location, date, population, total_cases, (total_cases / population)*100 as infection_percent
FROM CovidDeaths$
-- Where location like '%Brazil%'
Order by 1, 2


-- Looking for countries with high infection percentage

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases / population))*100 as infection_percent
FROM CovidDeaths$
Group by location, population
Order by infection_percent desc

-- Looking for countries with high death count

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM CovidDeaths$
WHERE continent is not null
Group by location
Order by total_death_count desc

--looking by continent

SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM CovidDeaths$
WHERE continent is not null
Group by continent
Order by total_death_count desc


-- showing the continents with the highest death count

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM CovidDeaths$
WHERE continent is null
Group by location
Order by total_death_count desc


-- SUM ALL THE WORLD'S NUMBERS

SELECT SUM(cast(new_cases as int)) as total_cases_worldwide, SUM(cast(new_deaths as int)) as total_deaths_worldwide , (SUM(cast(new_deaths as int))/SUM(new_cases)) *100 as mortality
FROM CovidDeaths$
WHERE continent is not null
Order by 1


-- Joining the DBs

SELECT *
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	on dea.location = vac.location 
	and dea.date = vac.date
ORDER BY  dea.location, dea.date

-- vac x total pop

SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as total_vacc_per_country
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	on dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY  dea.location, dea.date



-- With CTE

With PopVsVacc (continent, location, date, population, new_vaccinations, total_vacc_per_country)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as total_vacc_per_country
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	on dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
)
select *, (total_vacc_per_country/population)*100 as percent_vacc
from PopVsVacc
order by 2,3


-- With temp table

DROP Table if exists #PercentPopVacc
Create Table #PercentPopVacc
(
continent nvarchar(255),
location  nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
total_vacc_per_country numeric
)


INSERT into #PercentPopVacc
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date) as total_vacc_per_country
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	on dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null

Select *, (total_vacc_per_country/population)*100
From #PercentPopVacc