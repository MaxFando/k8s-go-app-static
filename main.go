package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/MaxFando/k8s-go-app-static/config"
	"github.com/MaxFando/k8s-go-app-static/server"
	"github.com/MaxFando/k8s-go-app-static/version"
)

func main() {
	launchMode := config.LaunchMode(os.Getenv("LAUNCH_MODE"))
	if len(launchMode) == 0 {
		launchMode = config.LocalEnv
	}
	log.Printf("LAUNCH_MODE: %v", launchMode)

	cfg, err := config.Load(launchMode, "./config")
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("CONFIG: %+v", cfg)

	info := server.VersionInfo{
		Version: version.Version,
		Commit:  version.Commit,
		Build:   version.Build,
	}

	srv := server.New(info, cfg.Port, cfg.StaticsPath)
	ctx, cancel := context.WithCancel(context.Background())

	errors := make(chan error, 1)
	go func() {
		err := srv.Serve(ctx)
		if err != nil {
			errors <- err
		}
	}()
	log.Printf("Starting and Listening on port %s", cfg.Port)

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt, syscall.SIGTERM)

	select {
	case killSignal := <-interrupt:
		switch killSignal {
		case os.Interrupt:
			log.Print("Got SIGINT...")
		case syscall.SIGTERM:
			log.Print("Got SIGTERM...")
		}
	case err = <-errors:
		log.Panicf("Error while serving: %v", err)
	}

	cancel()
}
