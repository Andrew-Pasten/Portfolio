/*                            
                  DATA EXPLORATION WITH SQL 
	Covid 19 DATA (https://ourworldindata.org/covid-deaths) 

SKILLS USED: 1.) Joins, 2.) CTE's, 3.) Temp Tables, 4.) Windows Functions, 
             5.) Aggregate Functions, 6.) Creating Views, 7.) Converting Data Types

*/ 

-- Data to be explored 
SELECT *
FROM PortfolioProject.dbo.CovidDeaths 
ORDER BY location, date

-- Start by selecting data to work with
SELECT Location, Date, Total_Cases, New_Cases, Total_Deaths, Population
FROM PortfolioProject..CovidDeaths
WHERE Continent is not null
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Table shows the Total Cases, Total Deaths, and Percentage of Covid cases that
-- reulted in deaths in the United States between January 2020 through November 2023
Select Location, Date, Total_Cases, Total_Deaths, (CONVERT(float, Total_Deaths) / NULLIF(CONVERT(float, Total_Cases), 0))*100 as Death_Percentage
FROM PortfolioProject..CovidDeaths
WHERE Location like'united States'
and continent is not null
ORDER BY 1,2


--Total Cases vs Population
--Table shows perctage of the US population infected with Covid
Select Location, Date, Population, Total_Cases, ((Total_Cases) / (Population))*100 as Infected_Percentage
FROM PortfolioProject..CovidDeaths
WHERE Location like'united States'
and Continent is not null
ORDER BY 1,2

-- Countries with HIGHEST Infection Rate compared to POPULAATION
Select Location, Population, MAX(Total_Cases) as HighestInfectionCount, MAX(Total_Cases / Population)*100 as Infected_Percentage
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
ORDER BY Infected_Percentage desc


--Countries with HIGHEST Death Count per POPULATION
Select Location, MAX(cast(Total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc

--Exploring Data by Continent, Country and Global categories

--Table shows Continents with HIGHEST Death Count per POPULATION
Select continent, MAX(cast(Total_Deaths as int)) as TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE Continent is not null
GROUP BY Continent
ORDER BY TotalDeathCount desc

--Exploring Data by Country 
--Table shows Countries with HIGHEST Death Count per POPULATION
Select Location, MAX(cast(Total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE Continent is not null
GROUP BY Location 
ORDER BY TotalDeathCount desc

--Exploring Data by Global categories
Select Location, MAX(cast(Total_Deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY Location 
ORDER BY TotalDeathCount desc


--Worldwide Death Percentage 
--Table shows percentage of Covid cases resulting in Death Worldwide
Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
WHERE continent is not null 
Order By 1,2


-- Total Population vs Vaccinations
-- Table shows a Rolling Count of the Population that has recieved a Covid Vaccination 
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations
, SUM(CONVERT(bigint,vac.New_Vaccinations)) OVER(Partition By dea.Location ORDER By dea.location,
  dea.date) as Rolling_Vaccination_Count
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3

--(CTE METHOD) 
-- Total Percentage of Vaccination Shots per Country Population 
-- The Rolling Count of Vaccinations administered to the Country's Population as well as 
-- the Rolling Percentage of the Country's Population that could have recieved a Vaccination
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccination_Count) 
as 
(
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations
, SUM(CONVERT(bigint,vac.New_Vaccinations)) OVER(Partition By dea.Location ORDER By dea.location,
  dea.date) as Rolling_Vaccination_Count
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (Rolling_Vaccination_Count/Population)*100 as Rolling_VaccinationShot_Percentage
FROM PopVsVac



--(Temp Table METHOD) 
-- Total Percentage of Vaccination Shots per Country Population 
-- The Rolling Count of vaccinations administered to the Country's Population as well as 
-- the Rolling Percentage of the Country's Population that could have recieved a Vaccination

DROP TABLE IF exists #Rolling_VaccinationShot_Percentage
CREATE TABLE #Rolling_VaccinationShot_Percentage
(
Continent nvarchar(255),
location nvarchar(255),
Date Datetime,
Population Numeric,
New_Vaccinations Numeric,
Rolling_Vaccination_Count Numeric
)

INSERT INTO #Rolling_VaccinationShot_Percentage
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations
, SUM(CONVERT(bigint,vac.New_Vaccinations)) OVER(Partition By dea.Location ORDER By dea.location,
  dea.date) as Rolling_Vaccination_Count
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null


SELECT *, (Rolling_Vaccination_Count/Population)*100 Rolling_VaccinationShot_Percentage
FROM #Rolling_VaccinationShot_Percentage


-- VIEWS created to store for visualizations


-- View shows Percentage of the Country's Population that could have recieved a Vaccination
Create View Rolling_VaccinationShot_Percentage as
SELECT dea.Continent, dea.Location, dea.Date, dea.Population, vac.New_Vaccinations
, SUM(CONVERT(bigint,vac.New_Vaccinations)) OVER(Partition By dea.Location ORDER By dea.location,
  dea.date) as Rolling_Vaccination_Count
From PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

Select * 
FROM Rolling_VaccinationShot_Percentage


--View shows Percentage of Covid cases resulting in Death Worldwide
Create View Worldwide_Death_Percentage as 
Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
WHERE continent is not null 

Select * 
FROM Worldwide_Death_Percentage

--View shows Continents with HIGHEST Death Count per POPULATION as of Novemebr 2023
Create View Total_Deaths_ByContinent as 
Select continent, MAX(cast(Total_Deaths as int)) as TotalDeathCount 
FROM PortfolioProject..CovidDeaths
WHERE Continent is not null
GROUP BY Continent

Select * 
FROM Total_Deaths_ByContinent

