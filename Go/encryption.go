package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"io"
	"log"
	"os"
)

/*
This file contains logic to encrypt a token before it is stored on the local filesystem,
and decrypt tokens read from a file. A key and nonce are defined in order to perform AES-GCM
authenticated encryption.

IMPORTANT: The key and nonce are written to files and stored on the local file system.
Whenever possible, they should instead be stored in a more secure location, separate from
the data they are used to encrypt and decrypt.
*/

var key = make([]byte, 32)
var nonce = make([]byte, 12)

func encryptToken(t token) string {
	original := t.ID // ID is string member of token

	block, err := aes.NewCipher(key)
	if err != nil {
		log.Println("Error creating cipher during encrypt:", err)
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		log.Println("Error creating GCM during encrypt:", err)
	}

	ciphertext := aesgcm.Seal(nil, nonce, []byte(original), nil)

	return hex.EncodeToString(ciphertext)
}

func decryptToken(s string) string {
	ciphertext, err := hex.DecodeString(s)
	if err != nil {
		log.Println("Error decoding string from hex:", err)
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		log.Println("Error creating cipher during decrypt:", err)
	}

	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		log.Println("Error creating GCM during decrypt:", err)
	}

	original, err := aesgcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		log.Println("Error decrypting to string:", err)
	}
	originalAsString := string(original)

	return originalAsString
}

func handleCrypto(key *[]byte, nonce *[]byte) {
	if _, err := os.Stat("key.key"); errors.Is(err, os.ErrNotExist) {
		log.Println("No crypto files found. Creating key, nonce, and files...")
		key_file, err := os.OpenFile("key.key", os.O_CREATE|os.O_WRONLY, 0600)
		if err != nil {
			log.Println("Error creating file:", err)
		}
		nonce_file, err := os.OpenFile("nonce.key", os.O_CREATE|os.O_WRONLY, 0600)
		if err != nil {
			log.Println("Error creating file:", err)
		}

		defer key_file.Close()
		defer nonce_file.Close()

		_, err = rand.Read(*key)
		if err != nil {
			log.Println("Error creating key:", err)
		}

		_, err = io.ReadFull(rand.Reader, *nonce)
		if err != nil {
			log.Println("Error creating nonce:", err)

		}

		_, err = key_file.Write(*key)
		if err != nil {
			log.Println("Error writing key to file:", err)
		}
		_, err = nonce_file.Write(*nonce)
		if err != nil {
			log.Println("Error writing nonce to file:", err)
		}

	} else {
		log.Println("Crypto files found, attempting to read...")
		key_file, err := os.OpenFile("key.key", os.O_RDONLY, 0644)
		if err != nil {
			log.Println("Error accessing key file:", err)
		}

		nonce_file, err := os.OpenFile("nonce.key", os.O_RDONLY, 0644)
		if err != nil {
			log.Println("Error accessing nonce file:", err)
		}

		defer key_file.Close()
		defer nonce_file.Close()

		_, err = key_file.Read(*key)
		if err != nil {
			log.Println("Error reading key from file:", err)
		}

		_, err = nonce_file.Read(*nonce)
		if err != nil {
			log.Println("Error reading nonce from file:", err)
		}
	}

}
