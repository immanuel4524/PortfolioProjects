--Cleaning Data in SQL Queries-- 

SELECT * 
FROM HousingProject.dbo.NashvilleHousing


--Standardizing Sale Date Format

SELECT SaleDateConverted
FROM HousingProject.dbo.NashvilleHousing

UPDATE HousingProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE HousingProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


--Populating Address Data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProject.dbo.NashvilleHousing a
JOIN HousingProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ] 
WHERE a.PropertyAddress IS NULL

										--Updating table to get rid of null property address values
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProject.dbo.NashvilleHousing a
JOIN HousingProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] != b.[UniqueID ] 
WHERE a.PropertyAddress IS NULL

										--Breaking out property and owner address into indiviual columns (Address, City, State)

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS address, 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS address
FROM HousingProject.dbo.NashvilleHousing

										--Adding two new columns for the address and city
ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

										--Since parse name looks for periods i am replacing the commas with them
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM HousingProject.dbo.NashvilleHousing

										--Adding three new columns for owner address

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET OwnerSplitAddress  = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE HousingProject.dbo.NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE HousingProject.dbo.NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Changing the Y, N values to yes or no in the sold as vacant column

										--Seeing how many Y, N values I have
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM HousingProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

										--Making a CASE WHEN statement to swap out values
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	     WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM HousingProject.dbo.NashvilleHousing


UPDATE HousingProject.dbo.NashvilleHousing
SET SoldAsVacant =
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	     WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END


--Removing Duplicates
												--Identifying duplicates with the row_number function and creating a CTE
WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SaleDate,
				 SalePrice,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num

FROM HousingProject.dbo.NashvilleHousing)


SELECT *
FROM RowNumCTE
WHERE row_num > 1



-- Deleting unused columns
SELECT *
FROM HousingProject.dbo.NashvilleHousing

ALTER TABLE HousingProject.dbo.NashvilleHousing
DROP COLUMN SaleDate,  OwnerAddress, TaxDistrict, PropertyAddress


