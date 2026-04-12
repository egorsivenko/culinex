package handler

import (
	"net/http"
)

const defaultTag = "en"

var languages = map[string]string{
	"en": "English",
	"uk": "Ukrainian",
}

func resolveLanguage(r *http.Request) (string, string) {
	tag := r.Header.Get("Accept-Language")
	if lang, ok := languages[tag]; ok {
		return tag, lang
	}
	return defaultTag, languages[defaultTag]
}
