--!optimize 2
--!strict
-- Used to grab all current products uploaded already.

local Enums = require("./Enums")
local ProductifyUtilities = require("./Utilities/ProductifyUtilities")
local Promise = require("./Packages/PromiseTyped")
local RobloxApiUtilities = require("./Utilities/RobloxApiUtilities")
local SerdeUtilities = require("./Utilities/SerdeUtilities")

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local function Grab(UniverseId: number)
	local FileName = stdio.prompt("text", "What is the name of the file you want to save the products to?")
	if FileName == "" then
		return Promise.Resolve(false)
	end

	local SerializeAs = stdio.prompt("select", "What do you want to serialize as?", {
		[Enums.SerializeAs.TOML] = "TOML";
		[Enums.SerializeAs.JSON] = "JSON";
		[Enums.SerializeAs.YAML] = "YAML";
	})

	if not SerializeAs then
		return Promise.Resolve(false)
	end

	local FullFileName = `{process.cwd}{FileName}.productify.{string.lower(Enums.SerializeAs[SerializeAs])}`
	if not stdio.prompt("confirm", `Do you want to save as {FullFileName}?`) then
		return Promise.Resolve(false)
	end

	if
		fs.isFile(FullFileName)
		and not stdio.prompt("confirm", "This file already exists, do you want to overwrite it?")
	then
		return Promise.Resolve(false)
	end

	return RobloxApiUtilities.GetAllDeveloperProducts(UniverseId):Then(function(ProductInfos)
		local Products: {any} = table.clone(ProductInfos)
		for Index, ProductInfo in ProductInfos do
			local ProductEntry: ProductifyUtilities.ProductEntry = {
				Name = ProductInfo.name;
				Price = ProductInfo.priceInRobux;
				Description = ProductInfo.description;
				ProductId = ProductInfo.id;
			}

			ProductEntry.UploadHash = ProductifyUtilities.GetHash(ProductEntry)
			Products[Index] = ProductEntry
		end

		return SerdeUtilities.PromiseEncodeFile(FullFileName, {
			Products = Products;
			UniverseId = UniverseId;
		})
	end)
end

return Grab
