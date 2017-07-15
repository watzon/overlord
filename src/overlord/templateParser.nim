import omnilog, streams, strutils, parseutils, tables, os

let logger = getLogger("templateParser")

type
  TTemplate* = object
    title* : string
    permalink* : string
    layout* : string
    body*: string
    locals*: TableRef[string, string]

proc parseStringValue(s: string): string =
  if s[0] == '"' and s[s.len-1] == '"':
    result = s[1 .. -2]
  else:
    result = s

proc parseTemplateFromString*(body: string): TTemplate =
  logger.info("Parsing a template")
  logger.debug("Raw template content: \n" & body)

  result = TTemplate()
  result.locals = newTable[string, string]()

  var i = 0
  # Find the location of the front matter
  i.inc skip(body, "---", i)
  # If the `---` is not found on the first line then we will assume there is no front matter
  if i == 0:
    logger.info("No front matter was found. Continuing.")
    result.body = body
    return result

  # Skip over any whitespace
  i.inc skipWhitespace(body, i)
  
  # Loop through the front matter area until the matching `---` is found.
  # Skip over any comments and whitespace along the way
  logger.info("Starting to parse front matter")
  while true:
    if body[i .. i + 2] == "---":
      logger.info("Found closing `---`")
      break
    if body[i] == '#':
      i.inc skipUntil(body, Whitespace - {' '}, i)
      i.inc skipWhitespace(body, i)
      continue

    # Search for keys
    var key = ""
    i.inc parseUntil(body, key, {':'} + Whitespace, i)
    if body[i] != ':':
      logger.error("Expected ':' after key in meta data.")
      raise newException(ValueError, "Expected ':' after key in meta data.")
    i.inc # skip :
    i.inc skipWhitespace(body, i)

    # Search for and parse the matching values
    var value = ""
    i.inc parseUntil(body, value, Whitespace - {' '}, i)
    logger.info("Found key/value pair (" & key & ", " & value & ").")
    i.inc skipWhitespace(body, i)
    case key.normalize
    of "title":
      result.title = parseStringValue(value)
    of "permalink":
      result.permalink = parseStringValue(value)
    of "layout":
      result.layout = parseStringValue(value)
    else:
      # If none of the keys match, add the key and value to the `locals`
      logger.info("Key '" & key & "' didn't match. Adding as local value.")
      result.locals.add(key.normalize, value)
  logger.info("Finished parsing front matter")
  i.inc 3 # skip ---
  i.inc skipWhitespace(body, i)
  result.body = body[i .. body.len]
  logger.info("Finished parsing template")
  logger.debug("Front matter: " & repr(result))

proc parseTemplateFromFile*(filename: string): TTemplate =
  logger.info("Parsing template from file '" & filename & "'.")
  var fileContent = readFile(filename)
  return parseTemplateFromString(fileContent)