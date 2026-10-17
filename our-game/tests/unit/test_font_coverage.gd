extends GdUnitTestSuite

const UI := preload("res://ui_preview/shared/ui_kit.gd")
const ALPHABET := "ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZabcçdefgğhıijklmnoöprsştuüvyz"
const SYMBOLS := "ÂÎÛâîû‘’“”«»–—…×•₺\u00a0"


func test_printable_ascii_and_turkish_characters_have_real_glyphs() -> void:
	var image := Image.load_from_file("res://ui_preview/assets/afet_pixel.png")
	var rectangles := _glyph_rectangles()
	var characters := ALPHABET + SYMBOLS
	for codepoint: int in range(32, 127):
		characters += String.chr(codepoint)
	var replacement := _ink_mask(image, rectangles[63])
	for character: String in characters:
		var codepoint := character.unicode_at(0)
		assert_bool(UI.FONT.has_char(codepoint)).is_true()
		assert_bool(rectangles.has(codepoint)).is_true()
		var mask := _ink_mask(image, rectangles[codepoint])
		if character == " " or character == "\u00a0":
			assert_bool(mask.has(1)).is_false()
		else:
			assert_bool(mask.has(1)).is_true()
			if character != "?":
				assert_bool(mask == replacement).is_false()


func test_turkish_accents_and_dotted_i_remain_distinct() -> void:
	var image := Image.load_from_file("res://ui_preview/assets/afet_pixel.png")
	var rectangles := _glyph_rectangles()
	for pair: String in ["CÇ", "GĞ", "Iİ", "OÖ", "SŞ", "UÜ", "AÂ", "IÎ", "UÛ"]:
		var plain := _ink_mask(image, rectangles[pair.unicode_at(0)])
		var accented := _ink_mask(image, rectangles[pair.unicode_at(1)])
		assert_bool(plain == accented).is_false()
	# The native font intentionally uses capital artwork for lowercase characters.
	for pair: String in ["çÇ", "ğĞ", "ıI", "iİ", "öÖ", "şŞ", "üÜ", "âÂ", "îÎ", "ûÛ"]:
		var lowercase := _ink_mask(image, rectangles[pair.unicode_at(0)])
		var uppercase := _ink_mask(image, rectangles[pair.unicode_at(1)])
		assert_bool(lowercase == uppercase).is_true()


func _glyph_rectangles() -> Dictionary:
	var records := RegEx.create_from_string(
		"(?m)^char id=(\\d+) x=(\\d+) y=(\\d+) width=(\\d+) height=(\\d+)"
	)
	var rectangles: Dictionary = {}
	for record: RegExMatch in records.search_all(
		FileAccess.get_file_as_string("res://ui_preview/assets/afet_pixel.fnt")
	):
		rectangles[record.get_string(1).to_int()] = Rect2i(
			record.get_string(2).to_int(),
			record.get_string(3).to_int(),
			record.get_string(4).to_int(),
			record.get_string(5).to_int()
		)
	return rectangles


func _ink_mask(image: Image, region: Rect2i) -> PackedByteArray:
	var mask := PackedByteArray()
	for y: int in range(region.position.y, region.end.y):
		for x: int in range(region.position.x, region.end.x):
			mask.append(1 if image.get_pixel(x, y).a > 0.0 else 0)
	return mask
