--!optimize 2
--!strict

-- TODO: Support greater than 1 page (100 entries) of developer products.
-- TODO: Support passes.

local ProductifyUtility = require("./Utilities/ProductifyUtility")
local SerdeUtilities = require("./Utilities/SerdeUtilities")
local Sift = require("./Packages/Sift")

local Upload = require("./Upload")
local Validate = require("./Validate")

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local BOLD = stdio.style("bold")
local RESET = stdio.style("reset")

local CYAN = stdio.color("cyan")
local CYAN_BOLD = CYAN .. BOLD
local GREEN = stdio.color("green")
local GREEN_BOLD = GREEN .. BOLD

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

local Options = {
	Validate = 1;
	Upload = 2;

	"Validate";
	"Upload";
}

local OptionIndex = stdio.prompt("select", "What do you want to do with this?", {
	[Options.Validate] = "Validate the file.";
	[Options.Upload] = "Upload the products.";
})

if not OptionIndex then
	warn("This shouldn't happen.")
	process.exit(1)
end

return SerdeUtilities.PromiseDecodeFile(ProductFile, {} :: Productify):Then(function(ProductifyData)
	if OptionIndex == Options.Validate then
		Validate(ProductifyData)
	elseif OptionIndex == Options.Upload then
		return Upload(ProductFile, ProductifyData)
	end
end):Catch(function(Exception)
	warn(`Failed to run productify {GREEN_BOLD}"{ProductFile}"{RESET} - {tostring(Exception)}{RESET}`)
	process.exit(1)
end):Wait()
