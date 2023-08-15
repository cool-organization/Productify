--!optimize 2
--!strict
local FileSystemUtilities = require("./Utilities/FileSystemUtilities")
local ProductifyUtilities = require("./Utilities/ProductifyUtilities")
local Promise = require("./Packages/Promise")
local RobloxApiUtilities = require("./Utilities/RobloxApiUtilities")
local SerdeUtilities = require("./Utilities/SerdeUtilities")
local Sift = require("./Packages/Sift")

local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local BOLD = stdio.style("bold")
local RESET = stdio.style("reset")

local CYAN = stdio.color("cyan")
local CYAN_BOLD = CYAN .. BOLD
local GREEN = stdio.color("green")
local GREEN_BOLD = GREEN .. BOLD
local YELLOW = stdio.color("yellow")
local YELLOW_BOLD = YELLOW .. BOLD

type Productify = ProductifyUtilities.Productify
type ProductEntry = ProductifyUtilities.ProductEntry

local function Upload(ProductFile: string, ProductifyData: Productify)
	assert(ProductifyUtilities.IsProductify(ProductifyData))

	local Promises: {any} = {}
	local Length = 0

	local UniverseId = ProductifyData.UniverseId
	local NewProductify = Sift.Dictionary.copyDeep(ProductifyData)

	local function ReplaceProduct(ProductEntry: ProductEntry, OnFound: (ProductEntry: ProductEntry) -> ProductEntry?)
		for Index, OtherProductEntry in NewProductify.Products do
			if
				Sift.Dictionary.equals(OtherProductEntry, ProductEntry)
				or OtherProductEntry.ProductId == ProductEntry.ProductId
			then
				local Cloned = table.clone(OtherProductEntry)
				local NewProductEntry = OnFound(Cloned) or Cloned
				NewProductEntry.UploadHash = ProductifyUtilities.GetHash(OtherProductEntry)
				NewProductify.Products[Index] = NewProductEntry
				break
			end
		end
	end

	for _, ProductEntry in ProductifyData.Products do
		if not ProductifyUtilities.IsProductEntryOutdated(ProductEntry) then
			continue
		end

		if ProductEntry.ProductId ~= nil then
			Length += 1
			Promises[Length] = RobloxApiUtilities.PromiseUpdateProduct(
				UniverseId,
				ProductEntry.ProductId,
				ProductEntry.Name,
				ProductEntry.Price,
				ProductEntry.Description
			):Tap(function()
				ReplaceProduct(ProductEntry, function(NewProductEntry)
					NewProductEntry.ProductId = ProductEntry.ProductId
					return NewProductEntry
				end)
			end):Catch(function(Exception)
				warn(
					`Failed to call {CYAN_BOLD}PromiseUpdateProduct({UniverseId}, {ProductEntry.ProductId}, {GREEN}"{ProductEntry.Name}"{CYAN}, {ProductEntry.Price}, {GREEN}"{ProductEntry.Description or ""}"{CYAN}){RESET}: {YELLOW_BOLD}{Exception}{RESET}\n`
				)
			end)
		else
			Length += 1
			Promises[Length] = RobloxApiUtilities.PromiseGuaranteedProductUpload(
				UniverseId,
				ProductEntry.Name,
				ProductEntry.Price,
				ProductEntry.Description
			):Tap(function(ProductId)
				ReplaceProduct(ProductEntry, function(NewProductEntry)
					NewProductEntry.ProductId = ProductId
					return NewProductEntry
				end)
			end):Catch(function(Exception)
				warn(
					`Failed to call {CYAN_BOLD}PromiseGuaranteedProductUpload({UniverseId}, {GREEN}"{ProductEntry.Name}"{CYAN}, {ProductEntry.Price}, {GREEN}"{ProductEntry.Description or ""}"{CYAN}){RESET}: {YELLOW_BOLD}{Exception}{RESET}\n`
				)
			end)
		end
	end

	-- TODO: GamePasses
	return Promise.All(Promises):Then(function()
		local EncodeType: serde.EncodeDecodeFormat? = FileSystemUtilities.GetEncodeDecodeType(ProductFile)
		if not EncodeType then
			return Promise.Reject(`Can't get encode type for {GREEN_BOLD}"{ProductFile}"{RESET}}`)
		end

		return SerdeUtilities.PromiseEncode(EncodeType, NewProductify, true)
	end):Then(function(String)
		return FileSystemUtilities.PromiseWriteFile(ProductFile, String)
	end):Then(function()
		print(`Successfully productified {GREEN_BOLD}"{ProductFile}"{RESET}!`)
	end)
end

return Upload
