package main

import (
	"embed"
	"errors"
	"fmt"
	"io/fs"
	"log"
	"log/slog"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"

	"github.com/golang/glog"
	"github.com/labstack/echo/v5"
)

//go:embed app
var embededFiles embed.FS

func getFileSystem(useOS bool) http.FileSystem {
	if useOS {
		log.Print("using live mode")
		return http.FS(os.DirFS("app"))
	}

	log.Print("using embed mode")

	fsys, err := fs.Sub(embededFiles, "app")
	if err != nil {
		panic(err)
	}

	return http.FS(fsys)
}

func main() {
	reverseProxyURL, ok := os.LookupEnv("REVERSE_PROXY_URL")
	if !ok || reverseProxyURL == "" {
		glog.Fatalf("web: environment variable not declared: reverseProxyURL")
	}

	webPort, ok := os.LookupEnv("WEB_PORT")
	if !ok || webPort == "" {
		glog.Fatalf("web: environment variable not declared: webPort")
	}

	proxyURL, err := url.Parse(reverseProxyURL)
	if err != nil {
		glog.Fatalf("web: invalid reverse proxy URL: %v", err)
	}

	reverseProxy := httputil.NewSingleHostReverseProxy(proxyURL)

	e := echo.New()

	useOS := len(os.Args) > 1 && os.Args[1] == "live"
	assetHandler := http.FileServer(getFileSystem(useOS))

	e.GET("/", echo.WrapHandler(assetHandler))

	e.GET("/static/*", echo.WrapHandler(
		http.StripPrefix("/static/", assetHandler),
	))

	// Browser -> Web :8888 -> Envoy :5555 -> Proxy
	e.Any("/v1/*", echo.WrapHandler(reverseProxy))

	if err := e.Start(fmt.Sprintf(":%v", webPort)); err != nil &&
		!errors.Is(err, http.ErrServerClosed) {
		slog.Error("server stopped unexpectedly",
			"error", err,
		)

		os.Exit(1)
	}
}
