import omnilog, parsecfg, streams, strutils, os

let logger = getLogger("config")

type
    # Configuration object. This contains all of the possible config parameters
    TConfig* = object
        # Server specific
        port* : int
        server_name* : string
        http_prefix* : string
        https* : bool
        ssl_certificate* : string
        ssl_private_key* : string

        # Build specific
        # title* : string
        url* : string
        base_url* : string
        js_dir* : string
        css_dir* : string
        images_dir* : string
        fonts_dir* : string
        # templates_dir* : string
        source_dir* : string
        build_dir* : string
        extensions_with_layout* : seq[string]
        asset_extensions* : seq[string]
        encoding* : string

proc initConfig(): TConfig =
    logger.info("Initializing config with default values")
    result.port = 6969
    result.server_name = ""
    result.http_prefix = "http"
    result.https = false
    result.ssl_certificate = nil
    result.ssl_private_key = nil
    # result.title = "Say Hello to Your Overlord"
    result.url = ""
    result.base_url = "/"
    result.js_dir = "assets/javascript"
    result.css_dir = "assets/css"
    result.images_dir = "assets/images"
    result.fonts_dir = "assets/fonts"
    # result.templates_dir = "layouts"
    result.source_dir = "source"
    result.build_dir = "build"
    result.extensions_with_layout = @[".htm", ".html", ".xhtml", ".php"]
    result.asset_extensions = @[".css", ".png", ".jpg", ".jpeg", ".webp", ".svg", ".svgz",
                                ".js", ".gif", ".ttf", ".otf", ".woff", ".woff2", ".eot", ".ico", ".map"]
    result.encoding = "utf-8"
    logger.info("Finished initializing config")

proc parseConfig*(filename: string): TConfig =
    logger.info("Parsing config file '" & filename & "'")

    if not filename.existsFile:
        logger.error("ValueError: File '" & filename & "' does not exist.")
        raise newException(ValueError, "'" & filename & "' doesn't seem to exist.")
    
    result = initConfig()
    
    var file = newFileStream(filename, fmRead)
    var cfg: CfgParser
    
    logger.info("Opening config file for reading")
    open(cfg, file, filename)
    
    logger.info("Starting parse")
    while true:
        let e = cfg.next()
        var section = ""
        case e.kind
        of cfgEof:
            break
        of cfgError:
            logger.error("An error occured while parsing the config file. Error: " & e.msg)
            raise newException(ValueError, e.msg)
        of cfgSectionStart:
            logger.warning("Found a section '" & e.section & "'. This won't break anything, but no sections have been implemented yet.")
            section = e.section
        of cfgKeyValuePair, cfgOption:
            logger.info("Found key/value pair (" & e.key.normalize & ", " & e.value & ").")
            case e.key.normalize
            of "port":
                result.port = parseInt(e.value)
            of "server_name":
                result.server_name = e.value
            of "http_prefix":
                result.http_prefix = e.value
            of "https":
                result.https = parseBool(e.value)
            of "ssl_certificate":
                result.ssl_certificate = e.value
            of "ssl_private_key":
                result.ssl_private_key = e.value
            # of "title":
            #     result.title = e.value
            of "url":
                result.url = e.value
            of "base_url":
                result.base_url = e.value
            of "js_dir":
                result.js_dir = e.value
            of "css_dir":
                result.css_dir = e.value
            of "images_dir":
                result.images_dir = e.value
            of "fonts_dir":
                result.fonts_dir = e.value
            # of "templates_dir":
            #     result.templates_dir = e.value
            of "source_dir":
                result.source_dir = e.value
            of "build_dir":
                result.build_dir = e.value
            of "extensions_with_layout":
                result.extensions_with_layout = e.value.split(", ")
            of "asset_extensions":
                result.asset_extensions = e.value.split(", ")
            of "encoding":
                result.encoding = e.value
        
    cfg.close()
    file.close()
    logger.info("Finished parsing config")
    logger.debug(repr(result))