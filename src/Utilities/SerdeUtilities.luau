--!optimize 2
--!strict

local FileSystemUtilities = require("./FileSystemUtilities")
local Promise = require("../Packages/PromiseTyped")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")

local CYAN_BOLD = stdio.style("bold") .. stdio.color("cyan")
local RESET = stdio.color("reset")

--[=[
	@class SerdeUtilities
]=]
local SerdeUtilities = {}

SerdeUtilities.PromiseDecode = Promise.Promisify(serde.decode)
SerdeUtilities.PromiseEncode = Promise.Promisify(serde.encode)

local CAN_DECODE: {[string]: serde.EncodeDecodeFormat} = {
	json = "json";
	toml = "toml";
	yaml = "yaml";
	yml = "yaml";
}

function SerdeUtilities.PromiseDecodeFile<T>(FilePath: string, _TemplateType: T): Promise.TypedPromise<T>
	if not fs.isFile(FilePath) then
		return Promise.Reject(`A file does not exist at path {CYAN_BOLD}{FilePath}{RESET}`)
	end

	local FileExtension = FileSystemUtilities.GetFileExtension(FilePath)
	if not FileExtension then
		return Promise.Reject(`Cannot decode file {CYAN_BOLD}{FilePath}{RESET} (missing file extension?)`)
	end

	local DecodeTo: serde.EncodeDecodeFormat? = CAN_DECODE[string.lower(FileExtension)]
	if not DecodeTo then
		return Promise.Reject(`Cannot decode file {CYAN_BOLD}{FilePath}{RESET} (unsupported file extension)`)
	end

	return FileSystemUtilities.PromiseReadFile(FilePath):Then(function(Contents)
		return SerdeUtilities.PromiseDecode(DecodeTo, Contents)
	end)
end

function SerdeUtilities.PromiseEncodeFile<T>(FilePath: string, Data: T): Promise.Promise
	local FileExtension = FileSystemUtilities.GetFileExtension(FilePath)
	if not FileExtension then
		return Promise.Reject(`Cannot decode file {CYAN_BOLD}{FilePath}{RESET} (missing file extension?)`)
	end

	local EncodeTo: serde.EncodeDecodeFormat? = CAN_DECODE[string.lower(FileExtension)]
	if not EncodeTo then
		return Promise.Reject(`Cannot encode file {CYAN_BOLD}{FilePath}{RESET} (unsupported file extension)`)
	end

	return SerdeUtilities.PromiseEncode(EncodeTo, Data, true):Then(function(Contents)
		return FileSystemUtilities.PromiseWriteFile(FilePath, Contents)
	end)
end

return table.freeze(SerdeUtilities)
