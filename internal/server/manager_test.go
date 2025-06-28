package server

import (
	"testing"

	"minecraft-server-manager/internal/config"

	"github.com/sirupsen/logrus"
)

func TestFirstRunMode(t *testing.T) {
	// Create a test configuration with first-run enabled
	cfg := &config.Config{
		Server: config.ServerConfig{
			FirstRun: true,
		},
	}

	// Create a logger
	logger := logrus.New()

	// Create a manager
	manager := NewManager(cfg, logger)

	// Verify that the first-run flag is set correctly
	if !manager.config.Server.FirstRun {
		t.Error("First run flag should be enabled")
	}

	// Test that lastCommitSHA starts as empty string
	if manager.lastCommitSHA != "" {
		t.Error("lastCommitSHA should start as empty string")
	}
}

func TestNormalMode(t *testing.T) {
	// Create a test configuration with first-run disabled
	cfg := &config.Config{
		Server: config.ServerConfig{
			FirstRun: false,
		},
	}

	// Create a logger
	logger := logrus.New()

	// Create a manager
	manager := NewManager(cfg, logger)

	// Verify that the first-run flag is not set
	if manager.config.Server.FirstRun {
		t.Error("First run flag should be disabled")
	}

	// Test that lastCommitSHA starts as empty string
	if manager.lastCommitSHA != "" {
		t.Error("lastCommitSHA should start as empty string")
	}
}
