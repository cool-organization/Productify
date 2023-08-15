--!optimize 2
--!strict
local Promise = require("../Packages/PromiseTyped")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

--[=[
	Utilities for working with the file system.
	@class FileSystemUtilities
]=]
local FileSystemUtilities = {}

FileSystemUtilities.PromiseReadFile = Promise.Promisify(fs.readFile)
FileSystemUtilities.PromiseWriteFile = Promise.Promisify(fs.writeFile)

--[=[
	Gets the file extension of the file at the path.
	@param FilePath string -- The path to the file.
	@return string? -- The file extension.
]=]
function FileSystemUtilities.GetFileExtension(FilePath: string)
	return string.match(FilePath, "%.([^%.]+)$") or string.match(FilePath, "%.(%a+)$")
end

local EXTENSION_TO_XCODE: {[string]: serde.EncodeDecodeFormat} = {
	json = "json";
	toml = "toml";
	yaml = "yaml";
	yml = "yaml";
}

function FileSystemUtilities.GetEncodeDecodeType(FilePath: string): serde.EncodeDecodeFormat?
	local FileExtension = FileSystemUtilities.GetFileExtension(FilePath)
	return if FileExtension then EXTENSION_TO_XCODE[FileExtension] else nil
end

--[=[
	Gets the name of the file.
	@param FilePath string -- The path to the file.
	@return string? -- The name of the file.
]=]
function FileSystemUtilities.GetFileName(FilePath: string)
	return string.match(FilePath, "([^/]+)$")
end

return table.freeze(FileSystemUtilities)
