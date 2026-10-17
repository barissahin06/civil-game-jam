extends GdUnitTestSuite

const PHOTOS := preload("res://ui_preview/crisis/news_photos.gd")


func test_every_historical_event_has_an_imported_photo_without_mutating_event_data() -> void:
	var catalog := HistoricalCatalog.new()
	assert_bool(catalog.load_events()).is_true()
	var original := catalog.events.duplicate(true)
	var ids: Array[String] = []
	var representative := 0
	for event: Dictionary in catalog.events:
		ids.append(event.id)
		var path: String = PHOTOS.path_for(event)
		assert_bool(path.begins_with("res://assets/events/")).is_true()
		assert_bool(ResourceLoader.exists(path, "Texture2D")).is_true()
		if path.get_file().begins_with("_fallback_"):
			representative += 1
	for id: String in PHOTOS.EVENT_IMAGES:
		assert_bool(id in ids).is_true()
	assert_int(PHOTOS.EVENT_IMAGES.size()).is_equal(59)
	assert_int(representative).is_equal(40)
	assert_array(catalog.events).is_equal(original)


func test_unknown_events_use_the_correct_disaster_type_fallback() -> void:
	for kind: String in PHOTOS.FALLBACK_IMAGES:
		assert_str(PHOTOS.path_for({"id": "unmapped", "kind": kind})).is_equal(
			PHOTOS.FALLBACK_IMAGES[kind]
		)
	assert_str(PHOTOS.path_for({"kind": "fire"})).ends_with("/_fallback_wildfire.jpg")
	assert_str(PHOTOS.path_for({"id": "historical-029", "kind": "landslide"})).ends_with(
		"/_fallback_landslide.jpg"
	)


func test_specific_images_take_priority_and_invalid_events_have_no_resource_path() -> void:
	assert_str(PHOTOS.path_for({"id": "historical-003", "kind": "earthquake"})).ends_with(
		"/1952-hasankale-depremi.jpg"
	)
	assert_str(PHOTOS.path_for({})).is_empty()
	assert_str(PHOTOS.path_for({"id": "unmapped", "kind": "unknown"})).is_empty()
