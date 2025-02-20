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
	Prefix       string                 `json:"prefix,omitempty"`
	Info         Info                   `json:"info,omitempty"`
	LastModified int64                  `json:"lastModified,omitempty"`
	Icons        map[string]Item        `json:"icons,omitempty"`
	Aliases      map[string]Item        `json:"aliases,omitempty"`
	Suffixes     map[string]interface{} `json:"suffixes,omitempty"`
	Prefixes     map[string]interface{} `json:"prefixes,omitempty"`
	Width        int64                  `json:"width,omitempty"`
	Height       int64                  `json:"height,omitempty"`
	Categories   map[string]interface{} `json:"categories,omitempty"`
}

type Item struct {
	Body   string `json:"body,omitempty"`
	Parent string `json:"parent,omitempty"`
	Width  int64  `json:"width,omitempty"`
	Height int64  `json:"height,omitempty"`
	HFlip  bool   `json:"hFlip,omitempty"`
	VFlip  bool   `json:"vFlip,omitempty"`
	Left   int64  `json:"left,omitempty"`
	Top    int64  `json:"top,omitempty"`
	Rotate int64  `json:"rotate,omitempty"`
}

type Info struct {
	Name          string   `json:"name,omitempty"`
	Total         int64    `json:"total,omitempty"`
	Version       string   `json:"version,omitempty"`
	Author        Author   `json:"author,omitempty"`
	License       License  `json:"license,omitempty"`
	Samples       []string `json:"samples,omitempty"`
	Height        int64    `json:"height,omitempty"`
	DisplayHeight int64    `json:"displayHeight,omitempty"`
	Category      string   `json:"category,omitempty"`
	Palette       bool     `json:"palette,omitempty"`
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
func tojson(info Info) template.HTML {
	result, _ := json.MarshalIndent(info, "\t", "\t")
	return template.HTML(string(result))
}
func buildInfo(icon IconSet) template.HTML {
	icon.Icons = nil
	icon.Aliases = nil
	result, _ := json.MarshalIndent(icon, "\t", "\t")
	return template.HTML(string(result))
}
func main() {
	result, _ := http.Get("https://raw.githubusercontent.com/iconify/icon-sets/master/collections.json")
	var items map[string]map[string]interface{}
	byteData, _ := io.ReadAll(result.Body)
	os.RemoveAll("../lib/generated/")
	os.Mkdir("../lib/generated/", 0700)
	json.Unmarshal(byteData, &items)
	resultTemplate, _ := os.ReadFile("iconfile.template")
	resultBaseTemplate, _ := os.ReadFile("iconyfy.template")

	tmpl, err := template.New("file").Funcs(template.FuncMap{"className": GeNName, "tojson": tojson, "buildInfo": buildInfo, "iconName": iconName, "html": func(value interface{}) template.HTML {
		return template.HTML(fmt.Sprint(value))
	}}).Parse(string(resultTemplate))
	if err != nil {
		panic(err)
	}
	tmplBase, err := template.New("fileBase").Funcs(template.FuncMap{"className": GeNName, "tojson": tojson, "iconName": iconName, "html": func(value interface{}) template.HTML {
		return template.HTML(fmt.Sprint(value))
	}}).Parse(string(resultBaseTemplate))
	if err != nil {
		panic(err)
	}
	os.Remove("../lib/iconifyly.dart")
	fs, err := os.Create("../lib/iconifyly.dart")
	if err != nil {
		panic(err)
	}
	defer fs.Close()
	// Run the template to verify the output.
	err = tmplBase.Execute(fs, items)
	if err != nil {
		panic(err)
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
		fs, err := os.Create(fmt.Sprintf("../lib/generated/%s.dart", name))
		if err != nil {
			log.Fatalf("creating: %s", err)
		}
		defer fs.Close()

		// Run the template to verify the output.
		err = tmpl.Execute(fs, iconSet)
		if err != nil {
			log.Fatalf("execution: %s", err)
		}

	}
}
