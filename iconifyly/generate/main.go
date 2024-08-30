package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io"
	"log"
	"net/http"
	"os"
	"slices"
	"strconv"
	"strings"

	"golang.org/x/text/cases"
	"golang.org/x/text/language"
)

type IconSet struct {
	Prefix       string          `json:"prefix"`
	Info         Info            `json:"info"`
	LastModified int64           `json:"lastModified"`
	Icons        map[string]Item `json:"icons"`
	Suffixes     Suffixes        `json:"suffixes"`
	Width        int64           `json:"width"`
	Height       int64           `json:"height"`
}

type Item struct {
	Body  string `json:"body"`
	Width int64  `json:"width"`
}

type Info struct {
	Name          string   `json:"name"`
	Total         int64    `json:"total"`
	Version       string   `json:"version"`
	Author        Author   `json:"author"`
	License       License  `json:"license"`
	Samples       []string `json:"samples"`
	Height        int64    `json:"height"`
	DisplayHeight int64    `json:"displayHeight"`
	Category      string   `json:"category"`
	Palette       bool     `json:"palette"`
}

type Author struct {
	Name string `json:"name"`
	URL  string `json:"url"`
}

type License struct {
	Title string `json:"title"`
	Spdx  string `json:"spdx"`
	URL   string `json:"url"`
}

type Suffixes struct {
	Empty  string `json:""`
	Square string `json:"square"`
}

func isNumeric(s string) bool {
	_, err := strconv.ParseFloat(s, 64)
	return err == nil
}
func GeNName(name string) string {
	caser := cases.Title(language.English)
	name = strings.ReplaceAll(name, "(", " ")
	name = strings.ReplaceAll(name, ".", " ")
	name = strings.ReplaceAll(name, "-", " ")
	name = strings.ReplaceAll(name, "_", " ")

	name = strings.ReplaceAll(name, ")", "")

	if strings.Contains(name, "#") {
		name = strings.Split(name, "#")[0]
	}
	if strings.Contains(name, "&") {
		name = strings.Split(name, "&")[0]
	}
	nameStart := name[:1]
	if isNumeric(nameStart) {
		name = fmt.Sprintf("i %s", name)
	}
	name = caser.String(name)
	name = strings.ReplaceAll(name, " ", "")
	if name == "Map" {
		return "MapIcons"
	}
	return name
}
func iconName(name string) string {
	name = GeNName(name)
	name = fmt.Sprintf("%s%s", strings.ToLower(name[:1]), name[1:])
	ignoredNames := []string{"do", "in", "continue", "try", "return", "is", "switch", "new", "void", "catch", "default", "null", "for", "case"}
	if slices.Contains(ignoredNames, name) {
		name = fmt.Sprintf("%sIcon", name)
	}
	return name
}
func main() {
	result, _ := http.Get("https://raw.githubusercontent.com/iconify/icon-sets/master/collections.json")
	var items map[string]map[string]interface{}
	byteData, _ := io.ReadAll(result.Body)
	os.Mkdir("icons/", 0700)
	json.Unmarshal(byteData, &items)
	resultTemplate, _ := os.ReadFile("iconfile.template")
	resultBaseTemplate, _ := os.ReadFile("iconifyly.template")

	tmpl, err := template.New("file").Funcs(template.FuncMap{"className": GeNName, "iconName": iconName, "html": func(value interface{}) template.HTML {
		return template.HTML(fmt.Sprint(value))
	}}).Parse(string(resultTemplate))
	if err != nil {
		log.Fatalf("parsing: %s", err)
	}
	tmplBase, err := template.New("fileBase").Funcs(template.FuncMap{"className": GeNName, "iconName": iconName, "html": func(value interface{}) template.HTML {
		return template.HTML(fmt.Sprint(value))
	}}).Parse(string(resultBaseTemplate))
	if err != nil {
		log.Fatalf("render: %s", err)
	}
	fs, err := os.Create("../lib/iconifyly.dart")
	if err != nil {
		log.Fatalf("creating: %s", err)
	}
	// Run the template to verify the output.
	err = tmplBase.Execute(fs, items)
	if err != nil {
		log.Fatalf("execution: %s", err)
	}
	if err != nil {
		log.Fatalf("parsing: %s", err)
	}
	for name := range items {
		var iconSet IconSet
		iconResult, _ := http.Get(fmt.Sprintf("https://raw.githubusercontent.com/iconify/icon-sets/master/json/%s.json", name))
		byteDataIcon, _ := io.ReadAll(iconResult.Body)
		json.Unmarshal(byteDataIcon, &iconSet)

		items["iconSet"] = map[string]interface{}{
			"data": iconSet,
		}
		iconSet.Info.Name = name
		if name == "Map" {
			name = "map_iconset"
		}
		fs, err := os.Create(fmt.Sprintf("../lib/%s.dart", name))
		if err != nil {
			log.Fatalf("creating: %s", err)
		}
		// Run the template to verify the output.
		err = tmpl.Execute(fs, iconSet)
		if err != nil {
			log.Fatalf("execution: %s", err)
		}
		fs.Close()

	}
}
