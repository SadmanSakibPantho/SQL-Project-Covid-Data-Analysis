select * from SQL_Portfolio_Project_1..Covid_Deaths
order by 3,4

select * from SQL_Portfolio_Project_1..Covid_Vaccinations
order by 3,4


-- Now, let's select the data we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from SQL_Portfolio_Project_1..Covid_Deaths
Order by 1,2


-- Now, let's look at the Total Cases vs the Total Deaths
-- Insert name or part of the name of your country in '%country%' to see the likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as PercentageofDeath
from SQL_Portfolio_Project_1..Covid_Deaths
Where location like '%Bangladesh%'
Order by 1,2 DESC


-- Now, let's look at the Total Cases vs Population
-- Let's see what portion of the population contracted covid
select location, date, population, total_cases, (total_cases/population)*100 as PercentageofContraction
from SQL_Portfolio_Project_1..Covid_Deaths
Where location like '%Bangladesh%'
Order by 1,2 DESC


-- Looking at countries with highest contraction rate compared to their population
select location, population, MAX(total_cases) as HighestContractionCount, MAX((total_cases/population))*100 as PercentageofContraction
from SQL_Portfolio_Project_1..Covid_Deaths
Group by location, population
Order by PercentageofContraction DESC


-- Let's look at the countries with the highest death count vs population
select location, population, MAX(cast(total_deaths as int)) as TotalDeathCount
from SQL_Portfolio_Project_1..Covid_Deaths
where continent is not null
Group by location, population
Order by TotalDeathCount DESC
-- Here, Total_cases had nvarchar character type which was causing the query to deliver a false result. That is why we used 'cast' to convert it into integer
-- we also used "where continent is not null" in order to prevent the query from grouping data into continents e.g. Word, Africa etc. since the continent groups contain NULL data


-- Let's break things down by continent
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from SQL_Portfolio_Project_1..Covid_Deaths
where continent is null
Group by location
Order by TotalDeathCount DESC


-- Let's look at the number of cases and deaths across the world throughout the pandemic
select date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from SQL_Portfolio_Project_1..Covid_Deaths
where continent is not null
Group by date
order by date


-- Let's see how the vaccination count stacked up with each passing day for each country
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast (vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as Cumulative_vaccinations
-- here, the partition by function allows the cumulative count to restart for a new location. 
-- But we must use ORDER BY date otherwise the cumulative summation is done for each location only, and not for each date
From SQL_Portfolio_Project_1..Covid_Deaths dea
join SQL_Portfolio_Project_1..Covid_Vaccinations vac
	on dea.date = vac.date
	and dea.location = vac.location
where dea.continent is not null
order by 2,3


-- Now let's look at total population vs vaccinations using the Cumulative_vaccinations data
-- We can do this in multiple ways
-- First, let's use a CTE or Common Table Expression
With PopvsVac (Continent, Location, Date, Population, new_vaccinations, Cumulative_vaccinations)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast (vac.new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as Cumulative_vaccinations
-- here, the partition by function allows the cumulative count to restart for a new location. 
-- But we must use ORDER BY date otherwise the cumulative summation is done for each location only, and not for each date
From SQL_Portfolio_Project_1..Covid_Deaths dea
join SQL_Portfolio_Project_1..Covid_Vaccinations vac
	on dea.date = vac.date
	and dea.location = vac.location
where dea.continent is not null
)
Select *, (Cumulative_vaccinations)/Population*100 from PopvsVac
-- results may show over 100% of the population being vaccinated since the New_vaccinations column also accounts for multiple doses of the vaccine for a person

-- Now, let's use a temporary table to accomplish the same task
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
Cumulative_vaccinations numeric
)
Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as Cumulative_vaccinations
-- here, the partition by function allows the cumulative count to restart for a new location. 
-- But we must use ORDER BY date otherwise the cumulative summation is done for each location only, and not for each date
From SQL_Portfolio_Project_1..Covid_Deaths dea
join SQL_Portfolio_Project_1..Covid_Vaccinations vac
	on dea.date = vac.date
	and dea.location = vac.location
where dea.continent is not null
order by 2,3
Select *, (Cumulative_vaccinations)/Population*100 from  #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) as Cumulative_vaccinations
-- here, the partition by function allows the cumulative count to restart for a new location. 
-- But we must use ORDER BY date otherwise the cumulative summation is done for each location only, and not for each date
From SQL_Portfolio_Project_1..Covid_Deaths dea
join SQL_Portfolio_Project_1..Covid_Vaccinations vac
	on dea.date = vac.date
	and dea.location = vac.location
where dea.continent is not null

select * from PercentPopulationVaccinated

