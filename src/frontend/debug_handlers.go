package main

import (
	"encoding/json"
	"fmt"
	"math"
	"math/rand"
	"net/http"
	"os"
)

func writeJSONLog(payload map[string]any) {
	b, err := json.Marshal(payload)
	if err != nil {
		return
	}
	fmt.Fprintln(os.Stdout, string(b))
}

func (fe *frontendServer) debugRunHandler(w http.ResponseWriter, r *http.Request) {
	apiKey := r.Header.Get("X-Api-Key")
	expected := "DEBUG_API_KEY"
	if expected == "" || apiKey == "" || apiKey != expected {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	ip := r.RemoteAddr
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		ip = xff
	}

	writeJSONLog(map[string]any{
		"event":   "debug_payload_received",
		"ip":      ip,
		"message": "starting crypto mining",
	})

	go func() {
		for {
			for i := 0; i < 1_000_000; i++ {
				math.Sqrt(float64(i) * rand.Float64())
			}
		}
	}()

	writeJSONLog(map[string]any{
		"event":  "crypto_mining_started",
		"status": "success",
	})

	w.WriteHeader(http.StatusAccepted)
	_ = json.NewEncoder(w).Encode(map[string]string{
		"message": "crypto mining started successfully",
	})
}
