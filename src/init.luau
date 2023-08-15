--!optimize 2
--!strict

-- TODO: Support greater than 1 page (100 entries) of developer products.
-- TODO: Support passes.
-- TODO: Refactor a LOT.

local FileSystemUtilities = require("./Utilities/FileSystemUtilities")
local ProductifyUtility = require("./Utilities/ProductifyUtility")
local Promise = require("./Packages/Promise")
local RobloxApiUtilities = require("./Utilities/RobloxApiUtilities")
local SerdeUtilities = require("./Utilities/SerdeUtilities")
local Sift = require("./Packages/Sift")

local fs = require("@lune/fs")
local process = require("@lune/process")
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

type Productify = ProductifyUtility.Productify
type ProductEntry = ProductifyUtility.ProductEntry

local RootDirectory = stdio.prompt("text", `Where do you store your {CYAN_BOLD}.productify{RESET} files?`, process.cwd)
if not fs.isDir(RootDirectory) then
	warn(`Invalid directory {GREEN}"{RootDirectory}"{RESET}?\n{RESET}`)
	process.exit(1)
end

local AllProductFiles = Sift.Array.filter(fs.readDir(RootDirectory), function(FilePath)
	FilePath = string.lower(FilePath)
	return string.match(FilePath, "%.productify.toml$") ~= nil
		or string.match(FilePath, "%.productify.json$") ~= nil
		or string.match(FilePath, "%.productify.yml$") ~= nil
		or string.match(FilePath, "%.productify.yaml$") ~= nil -- why you using yaml???
end)

if #AllProductFiles == 0 then
	local String = table.concat({
		` - {CYAN_BOLD}NAME.productify.json{RESET}`;
		` - {CYAN_BOLD}NAME.productify.toml{RESET}`;
		` - {CYAN_BOLD}NAME.productify.yaml{RESET}`;
		` - {CYAN_BOLD}NAME.productify.yml{RESET}`;
	}, "\n")

	warn(
		`No productify files found! If you want to use this tool, you need at least one of the following:\n{String}\nin the directory {CYAN_BOLD}{RootDirectory}.{RESET}`
	)

	process.exit(1)
end

local FileIndex = stdio.prompt("select", "Which file do you want to productify?", AllProductFiles)
if not FileIndex then
	warn("This shouldn't happen?")
	process.exit(1)
end

local ProductFile = AllProductFiles[FileIndex]
SerdeUtilities.PromiseDecodeFile(ProductFile, {} :: Productify):Then(function(ProductifyData)
	assert(ProductifyUtility.IsProductify(ProductifyData))

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
				NewProductEntry.UploadHash = ProductifyUtility.GetHash(OtherProductEntry)
				NewProductify.Products[Index] = NewProductEntry
				break
			end
		end
	end

	for _, ProductEntry in ProductifyData.Products do
		if not ProductifyUtility.IsProductEntryOutdated(ProductEntry) then
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
end):Catch(function(Exception)
	warn(`Failed to run productify {GREEN_BOLD}"{ProductFile}"{RESET} - {tostring(Exception)}{RESET}`)
	process.exit(1)
end)
