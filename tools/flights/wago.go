package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

// Spieldaten von wago.tools: neuester Build je Produkt (api/builds) und DB2-Tabellen als CSV (db2/<Tabelle>/csv).
// Produkt je Flavor (Ordnername wie Client.Flavor im Addon); "wowf" ist WoW Forever.

const (
	wagoBase      = "https://wago.tools"
	wagoUserAgent = "LevelTimer-flights-tool"
	wagoTimeout   = 2 * time.Minute
)

// Products ordnet jedem Flavor das Produkt auf wago.tools zu.
var Products = map[string]string{
	"retail":      "wow",
	"classic_era": "wow_classic_era",
	"anniversary": "wow_anniversary",
	"forever":     "wowf",
}

// BorrowSpeed: Flavor ohne eigene Messungen nimmt die Geschwindigkeit dieses Flavors (gleiche Classic-Flugrouten);
// das Addon zeigt die Zeit dann als Schätzung. Retail hat andere Geschwindigkeiten und leiht nicht.
var BorrowSpeed = map[string]string{
	"classic_era": "forever",
	"anniversary": "forever",
}

type wagoClient struct {
	http *http.Client
}

func newWagoClient() *wagoClient {
	return &wagoClient{http: &http.Client{Timeout: wagoTimeout}}
}

func (c *wagoClient) get(path string) (io.ReadCloser, error) {
	request, err := http.NewRequest(http.MethodGet, wagoBase+path, nil)
	if err != nil {
		return nil, err
	}
	request.Header.Set("User-Agent", wagoUserAgent)
	response, err := c.http.Do(request)
	if err != nil {
		return nil, err
	}
	if response.StatusCode != http.StatusOK {
		response.Body.Close()
		return nil, fmt.Errorf("%s: HTTP %d", path, response.StatusCode)
	}
	return response.Body, nil
}

type wagoBuild struct {
	Version   string `json:"version"`
	CreatedAt string `json:"created_at"`
}

// LatestBuilds liefert je Produkt die Version des neuesten Builds.
func (c *wagoClient) LatestBuilds() (map[string]string, error) {
	body, err := c.get("/api/builds")
	if err != nil {
		return nil, err
	}
	defer body.Close()
	var builds map[string][]wagoBuild
	if err := json.NewDecoder(body).Decode(&builds); err != nil {
		return nil, fmt.Errorf("api/builds: %w", err)
	}
	latest := map[string]string{}
	for product, list := range builds {
		var newest wagoBuild
		for _, build := range list {
			if build.CreatedAt > newest.CreatedAt {
				newest = build
			}
		}
		if newest.Version != "" {
			latest[product] = newest.Version
		}
	}
	return latest, nil
}

// Paths lädt TaxiPath und TaxiPathNode eines Builds und rechnet die Strecken.
func (c *wagoClient) Paths(build string) (*Paths, error) {
	taxiPath, err := c.get("/db2/TaxiPath/csv?build=" + url.QueryEscape(build))
	if err != nil {
		return nil, err
	}
	defer taxiPath.Close()
	taxiPathNode, err := c.get("/db2/TaxiPathNode/csv?build=" + url.QueryEscape(build))
	if err != nil {
		return nil, err
	}
	defer taxiPathNode.Close()
	return ParsePaths(build, taxiPath, taxiPathNode)
}
