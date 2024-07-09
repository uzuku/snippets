package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
)

const UPLOAD_DIR = "./uploads"

func init() {
	// Create the uploads directory if it doesn't exist
	if err := os.MkdirAll(UPLOAD_DIR, os.ModePerm); err != nil {
		log.Fatalf("fail to mkdir %s: %v", UPLOAD_DIR, err)
	}
	log.Println("upload dir created")
}

func uploadHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
		return
	}

	log.Println("upload request received")
	// Parse the multipart form
	mpReader, err := r.MultipartReader()
	if err != nil {
		log.Printf("fail to parse form data: %v", err)
		http.Error(w, "Error parsing form data", http.StatusInternalServerError)
		return
	}

	for {
		part, err_part := mpReader.NextPart()
		if err_part == io.EOF {
			break
		}
		if err != nil {
			log.Printf("fail to read next part: %v", err)
			http.Error(w, "Error reading part", http.StatusInternalServerError)
			return
		}
		if name := part.FormName(); name != "file" {
			log.Printf("skip form %s", name)
			continue
		}
		filename := part.FileName()
		log.Printf("start saving to file %s", filename)
		dst, err := os.Create(filepath.Join(UPLOAD_DIR, filename))
		if err != nil {
			log.Printf("fail to create dst file %s: %v", filename, err)
			http.Error(w, "Error creating file", http.StatusInternalServerError)
			return
		}
		defer dst.Close()

		// Copy the uploaded file data to the server file
		if _, err := io.Copy(dst, part); err != nil {
			log.Printf("fail to save to file %s: %v", filename, err)
			http.Error(w, "Error saving file", http.StatusInternalServerError)
			return
		}
		log.Printf("file %s saved", filename)
		fmt.Fprintf(w, "File %s uploaded successfully\n", filename)
		return
	}

	http.Error(w, "Form data file not found", http.StatusBadRequest)
}

func main() {
	http.HandleFunc("/upload", uploadHandler)

	log.Println("Starting server on :8500")
	if err := http.ListenAndServe(":8500", nil); err != nil {
		log.Println("Error starting server:", err)
	}
}
