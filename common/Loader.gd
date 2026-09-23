extends Node2D
class_name Loader

# The static functions in this class read from our cache, and then at loading time,
# we either read the files directly, or pull them from over the network

static var cachedData = {} # map of file name -> data (bytes or string)
static var cachedImages = {} # double the caching fun, for the actual Image objects

var baseUrl = "" # loaded via js bridge

var finishedCount = 0
var totalCount = 0

func _ready():
	if OS.get_name() == "Web":
		var locationHref = JavaScriptBridge.eval("location.href")
		baseUrl = locationHref.get_base_dir()
	
	# okay, so we're going to manually load the files we need first
	# and then on the return callback, if it's the char data, use that to
	# load even more
	var dataFiles = ["chars.json", "chatters.json", "events.json", "game.json", "hacking1.csv", "scene.json"]
	totalCount += dataFiles.size()
	for file in dataFiles:
		loadFile(file)

func loadFile(filePath):
	var path = "/data/" + filePath
	if OS.get_name() == "Web":
		var req = HTTPRequest.new()
		req.accept_gzip = false
		add_child(req)
		req.request_completed.connect(func(result, response_code, headers, body):
			if result != HTTPRequest.RESULT_SUCCESS:
				print("Couldn't load " + filePath)
				return
			cachedData[filePath] = body
			loadAnyAdditionalData(filePath)
			countUp()
		)
		var url = baseUrl + path
		req.request(url, [], HTTPClient.METHOD_GET)
		return
	# load from disk (sync, but fine)
	cachedData[filePath] = FileAccess.get_file_as_bytes("res:/" + path)
	loadAnyAdditionalData(filePath)
	countUp()

static func getDataFileImage(fileName):
	if cachedData.has(fileName):
		if not cachedImages.has(fileName):
			var dataContents = cachedData[fileName]
			# write it to a temp file first, for easier Image loading
			var tempFile = FileAccess.create_temp(
				FileAccess.READ_WRITE, "data_",
				fileName.get_extension()
			)
			tempFile.store_buffer(dataContents)
			var tempPath = tempFile.get_path()
			tempFile.flush()
			
			cachedImages[fileName] = Image.load_from_file(tempPath)
		return cachedImages[fileName]
	return Image.new()

static func getDataFileContents(fileName):
	if cachedData.has(fileName):
		return cachedData[fileName].get_string_from_utf8()
	print("No entry found for " + fileName + " in data cache")
	return ""

func loadAnyAdditionalData(filePath):
	# if the path has dependencies (eg. the list of char names) we can enqueue more files to download here
	if filePath == "chars.json":
		var string = Loader.getDataFileContents("chars.json")
		var charData = JSON.parse_string(string)
		totalCount += charData.keys().size()
		for key in charData.keys():
			loadFile("csps/" + key + ".png")

func countUp():
	finishedCount += 1
	var progressBar = get_node("ProgressBar")
	progressBar.value = finishedCount
	progressBar.max_value = totalCount
	
	if totalCount <= 0 or finishedCount <= 0:
		# invalid, haven't loaded yet
		return

	if finishedCount == totalCount:
		get_tree().change_scene_to_file("res://overworld/Main.tscn")
